// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {RoleControl} from "./RoleControl.sol";
import {Roles} from "../libraries/Roles.sol";

abstract contract Pausable is RoleControl {
    bool public paused;
    event Paused(address indexed account);
    event Unpaused(address indexed account);

    constructor(address admin) RoleControl(admin) {}

    modifier whenNotPaused() {
        require(!paused, "PAUSED");
        _;
    }

    function pause() external onlyRole(Roles.PAUSER) {
        paused = true;
        emit Paused(msg.sender);
    }

    function unpause() external onlyRole(Roles.ADMIN) {
        paused = false;
        emit Unpaused(msg.sender);
    }
}
