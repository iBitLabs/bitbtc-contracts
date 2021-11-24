// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFarmV3 {
    event Staked(uint256 farmId, uint256 tokenId);
    event Withdrawn(uint256 farmId, uint256 tokenId, address rewardToken, uint256 reward);
    event Claimed(uint256 farmId, uint256 tokenId, address rewardToken, uint256 reward);

    function stake(uint256 farmId, uint256 tokenId) external;
    function withdraw(uint256 tokenId) external;
    function claim(uint256 tokenId) external;

    function getFarmMeta(uint256 farmId) external view returns (address pool, address rewardToken, uint256 totalReward, uint256 startTime, uint256 endTime, uint256 lockDuration, bytes32 keyId);
    function getFarmInfo(uint256 farmId) external view returns (uint256 claimedReward, uint256 numberOfStakes, uint256 numberOfAddresses, uint256 balance0, uint256 balance1, uint256 liquidity);

    function getDepositMeta(uint256 tokenId) external view returns (address owner, uint256 farmId, uint256 unlockTime);
    function getDepositInfo(uint256 tokenId) external view returns (uint256 liquidity, uint256 balance0, uint256 balance1, uint256 unlockTime, uint256 reward);
    function getFarmDeposit(uint256 farmId, address account) external view returns (uint256[] memory tokenIds);
}