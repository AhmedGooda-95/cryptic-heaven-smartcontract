// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {RoleControl} from "../access/RoleControl.sol";
import {Errors} from "../libraries/Errors.sol";
import {Roles} from "../libraries/Roles.sol";

contract CreditLimitPolicy is RoleControl {
    uint256 public globalLimit;
    mapping(address account => uint256 limit) public overrides;

    constructor(address admin, uint256 globalLimit_) RoleControl(admin) {
        globalLimit = globalLimit_;
    }

    function setGlobalLimit(uint256 limit) external onlyRole(Roles.ADMIN) {
        globalLimit = limit;
    }

    function setAccountLimit(address account, uint256 limit) external onlyRole(Roles.ADMIN) {
        if (account == address(0)) revert Errors.ZeroAddress();
        overrides[account] = limit;
    }

    function capFor(address account) external view returns (uint256) {
        uint256 specific = overrides[account];
        return specific == 0 || specific > globalLimit ? globalLimit : specific;
    }
}
