// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./IAirdrop.sol";
import "./IAirdropController.sol";

contract AirdropController is UUPSUpgradeable, OwnableUpgradeable, IAirdrop, IAirdropController {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct Airdrop {
        uint256 id;
        address token;
        bytes32 merkleRoot;
        uint256 amount;
        uint256 count;
        uint256 deadline;

        mapping(uint256 => uint256) claimedBitMap;
        uint256 claimedAmount;
        uint256 claimedCount;
    }

    uint256 private constant MIN_ID = 1e4;

    address public governance;
    uint256 private _idTracker;
    mapping (uint256 => Airdrop) private _airdrops;
    mapping (address => uint256) private _assignedBalances;

    modifier onlyValid(uint256 id) {
        require(_isValid(id), "AirdropController: invalid id");
        _;
    }

    modifier onlyGovernance() {
        require(_msgSender() == governance, "AirdropController: not governance");
        _;
    }

    function initialize() public virtual payable initializer {
        __UUPSUpgradeable_init();
        __Ownable_init();

        _idTracker = MIN_ID;
        governance = _msgSender();
    }

    function setGovernance(address governance_) external onlyOwner {
        governance = governance_;
    }

    function create(address token, bytes32 merkleRoot, uint256 deadline, uint256 amount, uint256 count) external override onlyGovernance returns (uint256) {
        require(deadline > _getTimestamp(), "AirdropController: deadline is expired.");
        require(amount > 0, "AirdropController: invalid amount");
        require(_availableBalance(token) >= amount, "AirdropController: insufficient available balance");

        uint256 id = _idTracker++;

        Airdrop storage airdrop = _airdrops[id];
        airdrop.token = token;
        airdrop.merkleRoot = merkleRoot;
        airdrop.deadline = deadline;
        airdrop.amount = amount;
        airdrop.count = count;

        _assignedBalances[token] += amount;

        emit Created(id, token, merkleRoot, deadline, amount, count);

        return id;
    }

    function claim(uint256 id, uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) external override onlyValid(id) {
        require(!_isExpired(id), 'AirdropController: already expired.');
        require(!_isClaimed(id, index), 'AirdropController: already claimed.');

        Airdrop storage airdrop = _airdrops[id];
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(MerkleProof.verify(merkleProof, airdrop.merkleRoot, node), 'AirdropController: invalid proof.');

        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        airdrop.claimedBitMap[claimedWordIndex] = airdrop.claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
        airdrop.claimedCount += 1;
        airdrop.claimedAmount += amount;

        IERC20Upgradeable(airdrop.token).safeTransfer(account, amount);
        _assignedBalances[airdrop.token] -= amount;
        
        emit Claimed(id, account, amount, index);
    }

    function recycle(uint256 id, address recipient) external override onlyValid(id) onlyGovernance {
        require(_isExpired(id), 'AirdropController: not expired.');

        Airdrop storage airdrop = _airdrops[id];
        require(!_isAllClaimed(id), 'AirdropController: all claimed.');
        uint256 amount = airdrop.amount - airdrop.claimedAmount;

        IERC20Upgradeable(airdrop.token).safeTransfer(recipient, amount);
        _assignedBalances[airdrop.token] -= amount;

        emit Recycled(id, recipient, amount);
    }

    function availableBalance(address token) external override view returns (uint256) {
        return _availableBalance(token);
    }

    function getUnclaimed(uint256 id) external view override returns (uint256) {
        return _isValid(id) ? _getUnclaimed(id) : 0;
    }

    function isExpired(uint256 id) external view override returns (bool) {
        return _isValid(id) ? _isExpired(id) : true;
    }
    
    function isClaimed(uint256 id, uint256 index) external view override returns (bool) {
        return _isValid(id) ? _isClaimed(id, index) : true;
    }

    function isAllClaimed(uint256 id) external view override returns (bool) {
        return _isValid(id) ? _isAllClaimed(id) : false;
    }

    function _availableBalance(address token) private view returns (uint256) {
        return IERC20(token).balanceOf(address(this)) - _assignedBalances[token];
    }

    function _getUnclaimed(uint256 id) private view returns (uint256) {
        return _airdrops[id].amount - _airdrops[id].claimedAmount;
    }

    function _isValid(uint256 id) private view returns (bool) {
        return id >= MIN_ID && id < _idTracker;
    }

    function _isExpired(uint256 id) private view returns (bool) {
        return _airdrops[id].deadline < _getTimestamp();
    }

    function _isClaimed(uint256 id, uint256 index) private view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = _airdrops[id].claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);

        return claimedWord & mask == mask;
    }

    function _isAllClaimed(uint256 id) private view returns (bool) {
        return _airdrops[id].claimedCount == _airdrops[id].count;
    }

    function _getTimestamp() private view returns (uint256) {
        return block.timestamp;
    }

    function _authorizeUpgrade(address) internal virtual override onlyOwner {}
}