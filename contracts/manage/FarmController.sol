// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "./IFarm.sol";
import "./IFarmController.sol";

contract FarmController is UUPSUpgradeable, OwnableUpgradeable, IFarm, IFarmController {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct Farm {
        uint256 id;
        address baseToken;
        address targetToken;
        uint256 totalReward;
        uint256 startTime;
        uint256 endTime;
        uint256 duration;

        uint256 updateTime;
        uint256 totalStaked;

        uint256 storedRewardPerToken;
        mapping(address => uint256) paidRewardPerTokens;
        mapping(address => uint256) accountStaked;
        mapping(address => uint256) rewards;
    }

    uint256 private constant MIN_ID = 1e4;

    address public governance;
    uint256 private _idTracker;
    mapping (uint256 => Farm) private _farms;
    mapping (address => uint256) private _assignedBalances;
    
    modifier onlyValid(uint256 id) {
        require(_isValid(id), "FarmController: invalid id");
        _;
    }

    modifier onlyGovernance() {
        require(_msgSender() == governance, "FarmController: not governance");
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

    function create(
        address baseToken,
        address targetToken,
        uint256 totalReward,
        uint256 startTime,
        uint256 endTime
    ) external override onlyGovernance returns (uint256) {
        require(startTime > _getTimestamp(), "FarmController: startTime invalid");
        require(startTime < endTime, "FarmController: startTime must less than endTime");
        require(totalReward > 0, "FarmController: invalid totalReward");
        require(_getAvailableBalance(targetToken) >= totalReward, "FarmController: insufficient available balance");

        uint256 id = _idTracker++;

        Farm storage farm = _farms[id];
        farm.baseToken = baseToken;
        farm.targetToken = targetToken;
        farm.totalReward = totalReward;
        farm.startTime = startTime;
        farm.endTime = endTime;
        farm.duration = endTime - startTime;
        farm.updateTime = startTime;

        _assignedBalances[targetToken] += totalReward;

        emit Created(id, baseToken, targetToken);

        return id;
    }

    function stake(uint256 id, uint256 amount) external override onlyValid(id) {
        require(amount > 0, "FarmController: cannot stake 0");

        Farm storage farm = _farms[id];
        require(_isStarted(farm), "FarmController: not start");
        require(!_isEnded(farm), "FarmController: already ended");
        
        address account = _msgSender();
        _updateReward(farm, account);

        IERC20Upgradeable(farm.baseToken).safeTransferFrom(account, address(this), amount);
        farm.totalStaked += amount;
        farm.accountStaked[account] += amount;

        emit Staked(id, account, amount);
    }

    function withdraw(uint256 id, uint256 amount) external override onlyValid(id) {
        require(amount > 0, "FarmController: cannot stake 0");

        Farm storage farm = _farms[id];
        require(_isStarted(farm), "FarmController: not start");

        _withdraw(farm, amount);
    }

    function claim(uint256 id) external override onlyValid(id) {
        _claim(_farms[id]);
    }

    function exit(uint256 id) external override onlyValid(id) {
        Farm storage farm = _farms[id];
        require(_isStarted(farm), "FarmController: not start");

        uint256 amount = farm.accountStaked[_msgSender()];
        if(amount > 0) {
            _withdraw(farm, amount);
        }
        
        _claim(farm);
    }

    function getMeta(uint256 id_) public view override returns (
        uint256 id,
        address baseToken,
        address targetToken,
        uint256 startTime,
        uint256 endTime,
        uint256 duration
    ) {
        Farm storage farm = _farms[id_];

        baseToken = farm.baseToken;
        targetToken = farm.targetToken;
        id = farm.id;
        startTime = farm.startTime;
        endTime = farm.endTime;
        duration = farm.duration;
    }

    function getTotalStaked(uint256 id) public view override returns (uint256) {
        return _isValid(id) ? _farms[id].totalStaked : 0;
    }

    function getAccountStaked(uint256 id, address account) public view override returns (uint256) {
        return _isValid(id) ? _farms[id].accountStaked[account] : 0;
    }

    function getAccountEarned(uint256 id, address account) public view override returns (uint256) {
        return _isValid(id) ? _getAccountEarned(_farms[id], account) : 0;
    }

    function getTotalReward(uint256 id) public view override returns (uint256) {
        return _isValid(id) ? _farms[id].totalReward : 0;
    }

    function getCurrentReward(uint256 id) public view override returns (uint256) {
        if(!_isValid(id)) {
            return 0;
        }

        Farm storage farm = _farms[id];
        return (_getAppliedUpdateTime(farm)- farm.startTime) * farm.totalReward / farm.duration;
    }

    function _withdraw(Farm storage farm, uint256 amount) private {
        address account = _msgSender();
        _updateReward(farm, account);

        IERC20Upgradeable(farm.baseToken).safeTransfer(account, amount);
        farm.totalStaked -= amount;
        farm.accountStaked[account] -= amount;

        emit Withdrawn(farm.id, account, amount);
    }

    function _claim(Farm storage farm) private {
        address account = _msgSender();
        _updateReward(farm, account);

        uint256 amount = _getAccountEarned(farm, account);
        if(amount > 0) {
            farm.rewards[account] = 0;

            IERC20Upgradeable(farm.targetToken).safeTransfer(account, amount);
            _assignedBalances[farm.targetToken] -= amount;

            emit Claimed(farm.id, account, amount);
        }
    }

    function _getAccountEarned(Farm storage farm, address account) private view returns (uint256) {
        return farm.accountStaked[account] * (_getRewardPerToken(farm) - farm.paidRewardPerTokens[account]) / 1e40 + farm.rewards[account];
    }

    function _updateReward(Farm storage farm, address account) private {
        farm.storedRewardPerToken = _getRewardPerToken(farm);
        farm.updateTime = _getAppliedUpdateTime(farm);

        if(account != address(0)) {
            farm.rewards[account] = _getAccountEarned(farm, account);
            farm.paidRewardPerTokens[account] = farm.storedRewardPerToken;
        }
    }

    function _getAppliedUpdateTime(Farm storage farm) private view returns (uint256) {
        return _isStarted(farm) ? Math.min(_getTimestamp(), farm.endTime) : farm.startTime;
    }

    function _getRewardPerToken(Farm storage farm) private view returns (uint256) {
        if(farm.totalStaked == 0) {
            return farm.storedRewardPerToken;
        }

        return (_getAppliedUpdateTime(farm) - farm.updateTime) * farm.totalReward * 1e40 / farm.duration / farm.totalStaked + farm.storedRewardPerToken;
    }

    function _getAvailableBalance(address token) private view returns (uint256) {
        return IERC20Upgradeable(token).balanceOf(address(this)) - _assignedBalances[token];
    }

    function _isValid(uint256 id) private view returns (bool) {
        return id >= MIN_ID && id < _idTracker;
    }

    function _isStarted(Farm storage farm) private view returns (bool) {
        return _getTimestamp() >= farm.startTime;
    }

    function _isEnded(Farm storage farm) private view returns (bool) {
        return _getTimestamp() >= farm.endTime;
    }

    function _getTimestamp() private view returns (uint256) {
        return block.timestamp;
    }

    function _authorizeUpgrade(address) internal virtual override onlyOwner {}
}