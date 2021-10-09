// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAirdrop {
    event Claimed(uint256 id, address indexed account, uint256 amount, uint256 index);

    function claim(uint256 id, uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) external;

    function isExpired(uint256 id) external view returns (bool);
    function isClaimed(uint256 id, uint256 index) external view returns (bool);
}