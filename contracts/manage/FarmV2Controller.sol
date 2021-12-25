// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "./IFarmV2.sol";
import "./IFarmV2Controller.sol";

contract FarmV2Controller is Context, IFarmV2, IFarmV2Controller {
    using SafeERC20 for IERC20;

    struct Farm {
        uint256 farmId;
        address baseToken;
        address rewardToken;
        uint256 totalReward;
        uint256 startTime;
        uint256 endTime;
        uint256 duration;
        uint256 lockDuration;

        uint256 updateTime;
        uint256 totalStaked;

        uint256 claimedReward;
        uint256 numberOfAddresses;
        uint256 storedRewardPerToken;
        mapping(address => uint256) paidRewardPerTokens;
        mapping(address => uint256) accountStaked;
        mapping(address => uint256) rewards;
        mapping(address => uint256) unlockTimes;
        mapping(address => bool) stakedAddresses;
    }

    uint256 private constant MIN_ID = 1e4;
    uint256 private constant MAX_LOCK_DURATION = 2592000;

    address private _governance;
    uint256 private _idTracker;

    mapping (uint256 => Farm) private _farms;
    mapping (address => uint256) private _rewardBalances;

    modifier onlyValid(uint256 farmId) {
        require(_isValid(farmId), "FarmV2Controller: invalid farmId");
        _;
    }

    modifier onlyStaked(uint256 farmId, address account) {
        require(_isStaked(farmId, account), "FarmV2Controller: not stake yet");
        _;
    }

    modifier onlyGovernance() {
        require(_msgSender() == _governance, "FarmV2Controller: not governance");
        _;
    }

    constructor() {
        _idTracker = MIN_ID;
        _governance = _msgSender();
    }

    function increaseReward(address rewardToken, uint256 amount) external override onlyGovernance {
        address self = address(this);
        uint256 oldBalance = IERC20(rewardToken).balanceOf(self);
        IERC20(rewardToken).safeTransferFrom(_msgSender(), self, amount);
        uint256 actualAmount = IERC20(rewardToken).balanceOf(self) - oldBalance;

        _rewardBalances[rewardToken] += actualAmount;

        emit IncreaseReward(rewardToken, actualAmount);
    }

    function create(address baseToken, address rewardToken, uint256 totalReward, uint256 startTime, uint256 endTime, uint256 lockDuration) external override onlyGovernance returns (uint256) {
        require(startTime > _getTimestamp(), "FarmV2Controller: startTime invalid");
        require(startTime < endTime, "FarmV2Controller: startTime must less than endTime");
        require(totalReward > 0, "FarmV2Controller: invalid totalReward");
        require(_rewardBalances[rewardToken] >= totalReward, "FarmV2Controller: insufficient reward balance");
        require(lockDuration <= MAX_LOCK_DURATION, "FarmV2Controller: too long lock");

        uint256 farmId = _idTracker++;

        Farm storage farm = _farms[farmId];
        farm.baseToken = baseToken;
        farm.rewardToken = rewardToken;
        farm.totalReward = totalReward;
        farm.startTime = startTime;
        farm.endTime = endTime;
        farm.duration = endTime - startTime;
        farm.updateTime = startTime;
        farm.lockDuration = lockDuration;

        _rewardBalances[rewardToken] -= totalReward;

        emit Created(farmId, baseToken, rewardToken);

        return farmId;
    }

    function stake(uint256 farmId, uint256 amount) external override onlyValid(farmId) {
        Farm storage farm = _farms[farmId];

        uint256 timestamp = _getTimestamp();
        require(timestamp >= farm.startTime, "FarmV2Controller: not start");
        require(timestamp < farm.endTime, "FarmV2Controller: already ended");
        require(amount > 0, "FarmV2Controller: cannot stake 0");

        address account = _msgSender();
        _updateReward(farm, account);

        address self = address(this);
        uint256 oldBalance = IERC20(farm.baseToken).balanceOf(self);
        IERC20(farm.baseToken).safeTransferFrom(account, self, amount);
        uint256 actualAmount = IERC20(farm.baseToken).balanceOf(self) - oldBalance;

        if(!farm.stakedAddresses[account]) {
            farm.unlockTimes[account] = Math.min(timestamp + farm.lockDuration, farm.endTime);
            farm.stakedAddresses[account] = true;
        }
        if(farm.accountStaked[account] == 0) {
            farm.numberOfAddresses++;
        }

        farm.totalStaked += actualAmount;
        farm.accountStaked[account] += actualAmount;

        emit Staked(farmId, actualAmount);
    }

    function withdraw(uint256 farmId) external override onlyValid(farmId) {
        uint256 reward = _claim(farmId, true);
        address account = _msgSender();

        Farm storage farm = _farms[farmId];
        uint256 amount = farm.accountStaked[account];
        farm.totalStaked -= amount;
        farm.accountStaked[account] = 0;
        farm.paidRewardPerTokens[account] =  0;
        farm.numberOfAddresses--;

        IERC20(farm.baseToken).safeTransfer(account, amount);

        emit Withdrawn(farm.farmId, amount, farm.rewardToken, reward);
    }

    function claim(uint256 farmId) external override onlyValid(farmId) {
        _claim(farmId, false);
    }

    function governance() external override view returns (address) {
        return _governance;
    }

    function maxLockDuration() external override pure returns (uint256) {
        return MAX_LOCK_DURATION;
    }

    function unassignedReward(address rewardToken) external override view returns (uint256) {
        return _rewardBalances[rewardToken];
    }

    function getFarmMeta(uint256 farmId) external override view onlyValid(farmId) returns (address baseToken, address rewardToken, uint256 totalReward, uint256 startTime, uint256 endTime, uint256 lockDuration) {
        Farm storage farm = _farms[farmId];

        rewardToken = farm.rewardToken;
        baseToken = farm.baseToken;
        totalReward = farm.totalReward;
        startTime = farm.startTime;
        endTime = farm.endTime;
        lockDuration = farm.lockDuration;
    }

    function getFarmInfo(uint256 farmId) external override view onlyValid(farmId) returns (uint256 claimedReward, uint256 numberOfAddresses, uint256 totalStaked) {
        Farm storage farm = _farms[farmId];

        claimedReward = farm.claimedReward;
        numberOfAddresses = farm.numberOfAddresses;
        totalStaked = farm.totalStaked;
    }

    function getDepositInfo(uint256 farmId, address account) external override view onlyValid(farmId) onlyStaked(farmId, account) returns (uint256 staked, uint256 unlockTime, uint256 reward) {
        Farm storage farm = _farms[farmId];

        staked = farm.accountStaked[account];
        unlockTime = farm.unlockTimes[account];
        reward = _getAccountEarned(farm, account);
    }

    function _claim(uint256 farmId, bool checkUnlock) private onlyStaked(farmId, _msgSender()) returns (uint256) {
        address account = _msgSender();

        if(checkUnlock) {
            require(_isUnlocked(farmId, account), "FarmV2Controller: not unlock yet");
        }

        Farm storage farm = _farms[farmId];
        _updateReward(farm, account);

        uint256 reward = _getAccountEarned(farm, account);
        farm.rewards[account] = 0;
        farm.claimedReward += reward;

        IERC20(farm.rewardToken).safeTransfer(account, reward);

        emit Claimed(farm.farmId, farm.rewardToken, reward);

        return reward;
    }

    function _getAccountEarned(Farm storage farm, address account) private view returns (uint256) {
        return farm.accountStaked[account] * (_getRewardPerToken(farm) - farm.paidRewardPerTokens[account]) / 1e40 + farm.rewards[account];
    }

    function _updateReward(Farm storage farm, address account) private {
        farm.storedRewardPerToken = _getRewardPerToken(farm);
        farm.updateTime = _getAppliedUpdateTime(farm);
        farm.rewards[account] = _getAccountEarned(farm, account);
        farm.paidRewardPerTokens[account] = farm.storedRewardPerToken;
    }

    function _getAppliedUpdateTime(Farm storage farm) private view returns (uint256) {
        return Math.min(_getTimestamp(), farm.endTime);
    }

    function _getRewardPerToken(Farm storage farm) private view returns (uint256) {
        if(farm.totalStaked == 0) {
            return farm.storedRewardPerToken;
        }

        return (_getAppliedUpdateTime(farm) - farm.updateTime) * farm.totalReward * 1e40 / farm.duration / farm.totalStaked + farm.storedRewardPerToken;
    }

    function _isValid(uint256 id) private view returns (bool) {
        return id >= MIN_ID && id < _idTracker;
    }

    function _isUnlocked(uint256 farmId, address account) private view returns (bool) {
        return _getTimestamp() >= _farms[farmId].unlockTimes[account];
    }

    function _isStaked(uint256 farmId, address account) private view returns (bool) {
        return _farms[farmId].accountStaked[account] > 0;
    }

    function _getTimestamp() private view returns (uint256) {
        return block.timestamp;
    }
}