// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "./IFarmV3.sol";
import "./IFarmV3Controller.sol";
import "./IUniswapV3Staker.sol";
import "./IUniswapV3Pool.sol";

contract FarmV3Controller is Context, IFarmV3Controller, IFarmV3, IERC721Receiver {
    using SafeERC20 for IERC20;

    struct Farm {
        uint256 farmId;
        IUniswapV3Pool pool;
        IERC20 token0;
        IERC20 token1;
        address rewardToken;
        uint256 totalReward;
        uint256 startTime;
        uint256 endTime;
        uint256 lockDuration;

        bytes32 incentiveId;
        IUniswapV3Staker.IncentiveKey key;

        uint256 numberOfAddresses;
        mapping(address => uint256) addressStaked;
        uint256 liquidity;
        mapping(address => uint256[]) stakedTokenIds;
    }

    struct Deposit {
        uint256 tokenId;
        address owner;
        uint256 farmId;
        uint256 unlockTime;
    }

    uint256 private constant MIN_ID = 1e4;
    uint256 private constant MAX_LOCK_DURATION = 2592000;

    address private _governance;
    uint256 private _idTracker;

    IUniswapV3Staker private _staker;
    IERC721 private _nft;

    mapping (address => bool) private _tokenApproved;
    mapping (uint256 => Farm) private _farms;
    mapping (uint256 => Deposit) private _deposits;
    mapping (address => uint256) private _rewardBalances;

    modifier onlyValid(uint256 farmId) {
        require(_isValid(farmId), "FarmV3Controller: invalid farmId");
        _;
    }

    modifier onlyStaked(uint256 tokenId) {
        require(_isStaked(tokenId), "FarmV3Controller: not stake yet");
        _;
    }

    modifier onlyGovernance() {
        require(_msgSender() == _governance, "FarmV3Controller: not governance");
        _;
    }

    constructor(address staker_) {
        _staker = IUniswapV3Staker(staker_);
        _nft = IERC721(_staker.nonfungiblePositionManager());

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

    function create(address pool, address rewardToken, uint256 totalReward, uint256 startTime, uint256 endTime, uint256 lockDuration) external override onlyGovernance returns (uint256) {
        require(startTime > _getTimestamp(), "FarmV3Controller: startTime invalid");
        require(startTime < endTime, "FarmV3Controller: startTime must less than endTime");
        require(totalReward > 0, "FarmV3Controller: invalid totalReward");
        require(_rewardBalances[rewardToken] >= totalReward, "FarmV3Controller: insufficient reward balance");
        require(lockDuration <= MAX_LOCK_DURATION, "FarmV3Controller: too long lock");

        IUniswapV3Staker.IncentiveKey memory key = IUniswapV3Staker.IncentiveKey(rewardToken, pool, startTime, endTime, address(this));
        bytes32 incentiveId = keccak256(abi.encode(key));

        uint256 farmId = _idTracker++;

        Farm storage farm = _farms[farmId];

        farm.pool = IUniswapV3Pool(pool);
        farm.token0 = IERC20(farm.pool.token0());
        farm.token1 = IERC20(farm.pool.token1());

        farm.rewardToken = rewardToken;
        farm.totalReward = totalReward;
        farm.startTime = startTime;
        farm.endTime = endTime;
        farm.lockDuration = lockDuration;
        farm.key = key;
        farm.incentiveId = incentiveId;

        if(!_tokenApproved[rewardToken]) {
            IERC20(rewardToken).safeApprove(address(_staker), type(uint256).max);
            _tokenApproved[rewardToken] = true;
        }
        
        _rewardBalances[rewardToken] -= totalReward;
        _staker.createIncentive(key, totalReward);

        emit Created(farmId, incentiveId, pool, rewardToken);

        return farmId;
    }

    function close(uint256 farmId) external override onlyValid(farmId) onlyGovernance {
        Farm storage farm = _farms[farmId];

        _staker.endIncentive(farm.key);

        emit Closed(farmId, farm.incentiveId);
    }

    function stake(uint256 farmId, uint256 tokenId) external override onlyValid(farmId) {
        Farm storage farm = _farms[farmId];

        uint256 timestamp = _getTimestamp();
        require(timestamp >= farm.startTime, "FarmV3Controller: not start");
        require(timestamp < farm.endTime, "FarmV3Controller: already ended");

        address account = _msgSender();

        _nft.safeTransferFrom(account, address(this), tokenId);
        _nft.safeTransferFrom(address(this), address(_staker), tokenId);

        _deposits[tokenId] = Deposit(tokenId, account, farmId, Math.min(timestamp + farm.lockDuration, farm.endTime));

        _staker.stakeToken(farm.key, tokenId);

        (, uint128 _liquidity) = _staker.stakes(tokenId, farm.incentiveId);
        farm.liquidity += uint256(_liquidity);

        if(farm.addressStaked[account] == 0) {
            farm.numberOfAddresses++;
        }
        farm.addressStaked[account]++;

        farm.stakedTokenIds[account].push(tokenId);

        emit Staked(farmId, tokenId);
    }

    function withdraw(uint256 tokenId) external override {
        address account = _msgSender();
        uint256 reward = _claim(tokenId, account, true, true);

        _staker.withdrawToken(tokenId, account, "");

        uint256 farmId = _deposits[tokenId].farmId;
        Farm storage farm = _farms[farmId];
        farm.addressStaked[account]--;

        if(farm.addressStaked[account] == 0) {
            farm.numberOfAddresses--;
        }

        uint256 index = _findArrayIndex(farm.stakedTokenIds[account], tokenId) - 1;
        _removeArrayValue(farm.stakedTokenIds[account], index);

        delete _deposits[tokenId];

        emit Withdrawn(farmId, tokenId, farm.rewardToken, reward);
    }

    function claim(uint256 tokenId) external override {
        address account = _msgSender();
        uint256 reward = _claim(tokenId, account, false, false);

        uint256 farmId = _deposits[tokenId].farmId;
        Farm storage farm = _farms[farmId];
        _staker.stakeToken(farm.key, tokenId);
    
        emit Claimed(farmId, tokenId, farm.rewardToken, reward);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
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

    function getFarmMeta(uint256 farmId) external override view onlyValid(farmId) returns (address pool, address rewardToken, uint256 totalReward, uint256 startTime, uint256 endTime, uint256 lockDuration, bytes32 incentiveId) {
        Farm storage farm = _farms[farmId];

        pool = address(farm.pool);
        rewardToken = farm.rewardToken;
        totalReward = farm.totalReward;
        startTime = farm.startTime;
        endTime = farm.endTime;
        lockDuration = farm.lockDuration;
        incentiveId = farm.incentiveId;
    }

    function getFarmInfo(uint256 farmId) external override view onlyValid(farmId) returns (uint256 claimedReward, uint256 numberOfStakes, uint256 numberOfAddresses, uint256 balance0, uint256 balance1, uint256 liquidity) {
        Farm storage farm = _farms[farmId];

        (uint256 totalRewardUnclaimed, ,uint96 numberOfStakes_) = _staker.incentives(farm.incentiveId);
        numberOfStakes = uint256(numberOfStakes_);
        claimedReward = farm.totalReward - totalRewardUnclaimed;
        numberOfAddresses = farm.numberOfAddresses;

        uint256 balance0_ = farm.token0.balanceOf(address(farm.pool));
        uint256 balance1_ = farm.token1.balanceOf(address(farm.pool));
        uint256 liquidity_ = uint256(farm.pool.liquidity());

        liquidity = farm.liquidity;

        balance0 = balance0_ * liquidity / liquidity_;
        balance1 = balance1_ * liquidity / liquidity_;
    }

    function getDepositMeta(uint256 tokenId) external override view onlyStaked(tokenId) returns (address owner, uint256 farmId, uint256 unlockTime) {
        Deposit memory deposit = _deposits[tokenId];

        owner = deposit.owner;
        farmId = deposit.farmId;
        unlockTime = deposit.unlockTime;
    }

    function getDepositInfo(uint256 tokenId) external override view onlyStaked(tokenId) returns (uint256 liquidity, uint256 balance0, uint256 balance1, uint256 unlockTime, uint256 reward) {
        Deposit memory deposit = _deposits[tokenId];
        Farm storage farm = _farms[deposit.farmId];

        (, uint128 _liquidity) = _staker.stakes(tokenId, farm.incentiveId);
        liquidity = uint256(_liquidity);
        
        uint256 totalLiquidity = uint256(farm.pool.liquidity());
        uint256 balance0_ = farm.token0.balanceOf(address(farm.pool));
        uint256 balance1_ = farm.token1.balanceOf(address(farm.pool));
        balance0 = balance0_ * liquidity / totalLiquidity;
        balance1 = balance1_ * liquidity / totalLiquidity;

        unlockTime = deposit.unlockTime;
        (reward, ) = _staker.getRewardInfo(farm.key, tokenId);
    }

    function getFarmDeposit(uint256 farmId, address account) external override view onlyValid(farmId) returns (uint256[] memory tokenIds) {
        Farm storage farm = _farms[farmId];

        tokenIds = farm.stakedTokenIds[account];
    }

    function _claim(uint256 tokenId, address sender, bool updateLiquidity, bool checkUnlock) private returns (uint256) {
        require(_isStaked(tokenId), "FarmV3Controller: not stake yet");

        Deposit memory deposit = _deposits[tokenId];

        require(deposit.owner == sender, "FarmV3Controller: not the owner");
        if(checkUnlock) {
            require(_getTimestamp() >= deposit.unlockTime, "FarmV3Controller: not unlock yet");
        }

        Farm storage farm = _farms[deposit.farmId];

        if(updateLiquidity) {
            (, uint128 _liquidity) = _staker.stakes(tokenId, farm.incentiveId);
            farm.liquidity -= uint256(_liquidity);
        }

        address account = deposit.owner;
        (uint256 reward, ) = _staker.getRewardInfo(farm.key, tokenId);
        _staker.unstakeToken(farm.key, tokenId);

        return _staker.claimReward(farm.key.rewardToken, account, reward);
    }

    function _isValid(uint256 farmId) private view returns (bool) {
        return farmId >= MIN_ID && farmId < _idTracker;
    }

    function _isStaked(uint256 tokenId) private view returns (bool) {
        return tokenId > 0 && _deposits[tokenId].tokenId == tokenId;
    }

    function _getTimestamp() private view returns (uint256) {
        return block.timestamp;
    }

    function _findArrayIndex(uint256[] memory array, uint256 value) private pure returns (uint256) {
        for(uint256 i = 0; i < array.length; i++) {
            if(array[i] == value) {
                return i + 1;
            }
        }

        return 0;
    }

    function _removeArrayValue(uint256[] storage array, uint256 index) private {
        uint256 lastIndex = array.length - 1;
        uint256 lastValue = array[lastIndex];

        array[lastIndex] = array[index];
        array[index] = lastValue;
        array.pop();
    }
}