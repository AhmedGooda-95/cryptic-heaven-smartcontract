// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {RoleControl} from "./src/access/RoleControl.sol";
import {ReentrancyGuard} from "./src/access/ReentrancyGuard.sol";
import {IERC20} from "./src/interfaces/IERC20.sol";
import {SafeToken} from "./src/libraries/SafeToken.sol";
import {Errors} from "./src/libraries/Errors.sol";
import {Roles} from "./src/libraries/Roles.sol";

contract Treasury is RoleControl, ReentrancyGuard {
    using SafeToken for IERC20;

    IERC20 public immutable stablecoin;
    event Disbursed(address indexed recipient, uint256 amount);
    event RevenueReceived(address indexed from, uint256 amount);

    constructor(address admin, IERC20 stablecoin_) RoleControl(admin) {
        if (address(stablecoin_) == address(0)) revert Errors.ZeroAddress();
        stablecoin = stablecoin_;
    }

    function disburse(address recipient, uint256 amount) external onlyRole(Roles.CREDIT_MANAGER) nonReentrant {
        if (recipient == address(0) || amount == 0) revert Errors.ZeroAmount();
        stablecoin.safeTransfer(recipient, amount);
        emit Disbursed(recipient, amount);
    }

    function receiveRevenue(uint256 amount) external nonReentrant {
        stablecoin.safeTransferFrom(msg.sender, address(this), amount);
        emit RevenueReceived(msg.sender, amount);
    }

    function balance() external view returns (uint256) {
        return stablecoin.balanceOf(address(this));
    }
}
