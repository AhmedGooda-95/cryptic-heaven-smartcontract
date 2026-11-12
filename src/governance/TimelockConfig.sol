// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {RoleControl} from "../access/RoleControl.sol";
import {Errors} from "../libraries/Errors.sol";
import {Roles} from "../libraries/Roles.sol";

contract TimelockConfig is RoleControl {
    uint64 public immutable minimumDelay;
    mapping(bytes32 operation => uint64 readyAt) public scheduled;

    event OperationScheduled(bytes32 indexed operation, uint64 readyAt);
    event OperationCancelled(bytes32 indexed operation);

    constructor(address admin, uint64 minimumDelay_) RoleControl(admin) {
        if (minimumDelay_ == 0) revert Errors.InvalidConfiguration();
        minimumDelay = minimumDelay_;
    }

    function schedule(bytes32 operation) external onlyRole(Roles.ADMIN) {
        if (operation == bytes32(0) || scheduled[operation] != 0) revert Errors.InvalidConfiguration();
        uint64 readyAt = uint64(block.timestamp) + minimumDelay;
        scheduled[operation] = readyAt;
        emit OperationScheduled(operation, readyAt);
    }

    function consume(bytes32 operation) external onlyRole(Roles.ADMIN) {
        uint64 readyAt = scheduled[operation];
        if (readyAt == 0 || block.timestamp < readyAt) revert Errors.InvalidStatus();
        delete scheduled[operation];
    }

    function cancel(bytes32 operation) external onlyRole(Roles.ADMIN) {
        delete scheduled[operation];
        emit OperationCancelled(operation);
    }
}
