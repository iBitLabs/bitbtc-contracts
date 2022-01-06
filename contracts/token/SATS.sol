// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./ISwap.sol";

contract SATS is ERC20, ISwap {
  using SafeERC20 for IERC20;

  enum FeeType {
    Deposit,
    Withdraw
  }

  struct SwapToken {
    address token;
    uint256 ratio;
  }

  uint256 private constant FEE = 5;
  uint256 private constant BASE_RATIO = 1e4;

  bool private _depositFeeOn;
  address private _fund;
  address private _governance;

  SwapToken[] private _swapTokens;
  mapping(address => uint256) private _swapTokenIndexes;

  event SatoshiNakamotoNFT(string message);
  event ChangeFund(address fund, address governance);
  event DepositFeeOn(address governance);
  event AddSwapToken(address token, uint256 ratio, address governance);

  modifier onlyGovernance() {
    require(_msgSender() == _governance, "SATS: not governance");
    _;
  }

  modifier onlySwapToken(address token) {
    require(_isSwapToken(token), "SATS: not swap token");
    _;
  }

  modifier onlyValidIndex(uint256 index) {
    require(index < _swapTokens.length, "SATS: invalid index");
    _;
  }

  constructor(address governance_) ERC20("SATS", "SATS") {
    _governance = governance_;

    emit SatoshiNakamotoNFT("Thank you for creating BTC for all mankind, Satoshi Nakamoto.");
  }

  function deposit(address token, uint256 value) external override onlySwapToken(token) {
    address sender = _msgSender();
    uint256 fee_ = _calcFee(value, FeeType.Deposit);

    address self = address(this);
    uint256 oldBalance = IERC20(token).balanceOf(self);
    IERC20(token).safeTransferFrom(sender, self, value - fee_);
    uint256 actualValue = IERC20(token).balanceOf(self) - oldBalance;

    if(fee_ > 0) {
      IERC20(token).safeTransferFrom(sender, _fund, fee_);
    }

    _mint(sender, actualValue * _getRatio(token));

    emit Deposit(token, sender, value);
  }

  function withdraw(address token, uint256 value) external override onlySwapToken(token) {
    address sender = _msgSender();
    uint256 fee_ = _calcFee(value, FeeType.Withdraw);
    uint256 actualValue = value - fee_;

    IERC20(token).safeTransfer(sender, actualValue);
    IERC20(token).safeTransfer(_fund, fee_);

    _burn(sender, value * _getRatio(token));

    emit Withdraw(token, sender, value);
  }

  function addSwapToken(address token, uint256 ratio) external onlyGovernance {
    require(token != address(0), "SATS: invalid token");
    require(!_isSwapToken(token), "SATS: token already exist");
    require(ratio > 0, "SATS: invalid ratio");

    _swapTokens.push(SwapToken(token, ratio));
    _swapTokenIndexes[token] = _swapTokens.length;

    emit AddSwapToken(token, ratio, _msgSender());
  }

  function setFund(address fund_) external onlyGovernance {
    require(fund_ != address(0), "SATS: invalid fund");

    _fund = fund_;
    emit ChangeFund(_fund, _msgSender());
  }

  function setDepositFeeOn() external onlyGovernance {
    require(!_depositFeeOn, "SATS: deposit fee already on");

    _depositFeeOn = true;

    emit DepositFeeOn(_msgSender());
  }

  function setGovernance(address governance_) external onlyGovernance {
    _governance = governance_;
  }

  function fee() external pure returns (uint256) {
    return FEE;
  }

  function depositFeeOn() external view returns (bool) {
    return _depositFeeOn;
  }

  function fund() external view returns (address) {
    return _fund;
  }

  function governance() external view returns (address) {
    return _governance;
  }

  function isSwapToken(address token) external view returns (bool) {
    return _isSwapToken(token);
  }

  function getSwapToken(uint256 index) external view onlyValidIndex(index) returns (address token, uint256 ratio) {
    SwapToken memory swapToken = _swapTokens[index];

    token = swapToken.token;
    ratio = swapToken.ratio;
  }

  function _calcFee(uint256 value, FeeType feeType) internal view returns (uint256) {
    return (feeType == FeeType.Deposit && !_depositFeeOn) ? 0 : value * FEE / BASE_RATIO;
  }

  function _isSwapToken(address token) internal view returns (bool) {
    return _swapTokenIndexes[token] > 0;
  }

  function _getRatio(address token) internal view returns (uint256) {
    return _swapTokens[_swapTokenIndexes[token] - 1].ratio;
  }
}