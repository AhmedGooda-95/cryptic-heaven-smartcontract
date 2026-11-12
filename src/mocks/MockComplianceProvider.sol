// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IComplianceProvider} from "../interfaces/IComplianceProvider.sol";

contract MockComplianceProvider is IComplianceProvider {
    mapping(address account => bool compliant) public isCompliant;

    function setCompliance(address account, bool compliant) external {
        isCompliant[account] = compliant;
    }
}
