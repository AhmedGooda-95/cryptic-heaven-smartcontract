// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AssetRegistry} from "../../AssetRegistry.sol";
import {Errors} from "../libraries/Errors.sol";

contract RiskConfig {
    AssetRegistry public immutable assets;

    constructor(AssetRegistry assets_) {
        if (address(assets_) == address(0)) revert Errors.ZeroAddress();
        assets = assets_;
    }

    function ltvBps(address asset) external view returns (uint16) {
        return assets.configOf(asset).maxLtvBps;
    }

    function liquidationBps(address asset) external view returns (uint16) {
        return assets.configOf(asset).liquidationThresholdBps;
    }
}
