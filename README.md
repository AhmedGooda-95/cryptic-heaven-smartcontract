# Cryptic Heaven Smart Contracts

A modular Solidity codebase for a collateral-backed credit and card-payment protocol. The contracts separate credit management, collateral custody, card authorization, merchant settlement, debt accounting, risk controls, and protocol administration.

## Table of Contents

- [Overview](#overview)
- [Core capabilities](#core-capabilities)
- [Architecture](#architecture)
- [Transaction lifecycle](#transaction-lifecycle)
- [Repository layout](#repository-layout)
- [Technology](#technology)
- [Prerequisites](#prerequisites)
- [Compile the contracts](#compile-the-contracts)
- [Integration and deployment considerations](#integration-and-deployment-considerations)
- [Security considerations](#security-considerations)
- [License](#license)

## Overview

The codebase implements Solidity components for a credit facility backed by supported collateral assets, together with card-based payment authorization and merchant settlement.

At a high level:

1. Users deposit supported ERC-20 collateral into a vault.
2. Asset configuration and oracle prices are used to calculate collateral value and borrowing capacity.
3. A credit manager tracks borrowing and repayment against the user's available credit.
4. An authorization component checks card status, compliance, merchant eligibility, spending policy, and fees before requesting transaction authorization from a card processor.
5. Authorized transactions can be settled to a merchant or reversed.
6. Debt, transaction status, and protocol configuration are maintained by separate modules.

The repository provides interfaces and contracts for several external dependencies, including ERC-20 tokens, a card processor, a compliance provider, and a price oracle.

## Core capabilities

- **Collateral management:** Deposit supported assets and track balances per account and asset.
- **Credit calculation:** Calculate collateral value and borrowing limits using configured loan-to-value (LTV) parameters, oracle prices, and account/global credit caps.
- **Borrowing and repayment:** Record debt, disburse stablecoins through the treasury, and support repayment paths.
- **Card authorization:** Validate card activity and expiry, compliance status, merchant eligibility, spending policy, and fees before authorization.
- **Merchant settlement:** Pay enabled merchants and route transaction fees to the treasury; support reversal of authorized transactions.
- **Risk controls:** Configure spending policies, credit limits, asset risk parameters, and liquidation behavior.
- **Administration and emergency controls:** Role-based access, pausing, timelock configuration, and emergency module controls.
- **Oracle integration:** Route price queries to configured oracle sources, with a manual oracle implementation available in the source tree.

## Architecture

| Contract                 | Responsibility                                                                                                |
| ------------------------ | ------------------------------------------------------------------------------------------------------------- |
| `CreditManager.sol`      | Calculates collateral-backed credit, handles borrowing and repayment, and coordinates collateral withdrawals. |
| `CollateralVault.sol`    | Holds supported collateral tokens and tracks each account's deposited balances.                               |
| `AssetRegistry.sol`      | Stores supported-asset configuration, including whether an asset is enabled and its risk parameters.          |
| `DebtLedger.sol`         | Records and updates account debt.                                                                             |
| `Treasury.sol`           | Holds the protocol stablecoin, disburses funds through authorized roles, and receives revenue.                |
| `CardAuthorization.sol`  | Applies card, compliance, merchant, spending, and fee checks before requesting processor authorization.       |
| `CardRegistry.sol`       | Registers cards and manages their active status.                                                              |
| `MerchantRegistry.sol`   | Stores merchant configuration and payout information.                                                         |
| `FeeManager.sol`         | Configures and calculates transaction fees.                                                                   |
| `TransactionLedger.sol`  | Records card transactions and their statuses.                                                                 |
| `SettlementManager.sol`  | Settles authorized transactions or reverses them.                                                             |
| `LiquidationManager.sol` | Handles liquidation logic for accounts that fail the configured collateral-health requirements.               |
| `RepaymentManager.sol`   | Provides a repayment preview against the account's recorded debt.                                             |

### Repository layout

The main contracts live at the repository root (listed above); the remaining source code is grouped under `src/`:

| Directory         | Contents                                                                                                               |
| ----------------- | ---------------------------------------------------------------------------------------------------------------------- |
| `src/access/`     | Role control, pausing, and reentrancy protection.                                                                      |
| `src/governance/` | Protocol configuration, timelock configuration, and emergency controls.                                                |
| `src/interfaces/` | Interfaces for tokens, oracles, the vault, credit manager, card processor, compliance provider, and related modules.   |
| `src/libraries/`  | Shared roles, errors, events, token-transfer helpers, hashing, decimal conversion, and financial math.                 |
| `src/mocks/`      | Mock tokens, card processor, compliance provider, collateral token, and price oracle for development/integration work. |
| `src/modules/`    | Supporting payout, accrual, asset-risk, and authorization-rule modules.                                                |
| `src/oracle/`     | Oracle routing and manual price-oracle implementations.                                                                |
| `src/registry/`   | Compliance registry implementation.                                                                                    |
| `src/risk/`       | Risk configuration, spending policy, and credit-limit policy.                                                          |
| `src/types/`      | Shared protocol, card, authorization, ledger, and asset configuration types.                                           |

## Transaction lifecycle

The following is a conceptual flow based on the responsibilities and calls in the source code. Exact deployment wiring and operational procedures depend on the addresses and roles configured for a particular deployment.

### 1. Collateral and credit

- An account deposits an enabled collateral token into `CollateralVault`.
- `CreditManager` reads balances from the vault and asset settings from `AssetRegistry`.
- Prices are obtained through the configured `IPriceOracle` implementation.
- The borrowing limit is calculated using each asset's configured maximum LTV and then constrained by the applicable credit cap.
- Borrowing records debt and asks `Treasury` to disburse the stablecoin.

### 2. Card authorization

`CardAuthorization.authorize` checks that the card exists, is active, and has not expired. It also checks compliance, merchant enablement, the spending policy, and the applicable fee. It records the authorization, requests credit for the transaction amount plus fee, and calls the configured card processor.

### 3. Settlement or reversal

- **Settlement:** `SettlementManager.settle` requires an authorized transaction and an enabled merchant. It transfers the transaction amount to the merchant payout address and transfers any fee to the treasury.
- **Reversal:** `SettlementManager.reverse` requires an authorized transaction, attempts to apply the funded amount to the card owner's debt, and routes any remainder to the treasury.

## Technology

- **Language:** Solidity
- **Compiler pragma:** `^0.8.24`
- **Token interfaces:** ERC-20 and ERC-20 metadata interfaces are included in `src/interfaces/`.
- **External integrations represented by interfaces:** price oracle, card processor, and compliance provider.
- **Development support:** mock contracts are included under `src/mocks/`.

## Prerequisites

- Node.js and npm, for running the Solidity compiler through `npx`.
- A Solidity compiler compatible with `^0.8.24`.
- A local copy of this repository.

## Compile the contracts

The snapshot does not include a Foundry `foundry.toml`, Hardhat configuration, npm package manifest, deployment scripts, or test suite. The following command can be used to compile the root-level contract entry points with `solc` without adding a project framework:

```bash
npx --yes solc@0.8.24 \
  --base-path . \
  --bin \
  CreditManager.sol Treasury.sol TransactionLedger.sol \
  CardRegistry.sol CollateralVault.sol FeeManager.sol \
  LiquidationManager.sol CardAuthorization.sol DebtLedger.sol \
  MerchantRegistry.sol RepaymentManager.sol AssetRegistry.sol \
  SettlementManager.sol
```

Run the command from the repository root. The compiler resolves the local relative imports from the repository root (the base path). Review compiler output and address any errors or warnings before proceeding.

To build a repeatable development workflow, add and configure a framework such as Foundry or Hardhat, then add unit, integration, and deployment tests appropriate to the intended target network.

## Integration and deployment considerations

This codebase is composed of contracts that reference one another through constructor-supplied addresses and interfaces. A deployment plan should therefore:

1. Identify the intended stablecoin and supported collateral assets.
2. Deploy the registries, vault, ledger, treasury, risk/policy modules, and protocol managers.
3. Supply the correct deployed addresses to dependent contract constructors.
4. Grant the required roles to the appropriate contracts and operational accounts.
5. Configure supported assets, oracle sources, merchant payout details, fees, credit limits, and risk parameters.
6. Fund the treasury and verify token allowances and transfer paths.
7. Test authorization, settlement, reversal, repayment, liquidation, pause, and role-restriction flows on a local chain or test network before any production deployment.

The exact deployment order and role assignments must be derived from the constructors, access-control checks, and integration requirements of the selected deployment. This README does not provide production addresses or claim that the contracts have been deployed.

## Security considerations

Contracts that custody collateral and move payment funds require independent review before any real-asset deployment: validate access-control roles, oracle price freshness, and risk parameters, and test borrowing, settlement, reversal, and liquidation edge cases.

**Audit status:** No audit report or test results are included in this repository snapshot. No security-audit or production-readiness claim is made here.

## License

The Solidity source files declare the MIT SPDX license identifier. Confirm the project's intended licensing terms and include the applicable license text before distributing the repository.
