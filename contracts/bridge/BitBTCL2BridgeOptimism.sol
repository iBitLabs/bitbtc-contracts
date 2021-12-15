// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

import "../optimism/IL1ERC20Bridge.sol";
import "../optimism/IL2ERC20Bridge.sol";
import "../optimism/IL2StandardERC20.sol";
import "../optimism/CrossDomainEnabled.sol";

contract BitBTCL2BridgeOptimism is IL2ERC20Bridge, CrossDomainEnabled {
  address public override l1TokenBridge;

  constructor(address _l2CrossDomainMessenger, address _l1TokenBridge) CrossDomainEnabled(_l2CrossDomainMessenger) {
    l1TokenBridge = _l1TokenBridge;
  }

  function withdraw(address _l2Token, uint256 _amount, uint32 _l1Gas, bytes calldata _data) external override {
    _initiateWithdrawal(_l2Token, msg.sender, msg.sender, _amount, _l1Gas, _data);
  }

  function withdrawTo(address _l2Token, address _to, uint256 _amount, uint32 _l1Gas, bytes calldata _data) external override {
    _initiateWithdrawal(_l2Token, msg.sender, _to, _amount, _l1Gas, _data);
  }

  function finalizeDeposit(address _l1Token, address _l2Token, address _from, address _to, uint256 _amount, bytes calldata _data) external override onlyFromCrossDomainAccount(l1TokenBridge) {
    if (ERC165Checker.supportsInterface(_l2Token, 0x1d1d8b63) && _l1Token == IL2StandardERC20(_l2Token).l1Token()) {
      IL2StandardERC20(_l2Token).mint(_to, _amount);

      emit DepositFinalized(_l1Token, _l2Token, _from, _to, _amount, _data);
    } else {
      bytes memory message = abi.encodeWithSelector(IL1ERC20Bridge.finalizeERC20Withdrawal.selector, _l1Token, _l2Token, _to, _from, _amount, _data);
      
      sendCrossDomainMessage(l1TokenBridge, 0, message);
      emit DepositFailed(_l1Token, _l2Token, _from, _to, _amount, _data);
    }
  }

  function _initiateWithdrawal(address _l2Token, address _from, address _to, uint256 _amount, uint32 _l1Gas, bytes calldata _data) internal {
    IL2StandardERC20(_l2Token).burn(msg.sender, _amount);

    address l1Token = IL2StandardERC20(_l2Token).l1Token();
    bytes memory message = abi.encodeWithSelector(IL1ERC20Bridge.finalizeERC20Withdrawal.selector, l1Token, _l2Token, _from, _to, _amount, _data);

    sendCrossDomainMessage(l1TokenBridge, _l1Gas, message);
    emit WithdrawalInitiated(l1Token, _l2Token, msg.sender, _to, _amount, _data);
  }
}
