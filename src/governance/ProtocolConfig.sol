// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {RoleControl} from "../access/RoleControl.sol";
import {Errors} from "../libraries/Errors.sol";
import {Roles} from "../libraries/Roles.sol";

contract ProtocolConfig is RoleControl {
    address public processor;
    address public feeRecipient;
    uint32 public oracleMaxAge;

    event ConfigChanged(bytes32 indexed key, address indexed account, uint256 value);

    constructor(address admin) RoleControl(admin) {}

    function setProcessor(address next) external onlyRole(Roles.ADMIN) {
        if (next == address(0)) revert Errors.ZeroAddress();
        processor = next;
        emit ConfigChanged(keccak256("PROCESSOR"), next, 0);
    }

    function setFeeRecipient(address next) external onlyRole(Roles.ADMIN) {
        if (next == address(0)) revert Errors.ZeroAddress();
        feeRecipient = next;
        emit ConfigChanged(keccak256("FEE_RECIPIENT"), next, 0);
    }

    function setOracleMaxAge(uint32 age) external onlyRole(Roles.ADMIN) {
        if (age == 0) revert Errors.InvalidConfiguration();
        oracleMaxAge = age;
        emit ConfigChanged(keccak256("ORACLE_MAX_AGE"), address(0), age);
    }
}
