// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./BitBTCL1BridgeOpImp.sol";

contract BitBTCL1Bridge is UUPSUpgradeable, OwnableUpgradeable, BitBTCL1BridgeOpImp {
  function initialize() external initializer {
    __UUPSUpgradeable_init();
    __Ownable_init();
  }

  function setOptimsimBridge(address l1messenger_, address l2TokenBridge_) external onlyOwner {
    _setOptimsimBridge(l1messenger_, l2TokenBridge_);
  }

  function _authorizeUpgrade(address) internal virtual override onlyOwner {}
}
