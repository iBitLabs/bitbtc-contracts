// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ICrossDomainMessenger.sol";

contract CrossDomainEnabled {
  address public messenger;

  constructor(address _messenger) {
    messenger = _messenger;
  }

  modifier onlyFromCrossDomainAccount(address _sourceDomainAccount) {
    require(msg.sender == address(getCrossDomainMessenger()), "OVM_XCHAIN: messenger contract unauthenticated");
    require(getCrossDomainMessenger().xDomainMessageSender() == _sourceDomainAccount, "OVM_XCHAIN: wrong sender of cross-domain message");
    _;
  }

  function getCrossDomainMessenger() internal virtual returns (ICrossDomainMessenger) {
    return ICrossDomainMessenger(messenger);
  }

  function sendCrossDomainMessage(address _crossDomainTarget, uint32 _gasLimit, bytes memory _message) internal {
    getCrossDomainMessenger().sendMessage(_crossDomainTarget, _message, _gasLimit);
  }
}
