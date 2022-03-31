// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IWhitelist {
  function useDiscount(address account) external;
  
  function getDiscount(address account) external view returns (uint256);
  function deadline() external view returns (uint256);
  function isExpired() external view returns (bool);
  function exists(address account) external view returns (bool);
}
