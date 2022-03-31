// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface ISatoshi {
  event Mint(address minter, address recipient, uint256 tokenId, uint256 index);

  function mint(uint256 tokenId) external payable;
  function reward(address recipient, uint256 tokenId) external;

  function baseURI() external view returns (string memory);
  function contractURI() external view returns (string memory);
  function fund() external view returns (address);
  function capacity() external view returns (uint256);
  
  function geniusPrice() external view returns (uint256);
  function deadline() external view returns (uint256);
  function whitelist() external view returns (address);
  function isWhitelistExpired() external view returns (bool);
  function getPrice(address account) external view returns (uint256);
  function exists(uint256 tokenId) external view returns (bool);
  function getData(uint256 tokenId) external view returns (
    bool valid,
    bool minted,
    bool reserved,
    address owner,
    uint256 index,
    uint256 transactionCount,
    uint256 mintAt,
    uint256 tradeAt,
    uint256 mintBlock,
    uint256 tradeBlock
  );
}