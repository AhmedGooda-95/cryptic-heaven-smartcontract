// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IPriceOracle} from "../interfaces/IPriceOracle.sol";
import {Errors} from "../libraries/Errors.sol";

contract MockPriceOracle is IPriceOracle {
    mapping(address asset => uint256 priceE18) public prices;

    function setPrice(address asset, uint256 priceE18) external {
        if (asset == address(0) || priceE18 == 0) revert Errors.InvalidPrice();
        prices[asset] = priceE18;
    }

    function getPrice(address asset) external view returns (uint256 priceE18, uint256 updatedAt) {
        return (prices[asset], block.timestamp);
    }
}
