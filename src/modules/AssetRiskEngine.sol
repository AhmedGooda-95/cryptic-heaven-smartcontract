// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20Metadata} from "../interfaces/IERC20Metadata.sol";
import {IPriceOracle} from "../interfaces/IPriceOracle.sol";
import {ICollateralVault} from "../interfaces/ICollateralVault.sol";
import {AssetRegistry} from "../../AssetRegistry.sol";
import {AssetConfig} from "../types/AssetConfig.sol";
import {CreditMath} from "../libraries/CreditMath.sol";
import {Errors} from "../libraries/Errors.sol";

contract AssetRiskEngine {
    AssetRegistry public immutable assets;
    ICollateralVault public immutable vault;
    IPriceOracle public immutable oracle;

    constructor(AssetRegistry assets_, ICollateralVault vault_, IPriceOracle oracle_) {
        if (
            address(assets_) == address(0) || address(vault_) == address(0) || address(oracle_) == address(0)
        ) revert Errors.ZeroAddress();
        assets = assets_;
        vault = vault_;
        oracle = oracle_;
    }

    function collateralAndLimit(address account) external view returns (uint256 valueE18, uint256 limitE18) {
        for (uint256 i; i < assets.assetCount(); ++i) {
            address asset = assets.assetAt(i);
            AssetConfig memory config = assets.configOf(asset);
            if (!config.enabled) continue;
            uint256 amount = vault.balanceOf(account, asset);
            if (amount == 0) continue;
            (uint256 price,) = oracle.getPrice(asset);
            uint8 decimals_ = IERC20Metadata(asset).decimals();
            if (decimals_ > 18) revert Errors.InvalidConfiguration();
            uint256 value = amount * price / (10 ** decimals_);
            valueE18 += value;
            limitE18 += CreditMath.borrowingLimit(value, config.maxLtvBps);
        }
    }

}
