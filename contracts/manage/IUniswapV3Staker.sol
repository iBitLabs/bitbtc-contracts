// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IUniswapV3Staker {
    struct IncentiveKey {
        address rewardToken;
        address pool;
        uint256 startTime;
        uint256 endTime;
        address refundee;
    }

    function nonfungiblePositionManager() external view returns (address);

    function incentives(bytes32 incentiveId) external view returns (uint256 totalRewardUnclaimed, uint160 totalSecondsClaimedX128, uint96 numberOfStakes);
    function stakes(uint256 tokenId, bytes32 incentiveId) external view returns (uint160 secondsPerLiquidityInsideInitialX128, uint128 liquidity);
    function getRewardInfo(IncentiveKey memory key, uint256 tokenId) external view returns (uint256 reward, uint160 secondsInsideX128);

    function createIncentive(IncentiveKey memory key, uint256 reward) external;
    function endIncentive(IncentiveKey memory key) external returns (uint256 refund);

    function stakeToken(IncentiveKey memory key, uint256 tokenId) external;
    function unstakeToken(IncentiveKey memory key, uint256 tokenId) external;

    function claimReward(address rewardToken, address to, uint256 amountRequested) external returns (uint256 reward);
    function withdrawToken(uint256 tokenId, address to, bytes memory data) external;
}