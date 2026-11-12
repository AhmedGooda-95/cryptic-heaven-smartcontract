// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {RoleControl} from "./src/access/RoleControl.sol";
import {ReentrancyGuard} from "./src/access/ReentrancyGuard.sol";
import {IERC20} from "./src/interfaces/IERC20.sol";
import {IERC20Metadata} from "./src/interfaces/IERC20Metadata.sol";
import {IPriceOracle} from "./src/interfaces/IPriceOracle.sol";
import {ICollateralVault} from "./src/interfaces/ICollateralVault.sol";
import {IDebtLedger} from "./src/interfaces/IDebtLedger.sol";
import {AssetRegistry} from "./AssetRegistry.sol";
import {AssetConfig} from "./src/types/AssetConfig.sol";
import {Treasury} from "./Treasury.sol";
import {SafeToken} from "./src/libraries/SafeToken.sol";
import {Errors} from "./src/libraries/Errors.sol";
import {Roles} from "./src/libraries/Roles.sol";

contract LiquidationManager is RoleControl, ReentrancyGuard {
    using SafeToken for IERC20;

    IERC20 public immutable stablecoin;
    ICollateralVault public immutable vault;
    IDebtLedger public immutable ledger;
    AssetRegistry public immutable assets;
    IPriceOracle public immutable oracle;
    Treasury public immutable treasury;
    uint8 public immutable stablecoinDecimals;

    event Liquidated(address indexed account, address indexed liquidator, address indexed asset, uint256 repaid, uint256 seized);

    constructor(
        address admin,
        IERC20 stablecoin_,
        ICollateralVault vault_,
        IDebtLedger ledger_,
        AssetRegistry assets_,
        IPriceOracle oracle_,
        Treasury treasury_
    ) RoleControl(admin) {
        if (
            address(stablecoin_) == address(0) || address(vault_) == address(0) || address(ledger_) == address(0)
                || address(assets_) == address(0) || address(oracle_) == address(0) || address(treasury_) == address(0)
        ) revert Errors.ZeroAddress();
        stablecoin = stablecoin_;
        vault = vault_;
        ledger = ledger_;
        assets = assets_;
        oracle = oracle_;
        treasury = treasury_;
        stablecoinDecimals = IERC20Metadata(address(stablecoin_)).decimals();
        if (stablecoinDecimals > 18) revert Errors.InvalidConfiguration();
    }

    function liquidate(address account, address asset, uint256 repayAmount)
        external
        onlyRole(Roles.LIQUIDATOR)
        nonReentrant
        returns (uint256 seized)
    {
        if (!assets.configOf(asset).enabled || repayAmount == 0) revert Errors.UnsupportedAsset();
        uint256 debt = ledger.debtOf(account);
        if (debt == 0) revert Errors.DebtOutstanding();
        if (_healthy(account, debt)) revert Errors.InvalidStatus();
        uint256 repay = repayAmount < debt ? repayAmount : debt;
        (uint256 price,) = oracle.getPrice(asset);
        uint8 decimals_ = IERC20Metadata(asset).decimals();
        if (decimals_ > 18) revert Errors.InvalidConfiguration();
        uint256 balance = vault.balanceOf(account, asset);
        uint256 valueE18 = balance * price / (10 ** decimals_);
        uint256 repayValueE18 = repay * (10 ** (18 - stablecoinDecimals));
        uint16 bonus = assets.configOf(asset).liquidationBonusBps;
        uint256 seizeValue = repayValueE18 * (10_000 + bonus) / 10_000;
        if (seizeValue > valueE18) revert Errors.InsufficientBalance();
        seized = seizeValue * (10 ** decimals_) / price;
        stablecoin.safeTransferFrom(msg.sender, address(treasury), repay);
        ledger.reduceDebt(account, repay);
        vault.seize(account, asset, seized, msg.sender);
        emit Liquidated(account, msg.sender, asset, repay, seized);
    }

    function _healthy(address account, uint256 debt) private view returns (bool) {
        uint256 thresholdValue;
        for (uint256 i; i < assets.assetCount(); ++i) {
            address asset = assets.assetAt(i);
            AssetConfig memory config = assets.configOf(asset);
            if (!config.enabled) continue;
            uint256 amount = vault.balanceOf(account, asset);
            if (amount == 0) continue;
            (uint256 price,) = oracle.getPrice(asset);
            uint8 decimals_ = IERC20Metadata(asset).decimals();
            if (decimals_ > 18) revert Errors.InvalidConfiguration();
            thresholdValue += amount * price / (10 ** decimals_) * config.liquidationThresholdBps / 10_000;
        }
        return debt <= thresholdValue / (10 ** (18 - stablecoinDecimals));
    }
}
