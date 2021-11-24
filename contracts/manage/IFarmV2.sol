// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFarmV2 {
    event Staked(uint256 farmId, uint256 amount);
    event Withdrawn(uint256 farmId, uint256 amount, address rewardToken, uint256 reward);
    event Claimed(uint256 farmId, address rewardToken, uint256 reward);

    function stake(uint256 farmId, uint256 amount) external;
    function withdraw(uint256 farmId) external;
    function claim(uint256 farmId) external;

    function getFarmMeta(uint256 farmId) external view returns (address baseToken, address rewardToken, uint256 totalReward, uint256 startTime, uint256 endTime, uint256 lockDuration);
    function getFarmInfo(uint256 farmId) external view returns (uint256 claimedReward, uint256 numberOfAddresses, uint256 totalStaked);

    function getDepositInfo(uint256 farmId, address account) external view returns (uint256 staked, uint256 unlockTime, uint256 reward);
}