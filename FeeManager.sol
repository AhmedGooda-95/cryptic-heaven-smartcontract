// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {RoleControl} from "./src/access/RoleControl.sol";
import {Errors} from "./src/libraries/Errors.sol";
import {Roles} from "./src/libraries/Roles.sol";

contract FeeManager is RoleControl {
    uint16 public feeBps;
    event FeeUpdated(uint16 feeBps);

    constructor(address admin, uint16 feeBps_) RoleControl(admin) {
        _setFee(feeBps_);
    }

    function setFee(uint16 feeBps_) external onlyRole(Roles.ADMIN) {
        _setFee(feeBps_);
    }

    function feeFor(uint256 amount) external view returns (uint256) {
        return amount * feeBps / 10_000;
    }

    function _setFee(uint16 feeBps_) private {
        if (feeBps_ > 1_000) revert Errors.InvalidConfiguration();
        feeBps = feeBps_;
        emit FeeUpdated(feeBps_);
    }
}
