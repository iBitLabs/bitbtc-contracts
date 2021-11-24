// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFarmV3Controller {
    event IncreaseReward(address rewardToken, uint256 amount);
    event Created(uint256 farmId, bytes32 incentiveId, address pool, address rewardToken);
    event Closed(uint256 farmId, bytes32 incentiveId);

    function increaseReward(address rewardToken, uint256 amount) external;
    function create(address pool, address rewardToken, uint256 totalReward, uint256 startTime, uint256 endTime, uint256 lockDuration) external returns (uint256);
    function close(uint256 farmId) external;

    function governance() external view returns (address);
    function maxLockDuration() external view returns (uint256);
    function unassignedReward(address rewardToken) external view returns (uint256);
}