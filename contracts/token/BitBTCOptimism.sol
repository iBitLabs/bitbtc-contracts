// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "./ISwap.sol";
import "../optimism/IL2StandardERC20.sol";

contract BitBTCOptimism is Context, ERC20, ISwap, IL2StandardERC20 {
  using SafeERC20 for IERC20;

  enum FeeType {
    Deposit,
    Withdraw
  }

  struct LegalToken {
    address token;
    uint256 ratio;
  }

  uint256 private constant FEE = 5;
  uint256 private constant BASE_RATIO = 1e4;

  bool private _depositFeeOn;
  address private _fund;
  address private _governance;

  LegalToken[] private _legalTokens;
  mapping(address => uint256) private _legalTokenIndexes;

  address private _l2Bridge;
  address private _l1Token;

  event SatoshiNakamotoNFT(string message);
  event ChangeFund(address fund, address governance);
  event ChangeGovernance(address oldGovernance, address newGovernance);
  event DepositFeeOn(address governance);
  event AddLegalToken(address token, uint256 ratio, address governance);

  modifier onlyBridge() {
    require(_msgSender() == _l2Bridge, "BitBTC: only bridge");
    _;
  }

  modifier onlyGovernance() {
    require(_msgSender() == _governance, "BitBTC: not governance");
    _;
  }

  modifier onlyLegalToken(address token) {
    require(_isLegalToken(token), "BitBTC: not legal token");
    _;
  }

  constructor(address l2Bridge_, address l1Token_) ERC20("BitBTC", "BitBTC") {
    _l2Bridge = l2Bridge_;
    _l1Token = l1Token_;

    _governance = _msgSender();

    emit SatoshiNakamotoNFT("Thank you for creating BTC for all mankind, Satoshi Nakamoto.");
  }

  function l1Token() external override view returns (address) {
    return _l1Token;
  }

  function l2Bridge() external view returns (address) {
    return _l2Bridge;
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

  function setFund(address fund_) external onlyGovernance {
    require(fund_ != address(0), "BitBTC: invalid fund");

    _fund = fund_;
    emit ChangeFund(_fund, _msgSender());
  }

  function setDepositFeeOn() external onlyGovernance {
    require(!_depositFeeOn, "BitBTC: deposit fee already on");

    _depositFeeOn = true;

    emit DepositFeeOn(_msgSender());
  }

  function setGovernance(address governance_) external onlyGovernance {
    address old = _governance;
    _governance = governance_;

    emit ChangeGovernance(old, _governance);
  }

  function deposit(address token, uint256 value) external override onlyLegalToken(token) {
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

  function withdraw(address token, uint256 value) external override onlyLegalToken(token) {
    address sender = _msgSender();
    uint256 fee_ = _calcFee(value, FeeType.Withdraw);
    uint256 actualValue = value - fee_;

    IERC20(token).safeTransfer(sender, actualValue);
    IERC20(token).safeTransfer(_fund, fee_);

    _burn(sender, value * _getRatio(token));

    emit Withdraw(token, sender, value);
  }

  function addLegalToken(address token) external onlyGovernance {
    require(token != address(0), "BitBTC: token invalid");
    require(!_isLegalToken(token), "BitBTC: already exist");

    uint8 decimals = IERC20Metadata(token).decimals();
    require(decimals > 0, "BitBTC: decimals invalid");

    uint256 ratio = _calcRatio(decimals);

    _legalTokens.push(LegalToken(token, ratio));
    _legalTokenIndexes[token] = _legalTokens.length;

    emit AddLegalToken(token, ratio, _msgSender());
  }

  function mint(address to, uint256 amount) external override onlyBridge {
    _mint(to, amount);

    emit Mint(to, amount);
  }

  function burn(address from, uint256 amount) external override onlyBridge {
    _burn(from, amount);

    emit Burn(from, amount);
  }

  function supportsInterface(bytes4 interfaceId) external override pure returns (bool) {
    bytes4 firstSupportedInterface = bytes4(keccak256("supportsInterface(bytes4)"));

    bytes4 secondSupportedInterface = IL2StandardERC20.l1Token.selector 
      ^ IL2StandardERC20.mint.selector
      ^ IL2StandardERC20.burn.selector;

    return interfaceId == firstSupportedInterface || interfaceId == secondSupportedInterface;
  }

  function isLegalToken(address token) external view returns (bool) {
    return _isLegalToken(token);
  }

  function legalTokens() external view returns (LegalToken[] memory) {
    return _legalTokens;
  }

  function _calcFee(uint256 value, FeeType feeType) internal view returns (uint256) {
    return (feeType == FeeType.Deposit && !_depositFeeOn) ? 0 : value * FEE / BASE_RATIO;
  }

  function _calcRatio(uint8 decimals_) internal view returns (uint256) {
    return 10 ** (decimals() + 6 - decimals_);
  }

  function _isLegalToken(address token) internal view returns (bool) {
    return _legalTokenIndexes[token] > 0;
  }

  function _getRatio(address token) internal view returns (uint256) {
    return _legalTokens[_legalTokenIndexes[token] - 1].ratio;
  }
}