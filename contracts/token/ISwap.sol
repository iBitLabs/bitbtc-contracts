// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISwap {
    event Deposit(address indexed token, address account, uint256 amount);
    event Withdraw(address indexed token, address account, uint256 amount);

    function deposit(address token, uint256 amount) external;
    function withdraw(address token, uint256 amount) external;
}