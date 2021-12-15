// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "../optimism/IL1ERC20Bridge.sol";
import "../optimism/IL2ERC20Bridge.sol";
import "../optimism/ICrossDomainMessenger.sol";

import "../token/IBridgeableToken.sol";

contract BitBTCL1BridgeOpImp is IL1ERC20Bridge {
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using AddressUpgradeable for address;

  address private _messenger;
  address private _l2TokenBridge;

  modifier onlyEOA() {
    require(!AddressUpgradeable.isContract(msg.sender), "Account not EOA");
    _;
  }

  modifier onlyFromCrossDomainAccount(address _sourceDomainAccount) {
    require(msg.sender == address(getCrossDomainMessenger()), "OVM_XCHAIN: messenger contract unauthenticated");
    require(getCrossDomainMessenger().xDomainMessageSender() == _sourceDomainAccount, "OVM_XCHAIN: wrong sender of cross-domain message");
    _;
  }

  function depositERC20(address _l1Token, address _l2Token, uint256 _amount, uint32 _l2Gas, bytes calldata _data) external override virtual onlyEOA() {
    _initiateERC20Deposit(_l1Token, _l2Token, msg.sender, msg.sender, _amount, _l2Gas, _data);
  }

  function depositERC20To(address _l1Token, address _l2Token, address _to, uint256 _amount, uint32 _l2Gas, bytes calldata _data) external override virtual {
    _initiateERC20Deposit(_l1Token, _l2Token, msg.sender, _to, _amount, _l2Gas, _data);
  }

  function finalizeERC20Withdrawal(address _l1Token, address _l2Token, address _from, address _to, uint256 _amount, bytes calldata _data) external override onlyFromCrossDomainAccount(_l2TokenBridge) {
    IBridgeableToken(_l1Token).bridgeMint(_to, _amount);

    emit ERC20WithdrawalFinalized(_l1Token, _l2Token, _from, _to, _amount, _data);
  }

  function messenger() external view returns (address) {
    return _messenger;
  }

  function l2TokenBridge() external override view returns (address) {
    return _l2TokenBridge;
  }

  function sendCrossDomainMessage(address _crossDomainTarget, uint32 _gasLimit, bytes memory _message) internal {
    getCrossDomainMessenger().sendMessage(_crossDomainTarget, _message, _gasLimit);
  }

  function getCrossDomainMessenger() internal virtual returns (ICrossDomainMessenger) {
    return ICrossDomainMessenger(_messenger);
  }

  function _setOptimsimBridge(address l1messenger_, address l2TokenBridge_) internal virtual {
    require(_messenger == address(0), "Contract has already been initialized.");
    
    _messenger = l1messenger_;
    _l2TokenBridge = l2TokenBridge_;
  }

  function _initiateERC20Deposit(address _l1Token, address _l2Token, address _from, address _to, uint256 _amount, uint32 _l2Gas, bytes calldata _data) internal {
    IBridgeableToken(_l1Token).bridgeBurn(_from, _amount);

    bytes memory message = abi.encodeWithSelector(IL2ERC20Bridge.finalizeDeposit.selector, _l1Token, _l2Token, _from, _to, _amount, _data);
    sendCrossDomainMessage(_l2TokenBridge, _l2Gas, message);

    emit ERC20DepositInitiated(_l1Token, _l2Token, _from, _to, _amount, _data);
  }
}
