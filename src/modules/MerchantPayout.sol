// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {RoleControl} from "../access/RoleControl.sol";
import {ReentrancyGuard} from "../access/ReentrancyGuard.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {SafeToken} from "../libraries/SafeToken.sol";
import {Errors} from "../libraries/Errors.sol";
import {Roles} from "../libraries/Roles.sol";

contract MerchantPayout is RoleControl, ReentrancyGuard {
    using SafeToken for IERC20;

    IERC20 public immutable stablecoin;
    event Paid(address indexed recipient, uint256 amount, bytes32 indexed referenceId);

    constructor(address admin, IERC20 stablecoin_) RoleControl(admin) {
        if (address(stablecoin_) == address(0)) revert Errors.ZeroAddress();
        stablecoin = stablecoin_;
    }

    function pay(address recipient, uint256 amount, bytes32 referenceId)
        external
        onlyRole(Roles.SETTLER)
        nonReentrant
    {
        if (recipient == address(0) || amount == 0) revert Errors.ZeroAmount();
        stablecoin.safeTransfer(recipient, amount);
        emit Paid(recipient, amount, referenceId);
    }
}
