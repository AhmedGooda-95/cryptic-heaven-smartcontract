// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IDebtLedger {
    function debtOf(address account) external view returns (uint256);
    function recordBorrow(address account, uint256 amount) external;
    function recordRepayment(address account, uint256 amount) external returns (uint256);
    function reduceDebt(address account, uint256 amount) external returns (uint256);
}
