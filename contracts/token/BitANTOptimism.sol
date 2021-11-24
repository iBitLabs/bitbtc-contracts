// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

import "../optimism/IL2StandardERC20.sol";

contract BitANTOptimism is ERC20, ERC20Burnable, ERC20Votes, IL2StandardERC20 {
  address private _l2Bridge = 0x4200000000000000000000000000000000000010;
  address private _l1Token;

  modifier onlyBridge() {
    require(msg.sender == _l2Bridge, "BitANT: only bridge");
    _;
  }

  constructor(address l1Token_) ERC20("BitANT", "BitANT") ERC20Permit("BitANT") {
    _l1Token = l1Token_;
  }

  function mint(address to, uint256 amount) external override onlyBridge {
    _mint(to, amount);

    emit Mint(to, amount);
  }

  function burn(address from, uint256 amount) external override onlyBridge {
    _burn(from, amount);

    emit Burn(from, amount);
  }

  function supportsInterface(bytes4 interfaceId) external override pure returns (bool) {
    bytes4 firstSupportedInterface = bytes4(keccak256("supportsInterface(bytes4)"));

    bytes4 secondSupportedInterface = IL2StandardERC20.l1Token.selector 
      ^ IL2StandardERC20.mint.selector
      ^ IL2StandardERC20.burn.selector;

    return interfaceId == firstSupportedInterface || interfaceId == secondSupportedInterface;
  }

  function l1Token() external override view returns (address) {
    return _l1Token;
  }

  function l2Bridge() external view returns (address) {
    return _l2Bridge;
  }

  function _burn(address account, uint256 amount) internal override(ERC20, ERC20Votes) {
    super._burn(account, amount);
  }

  function _mint(address account, uint256 amount) internal override(ERC20, ERC20Votes) {
    super._mint(account, amount);
  }

  function _afterTokenTransfer(address from, address to, uint256 amount) internal override(ERC20, ERC20Votes) {
    super._afterTokenTransfer(from, to, amount);
  }
}