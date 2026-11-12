// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {RoleControl} from "../access/RoleControl.sol";
import {IComplianceProvider} from "../interfaces/IComplianceProvider.sol";
import {Roles} from "../libraries/Roles.sol";

contract ComplianceRegistry is RoleControl, IComplianceProvider {
    mapping(address account => bool) public isCompliant;
    event ComplianceUpdated(address indexed account, bool compliant);

    constructor(address admin) RoleControl(admin) {}

    function setCompliance(address account, bool compliant) external onlyRole(Roles.COMPLIANCE) {
        isCompliant[account] = compliant;
        emit ComplianceUpdated(account, compliant);
    }
}
