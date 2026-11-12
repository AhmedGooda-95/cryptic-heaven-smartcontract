// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Pausable} from "./src/access/Pausable.sol";
import {ReentrancyGuard} from "./src/access/ReentrancyGuard.sol";
import {IERC20} from "./src/interfaces/IERC20.sol";
import {IERC20Metadata} from "./src/interfaces/IERC20Metadata.sol";
import {IPriceOracle} from "./src/interfaces/IPriceOracle.sol";
import {ICollateralVault} from "./src/interfaces/ICollateralVault.sol";
import {IDebtLedger} from "./src/interfaces/IDebtLedger.sol";
import {AssetRegistry} from "./AssetRegistry.sol";
import {CreditLimitPolicy} from "./src/risk/CreditLimitPolicy.sol";
import {AssetConfig} from "./src/types/AssetConfig.sol";
import {Treasury} from "./Treasury.sol";
import {SafeToken} from "./src/libraries/SafeToken.sol";
import {CreditMath} from "./src/libraries/CreditMath.sol";
import {Errors} from "./src/libraries/Errors.sol";
import {Roles} from "./src/libraries/Roles.sol";

contract CreditManager is Pausable, ReentrancyGuard {
    using SafeToken for IERC20;

    IERC20 public immutable stablecoin;
    ICollateralVault public immutable vault;
    IDebtLedger public immutable ledger;
    AssetRegistry public immutable assets;
    IPriceOracle public immutable oracle;
    Treasury public immutable treasury;
    CreditLimitPolicy public immutable limits;
    uint8 public immutable stablecoinDecimals;

    event CollateralWithdrawn(address indexed account, address indexed asset, uint256 amount);

    constructor(
        address admin,
        IERC20 stablecoin_,
        ICollateralVault vault_,
        IDebtLedger ledger_,
        AssetRegistry assets_,
        IPriceOracle oracle_,
        Treasury treasury_,
        CreditLimitPolicy limits_
    ) Pausable(admin) {
        if (
            address(stablecoin_) == address(0) || address(vault_) == address(0) || address(ledger_) == address(0)
                || address(assets_) == address(0) || address(oracle_) == address(0) || address(treasury_) == address(0)
                || address(limits_) == address(0)
        ) revert Errors.ZeroAddress();
        uint8 decimals_ = IERC20Metadata(address(stablecoin_)).decimals();
        if (decimals_ > 18) revert Errors.InvalidConfiguration();
        stablecoin = stablecoin_;
        vault = vault_;
        ledger = ledger_;
        assets = assets_;
        oracle = oracle_;
        treasury = treasury_;
        limits = limits_;
        stablecoinDecimals = decimals_;
    }

    modifier onlyBorrowerOrAuthorizer(address account) {
        if (msg.sender != account && !hasRole(Roles.AUTHORIZER, msg.sender)) revert Errors.Unauthorized();
        _;
    }

    function collateralValue(address account) public view returns (uint256 valueE18) {
        uint256 count = assets.assetCount();
        for (uint256 i; i < count; ++i) {
            address asset = assets.assetAt(i);
            if (!assets.configOf(asset).enabled) continue;
            uint256 amount = vault.balanceOf(account, asset);
            if (amount == 0) continue;
            (uint256 price,) = oracle.getPrice(asset);
            uint8 decimals_ = IERC20Metadata(asset).decimals();
            if (decimals_ > 18) revert Errors.InvalidConfiguration();
            valueE18 += amount * price / (10 ** decimals_);
        }
    }

    function creditLimit(address account) public view returns (uint256 limit) {
        uint256 count = assets.assetCount();
        for (uint256 i; i < count; ++i) {
            address asset = assets.assetAt(i);
            AssetConfig memory config = assets.configOf(asset);
            if (!config.enabled) continue;
            uint256 amount = vault.balanceOf(account, asset);
            if (amount == 0) continue;
            (uint256 price,) = oracle.getPrice(asset);
            uint8 decimals_ = IERC20Metadata(asset).decimals();
            if (decimals_ > 18) revert Errors.InvalidConfiguration();
            uint256 valueE18 = amount * price / (10 ** decimals_);
            limit += CreditMath.borrowingLimit(valueE18, config.maxLtvBps);
        }
        limit = limit / (10 ** (18 - stablecoinDecimals));
        uint256 cap = limits.capFor(account);
        if (limit > cap) limit = cap;
    }

    function availableCredit(address account) public view returns (uint256) {
        uint256 limit = creditLimit(account);
        uint256 debt = ledger.debtOf(account);
        return limit > debt ? limit - debt : 0;
    }

    function borrow(address account, uint256 amount, address recipient)
        external
        onlyBorrowerOrAuthorizer(account)
        whenNotPaused
        nonReentrant
    {
        if (amount == 0 || recipient == address(0)) revert Errors.ZeroAmount();
        if (amount > availableCredit(account)) revert Errors.InsufficientCredit();
        ledger.recordBorrow(account, amount);
        treasury.disburse(recipient, amount);
    }

    function repay(uint256 amount) external nonReentrant returns (uint256 paid) {
        uint256 debt = ledger.debtOf(msg.sender);
        if (debt == 0) revert Errors.DebtOutstanding();
        paid = amount < debt ? amount : debt;
        if (paid == 0) revert Errors.ZeroAmount();
        stablecoin.safeTransferFrom(msg.sender, address(treasury), paid);
        ledger.recordRepayment(msg.sender, paid);
    }

    function repayFromEscrow(address account, uint256 amount)
        external
        onlyRole(Roles.SETTLER)
        nonReentrant
        returns (uint256 paid)
    {
        uint256 debt = ledger.debtOf(account);
        if (debt == 0) revert Errors.DebtOutstanding();
        paid = amount < debt ? amount : debt;
        if (paid == 0) revert Errors.ZeroAmount();
        stablecoin.safeTransferFrom(msg.sender, address(treasury), paid);
        ledger.recordRepayment(account, paid);
    }

    function withdrawCollateral(address asset, uint256 amount, address recipient)
        external
        whenNotPaused
        nonReentrant
    {
        uint256 balance = vault.balanceOf(msg.sender, asset);
        if (amount == 0 || amount > balance) revert Errors.InsufficientBalance();
        uint256 remaining = balance - amount;
        (uint256 price,) = oracle.getPrice(asset);
        uint8 decimals_ = IERC20Metadata(asset).decimals();
        if (decimals_ > 18) revert Errors.InvalidConfiguration();
        uint256 remainingLimit = remaining * price / (10 ** decimals_);
        remainingLimit = CreditMath.borrowingLimit(remainingLimit, assets.configOf(asset).maxLtvBps);
        uint256 count = assets.assetCount();
        for (uint256 i; i < count; ++i) {
            address other = assets.assetAt(i);
            if (other == asset) continue;
            AssetConfig memory config = assets.configOf(other);
            if (!config.enabled) continue;
            uint256 otherAmount = vault.balanceOf(msg.sender, other);
            if (otherAmount == 0) continue;
            (uint256 otherPrice,) = oracle.getPrice(other);
            uint8 otherDecimals = IERC20Metadata(other).decimals();
            if (otherDecimals > 18) revert Errors.InvalidConfiguration();
            remainingLimit += CreditMath.borrowingLimit(otherAmount * otherPrice / (10 ** otherDecimals), config.maxLtvBps);
        }
        remainingLimit /= 10 ** (18 - stablecoinDecimals);
        uint256 cap = limits.capFor(msg.sender);
        if (remainingLimit > cap) remainingLimit = cap;
        if (remainingLimit < ledger.debtOf(msg.sender)) revert Errors.DebtOutstanding();
        vault.withdraw(msg.sender, asset, amount, recipient);
        emit CollateralWithdrawn(msg.sender, asset, amount);
    }
}
