// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ICreditManager {
    function availableCredit(address account) external view returns (uint256);
    function borrow(address account, uint256 amount, address recipient) external;
    function repay(address account, uint256 amount) external;
    function repayFromEscrow(address account, uint256 amount) external returns (uint256);
    function collateralValue(address account) external view returns (uint256);
}
