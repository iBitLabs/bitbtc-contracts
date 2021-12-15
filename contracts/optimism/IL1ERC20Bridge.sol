// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IL1ERC20Bridge {
    event ERC20DepositInitiated(address indexed _l1Token, address indexed _l2Token, address indexed _from, address _to, uint256 _amount, bytes _data);
    event ERC20WithdrawalFinalized(address indexed _l1Token, address indexed _l2Token, address indexed _from, address _to, uint256 _amount, bytes _data);

    function l2TokenBridge() external returns (address);

    function depositERC20(address _l1Token, address _l2Token, uint256 _amount, uint32 _l2Gas, bytes calldata _data) external;
    function depositERC20To(address _l1Token, address _l2Token, address _to, uint256 _amount, uint32 _l2Gas, bytes calldata _data) external;
    function finalizeERC20Withdrawal(address _l1Token, address _l2Token, address _from,  address _to, uint256 _amount, bytes calldata _data) external;
}
