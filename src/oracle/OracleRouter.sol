// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {RoleControl} from "../access/RoleControl.sol";
import {IPriceOracle} from "../interfaces/IPriceOracle.sol";
import {Errors} from "../libraries/Errors.sol";
import {Roles} from "../libraries/Roles.sol";

contract OracleRouter is RoleControl, IPriceOracle {
    IPriceOracle public source;
    uint32 public maxAge;
    event OracleConfigured(address indexed source, uint32 maxAge);

    constructor(address admin, IPriceOracle source_, uint32 maxAge_) RoleControl(admin) {
        _setOracle(source_, maxAge_);
    }

    function setOracle(IPriceOracle source_, uint32 maxAge_) external onlyRole(Roles.ADMIN) {
        _setOracle(source_, maxAge_);
    }

    function _setOracle(IPriceOracle source_, uint32 maxAge_) private {
        if (address(source_) == address(0) || maxAge_ == 0) revert Errors.InvalidConfiguration();
        source = source_;
        maxAge = maxAge_;
        emit OracleConfigured(address(source_), maxAge_);
    }

    function getPrice(address asset) external view returns (uint256 priceE18, uint256 updatedAt) {
        (priceE18, updatedAt) = source.getPrice(asset);
        if (priceE18 == 0) revert Errors.InvalidPrice();
        if (updatedAt > block.timestamp || block.timestamp - updatedAt > maxAge) revert Errors.StalePrice();
    }
}
