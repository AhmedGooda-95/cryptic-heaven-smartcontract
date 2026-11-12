// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {RoleControl} from "../access/RoleControl.sol";
import {IPriceOracle} from "../interfaces/IPriceOracle.sol";
import {Errors} from "../libraries/Errors.sol";
import {Roles} from "../libraries/Roles.sol";

contract ManualPriceOracle is RoleControl, IPriceOracle {
    struct Feed {
        uint192 priceE18;
        uint64 updatedAt;
    }
    mapping(address asset => Feed feed) public feeds;

    event PriceUpdated(address indexed asset, uint256 priceE18, uint256 updatedAt);

    constructor(address admin) RoleControl(admin) {}

    function setPrice(address asset, uint192 priceE18) external onlyRole(Roles.ADMIN) {
        if (asset == address(0)) revert Errors.ZeroAddress();
        if (priceE18 == 0) revert Errors.InvalidPrice();
        feeds[asset] = Feed(priceE18, uint64(block.timestamp));
        emit PriceUpdated(asset, priceE18, block.timestamp);
    }

    function getPrice(address asset) external view returns (uint256 priceE18, uint256 updatedAt) {
        Feed memory feed = feeds[asset];
        return (feed.priceE18, feed.updatedAt);
    }
}
