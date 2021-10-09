// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";

import "./IBridgeableToken.sol";

contract BitANT is UUPSUpgradeable, OwnableUpgradeable, ERC20Upgradeable, ERC20BurnableUpgradeable, ERC20PausableUpgradeable, ERC20VotesUpgradeable, IBridgeableToken {
  address private _gateway;

  bool private _feeOn;
  uint256 private _fee;
  address private _feeCollector;
  uint256 private constant FEE_RATIO = 1e4;

  mapping (address => bool) private _inWhiteList;
  mapping (address => bool) private _outWhiteList;

  modifier onlyBridge() virtual {
    require(_msgSender() == _gateway, "ONLY_BRIDGE");
    _;
  }

  function initialize() public virtual payable initializer {
    __UUPSUpgradeable_init();
    __Ownable_init();
    __ERC20_init("BitANT", "BitANT");
    __ERC20Burnable_init();
    __ERC20Pausable_init();
    __ERC20Permit_init("BitANT");

    _feeOn = true;
    _fee = 500;

    address sender = _msgSender();
    _inWhiteList[sender] = true;
    _outWhiteList[sender] = true;

    _mint(_msgSender(), 1e28);
  }

  function init(address gateway_) external virtual onlyOwner {
    _gateway = gateway_;
  }

  function pause() external virtual onlyOwner whenNotPaused {
    _pause();
  }

  function unpause() external virtual onlyOwner whenPaused {
    _unpause();
  }

  function setFee(uint256 fee_) external onlyOwner {
    _fee = fee_;
  }

  function setFeeOn(bool feeOn_) external onlyOwner {
    _feeOn = feeOn_;
  }

  function setFeeCollector(address feeCollector_) external onlyOwner {
    _feeCollector = feeCollector_;
  }

  function addInWhiteList(address account) external onlyOwner {
    _inWhiteList[account] = true;
  }

  function addOutWhiteList(address account) external onlyOwner {
    _outWhiteList[account] = true;
  }

  function removeInWhiteList(address account) external onlyOwner {
    _inWhiteList[account] = false;
  }

  function removeOutWhiteList(address account) external onlyOwner {
    _outWhiteList[account] = false;
  }

  function bridgeMint(address account, uint256 amount) external override onlyBridge {
    _mint(account, amount);
  }

  function bridgeBurn(address account, uint256 amount) external override onlyBridge {
    _burn(account, amount);
  }

  function gateway() external override view returns (address) {
    return _gateway;
  }

  function fee() external view returns (uint256) {
    return _fee;
  }

  function feeOn() external view returns (bool) {
    return _feeOn;
  }

  function feeCollector() external view returns (address) {
    return _feeCollector;
  }

  function isInWhiteList(address account) external view returns (bool) {
    return _inWhiteList[account];
  }

  function isOutWhiteList(address account) external view returns (bool) {
    return _outWhiteList[account];
  }

  function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
    if(!_feeOn || _feeCollector == address(0) || _inWhiteList[sender] || _outWhiteList[recipient]) {
      super._transfer(sender, recipient, amount);
    } else {
      super._transfer(sender, _feeCollector, amount * _fee / FEE_RATIO);
      super._transfer(sender, recipient, amount * (FEE_RATIO - _fee) / FEE_RATIO);
    }
  }

  function _burn(address account, uint256 amount) internal virtual override(ERC20Upgradeable, ERC20VotesUpgradeable) {
    super._burn(account, amount);
  }

  function _mint(address account, uint256 amount) internal virtual override(ERC20Upgradeable, ERC20VotesUpgradeable) {
    super._mint(account, amount);
  }

  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20Upgradeable, ERC20PausableUpgradeable) {
    super._beforeTokenTransfer(from, to, amount);
  }

  function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20Upgradeable, ERC20VotesUpgradeable) {
    super._afterTokenTransfer(from, to, amount);
  }

  function _authorizeUpgrade(address) internal virtual override onlyOwner {}
}