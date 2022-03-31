// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IWhitelist.sol";

contract Whitelist is Ownable, IWhitelist {

  struct Coupon {
    address account;
    uint256[] items; 
    uint256 count;
  }

  uint256 private constant MAX_COUNT = 172;

  uint256 private _deadline;
  address private _consumer;
  uint256 private _count;

  mapping(address => Coupon) _coupons;
  mapping(address => bool) _existed;

  event UseDiscount(address account, uint256 discount);

  constructor(uint256 deadline_) {
    _deadline = deadline_;
  }

  function add(address[] calldata accounts, uint256[] calldata discounts) external onlyOwner {
    require(!_isExpired(), "Whitelist: expired");
    require(accounts.length == discounts.length, "Whitelist: length mismatch");
    require(_count + accounts.length <= MAX_COUNT, "Whitelist: cap exceeded");

    uint256 length = accounts.length;
    address account;
    for(uint256 i = 0; i < length; i++) {
      account = accounts[i];
      if(_exists(account)) {
        _coupons[account].items.push(discounts[i]);
      } else {
        Coupon storage coupon = _coupons[account];
        coupon.account = account;
        coupon.items.push(discounts[i]);

        _existed[account] = true;
      }
    }

    _count += length;
  }

  function setConsumer(address consumer_) external onlyOwner {
    require(!_isExpired(), "Whitelist: expired");
    require(_consumer == address(0), "Whitelist: consumer already set");

    _consumer = consumer_;
  }

  function useDiscount(address account) external override {
    require(_consumer == _msgSender(), "Whitelist: not the consumer");

    require(!_isExpired(), "Whitelist: expired");
    require(_exists(account), "Whitelist: not on the whitelist");
    require(_hasDiscount(account), "Whitelist: discount used");

    uint256 discount = _getDiscount(account);
    _coupons[account].count += 1;

    emit UseDiscount(account, discount);
  }

  function getDiscount(address account) external view override returns (uint256) {
    return !_isExpired() && _exists(account) && _hasDiscount(account) ? _getDiscount(account) : 0;
  }

  function deadline() external view override returns (uint256) {
    return _deadline;
  }

  function consumer() external view returns (address) {
    return _consumer;
  }

  function count() external view returns (uint256) {
    return _count;
  }

  function isExpired() external view override returns (bool) {
    return _isExpired();
  }

  function exists(address account) external view override returns (bool) {
    return _exists(account);
  }

  function _isExpired() private view returns (bool) {
    return block.timestamp > _deadline;
  }

  function _exists(address account) private view returns (bool) {
    return _existed[account];
  }

  function _hasDiscount(address account) private view returns (bool) {
    return _coupons[account].count < _coupons[account].items.length;
  }

  function _getDiscount(address account) private view returns (uint256) {
    return _coupons[account].items[_coupons[account].count];
  }
}