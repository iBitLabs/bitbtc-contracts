// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ERC20MultiSender {
  event IncreaseAmount(address account, address token, uint256 amount);
  event MuitiSend(address account, address token, uint256 amount, uint256 count);

  mapping(address => mapping(address => uint256)) private _availableAmounts;

  function increaseAmount(address token, uint256 amount) external {
    address self = address(this);
    address sender = msg.sender;
    IERC20 erc20 = IERC20(token);

    uint256 balance = erc20.balanceOf(self);
    erc20.transferFrom(sender, self, amount);
    uint256 actualAmount = erc20.balanceOf(self) - balance;

    _availableAmounts[sender][token] += actualAmount;

    emit IncreaseAmount(sender, token, actualAmount);
  }

  function multiSend(address token, address[] calldata accounts, uint256[] calldata amounts) external {
    require(accounts.length == amounts.length && accounts.length > 0, "ERC20MultiSender: invalid length");

    address sender = msg.sender;
    uint256 length = accounts.length;
    uint256 total;
    uint256 i;

    for(; i < length; i++) {
      total += amounts[i];
    }

    require(_availableAmounts[sender][token] >= total, "ERC20MultiSender: insufficient balance");

    IERC20 erc20 = IERC20(token);
    _availableAmounts[sender][token] -= total;
    for(i = 0; i < length; i++) {
      erc20.transfer(accounts[i], amounts[i]);
    }

    emit MuitiSend(sender, token, total, length);
  }

  function availableAmount(address account, address token) external view returns (uint256) {
    return _availableAmounts[account][token];
  }
}
