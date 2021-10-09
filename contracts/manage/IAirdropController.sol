// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IAirdropController {
    event Created(uint256 id, address indexed token, bytes32 merkleRoot, uint256 deadline, uint256 amount, uint256 count);
    event Recycled(uint256 id, address indexed recipient, uint256 amount);

    function create(address token, bytes32 merkleRoot, uint256 deadline, uint256 amount, uint256 count) external returns (uint256);
    function recycle(uint256 id, address recipient) external;

    function availableBalance(address token) external view returns (uint256);
    function getUnclaimed(uint256 id) external view returns (uint256);
    function isAllClaimed(uint256 id) external view returns (bool);
}