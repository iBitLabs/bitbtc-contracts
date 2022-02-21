// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

import "./IUnderlyingToken.sol";

contract BitANTEVM is ERC20, ERC20Burnable, ERC20Votes, IUnderlyingToken {
    address private _wrapper;
    address private _governance;

    uint256 private _fee = 500;
    uint256 private constant MAX_FEE = 1000;
    uint256 private constant FEE_RATIO = 1e4;

    mapping (address => bool) private _inWhiteList;
    mapping (address => bool) private _outWhiteList;

    event ChangeFee(uint256 oldFee, uint256 newFee);
    event ChangeGovernance(address oldGovernance, address newGovernance);

    modifier onlyWrapper() {
        require(_msgSender() == _wrapper, "BitANT: not wrapper");
        _;
    }

    modifier onlyGovernance() {
        require(_msgSender() == _governance, "BitANT: not governance");
        _;
    }

    constructor(address governance_) ERC20("BitANT", "BitANT") ERC20Permit("BitANT") {
        _governance = governance_;
    }

    function initWrapper(address wrapper_) external onlyGovernance {
        require(_wrapper == address(0), "BitANT: already initialized");

        _wrapper = wrapper_;
        _inWhiteList[_wrapper] = true;
        _outWhiteList[_wrapper] = true;
    }

    function wrapperMint(address to, uint256 amount) external onlyWrapper override {
        _mint(to, amount);

        emit Mint(to, amount);
    }

    function wrapperBurn(address from, uint256 amount) external onlyWrapper override {
        _burn(from, amount);

        emit Burn(from, amount);
    }

    function setGovernance(address governance_) external onlyGovernance {
        require(governance_ != address(0), "BitANT: invalid governance");

        address old = _governance;
        _governance = governance_;

        emit ChangeGovernance(old, _governance);
    }

    function setFee(uint256 fee_) external onlyGovernance {
        require(fee_ <= MAX_FEE, "BitANT: invalid fee");

        uint256 old = _fee;
        _fee = fee_;

        emit ChangeFee(old, _fee);
    }

    function addInWhiteList(address account) external onlyGovernance {
        _inWhiteList[account] = true;
    }

    function addOutWhiteList(address account) external onlyGovernance {
        _outWhiteList[account] = true;
    }

    function removeInWhiteList(address account) external onlyGovernance {
        _inWhiteList[account] = false;
    }

    function removeOutWhiteList(address account) external onlyGovernance {
        _outWhiteList[account] = false;
    }

    function wrapper() external view override returns (address) {
        return _wrapper;
    }

    function governance() external view returns (address) {
        return _governance;
    }

    function fee() external view returns (uint256) {
        return _fee;
    }

    function isInWhiteList(address account) external view returns (bool) {
        return _inWhiteList[account];
    }

    function isOutWhiteList(address account) external view returns (bool) {
        return _outWhiteList[account];
    }

    function _burn(address account, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._burn(account, amount);
    }

    function _mint(address account, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._mint(account, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        if(_fee == 0 || _outWhiteList[sender] || _inWhiteList[recipient]) {
            super._transfer(sender, recipient, amount);
        } else {
            super._transfer(sender, 0x000000000000000000000000000000000000dEaD, amount * _fee / FEE_RATIO);
            super._transfer(sender, recipient, amount * (FEE_RATIO - _fee) / FEE_RATIO);
        }
    }

    function _afterTokenTransfer(address from, address to, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }
}