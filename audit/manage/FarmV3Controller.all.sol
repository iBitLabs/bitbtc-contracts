pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT



/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}



/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}





/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}



/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}





/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}



/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}



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


interface IUniswapV3Pool {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function liquidity() external view returns (uint128);
}

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