// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFarmController {
    event Created(uint256 id, address baseToken, address targetToken);

    function create(address baseToken, address targetToken, uint256 totalReward, uint256 startTime, uint256 endTime) external returns (uint256);
}