// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {RoleControl} from "../access/RoleControl.sol";
import {IPausable} from "../interfaces/IPausable.sol";
import {Errors} from "../libraries/Errors.sol";
import {Roles} from "../libraries/Roles.sol";

contract EmergencyController is RoleControl {
    event ModulePauseAttempt(address indexed module, bool paused);

    constructor(address admin) RoleControl(admin) {}

    function pauseModule(IPausable module) external onlyRole(Roles.PAUSER) {
        if (address(module) == address(0)) revert Errors.ZeroAddress();
        module.pause();
        emit ModulePauseAttempt(address(module), true);
    }

    function unpauseModule(IPausable module) external onlyRole(Roles.ADMIN) {
        if (address(module) == address(0)) revert Errors.ZeroAddress();
        module.unpause();
        emit ModulePauseAttempt(address(module), false);
    }
}
