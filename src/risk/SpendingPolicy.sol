// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {RoleControl} from "../access/RoleControl.sol";
import {Errors} from "../libraries/Errors.sol";
import {Roles} from "../libraries/Roles.sol";

contract SpendingPolicy is RoleControl {
    uint256 public dailyLimit;
    mapping(address merchant => bool blocked) public blockedMerchants;
    mapping(address account => mapping(uint256 day => uint256 spent)) public spentByDay;

    constructor(address admin, uint256 dailyLimit_) RoleControl(admin) {
        dailyLimit = dailyLimit_;
    }

    function configure(uint256 limit, address merchant, bool blocked) external onlyRole(Roles.ADMIN) {
        if (limit == 0 || merchant == address(0)) revert Errors.InvalidConfiguration();
        dailyLimit = limit;
        blockedMerchants[merchant] = blocked;
    }

    function consume(address account, address merchant, uint256 amount) external onlyRole(Roles.AUTHORIZER) {
        if (blockedMerchants[merchant]) revert Errors.Unauthorized();
        uint256 day = block.timestamp / 1 days;
        uint256 next = spentByDay[account][day] + amount;
        if (next > dailyLimit) revert Errors.LimitExceeded();
        spentByDay[account][day] = next;
    }
}
