// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {RoleControl} from "./src/access/RoleControl.sol";
import {IDebtLedger} from "./src/interfaces/IDebtLedger.sol";
import {Errors} from "./src/libraries/Errors.sol";
import {Roles} from "./src/libraries/Roles.sol";

contract DebtLedger is RoleControl, IDebtLedger {
    mapping(address account => uint256 amount) public debtOf;
    uint256 public totalDebt;

    event DebtIncreased(address indexed account, uint256 amount);
    event DebtReduced(address indexed account, uint256 amount);

    constructor(address admin) RoleControl(admin) {}

    function recordBorrow(address account, uint256 amount) external onlyRole(Roles.CREDIT_MANAGER) {
        if (account == address(0) || amount == 0) revert Errors.ZeroAmount();
        debtOf[account] += amount;
        totalDebt += amount;
        emit DebtIncreased(account, amount);
    }

    function recordRepayment(address account, uint256 amount)
        external
        onlyRole(Roles.CREDIT_MANAGER)
        returns (uint256 paid)
    {
        paid = _reduce(account, amount);
    }

    function reduceDebt(address account, uint256 amount)
        external
        onlyRole(Roles.LIQUIDATOR)
        returns (uint256 paid)
    {
        paid = _reduce(account, amount);
    }

    function _reduce(address account, uint256 amount) private returns (uint256 paid) {
        uint256 debt = debtOf[account];
        paid = amount < debt ? amount : debt;
        debtOf[account] = debt - paid;
        totalDebt -= paid;
        emit DebtReduced(account, paid);
    }
}
