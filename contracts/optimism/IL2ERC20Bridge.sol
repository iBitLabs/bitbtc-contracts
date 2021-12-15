// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IL2ERC20Bridge {
    event WithdrawalInitiated(address indexed _l1Token, address indexed _l2Token, address indexed _from, address _to, uint256 _amount, bytes _data);
    event DepositFinalized(address indexed _l1Token, address indexed _l2Token, address indexed _from, address _to, uint256 _amount, bytes _data);
    event DepositFailed(address indexed _l1Token, address indexed _l2Token, address indexed _from, address _to, uint256 _amount, bytes _data);

    function l1TokenBridge() external view returns (address);

    function withdraw(address _l2Token, uint256 _amount, uint32 _l1Gas, bytes calldata _data) external;
    function withdrawTo(address _l2Token, address _to, uint256 _amount, uint32 _l1Gas, bytes calldata _data) external;
    function finalizeDeposit(address _l1Token, address _l2Token, address _from, address _to, uint256 _amount, bytes calldata _data) external;
}
