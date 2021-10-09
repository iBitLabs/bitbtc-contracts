// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBridgeableToken {
  function gateway() external view returns (address);
  function bridgeMint(address account, uint256 amount) external;
  function bridgeBurn(address account, uint256 amount) external;
}