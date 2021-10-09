// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFarm {
    event Staked(uint256 id, address indexed account, uint256 amount);
    event Withdrawn(uint256 id, address indexed account, uint256 amount);
    event Claimed(uint256 id, address indexed account, uint256 amount);

    function stake(uint256 id, uint256 amount) external;
    function withdraw(uint256 id, uint256 amount) external;
    function claim(uint256 id) external;
    function exit(uint256 id) external;

    function getMeta(uint256 id_) external returns (uint256 id, address baseToken, address targetToken, uint256 startTime, uint256 endTime, uint256 duration);
    function getTotalStaked(uint256 id) external view returns (uint256);
    function getAccountStaked(uint256 id, address account) external view returns (uint256);
    function getAccountEarned(uint256 id, address account) external view returns (uint256);
    function getTotalReward(uint256 id) external view returns (uint256) ;
    function getCurrentReward(uint256 id) external view returns (uint256);
}