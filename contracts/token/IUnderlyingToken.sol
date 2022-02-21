// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IUnderlyingToken {
  event Mint(address indexed to, uint256 amount);
  event Burn(address indexed from, uint256 amount);

  function wrapper() external view returns (address);
  function wrapperMint(address to, uint256 amount) external;
  function wrapperBurn(address from, uint256 amount) external;
}