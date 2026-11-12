// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IDebtLedger} from "./src/interfaces/IDebtLedger.sol";
import {Errors} from "./src/libraries/Errors.sol";

contract RepaymentManager {
    IDebtLedger public immutable ledger;

    constructor(IDebtLedger ledger_) {
        if (address(ledger_) == address(0)) revert Errors.ZeroAddress();
        ledger = ledger_;
    }

    function previewRepayment(address account, uint256 offered) external view returns (uint256) {
        uint256 debt = ledger.debtOf(account);
        return offered < debt ? offered : debt;
    }
}
