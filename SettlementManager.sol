// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {RoleControl} from "./src/access/RoleControl.sol";
import {ReentrancyGuard} from "./src/access/ReentrancyGuard.sol";
import {IERC20} from "./src/interfaces/IERC20.sol";
import {ICreditManager} from "./src/interfaces/ICreditManager.sol";
import {MerchantRegistry} from "./MerchantRegistry.sol";
import {TransactionLedger} from "./TransactionLedger.sol";
import {Treasury} from "./Treasury.sol";
import {ProtocolTypes} from "./src/types/ProtocolTypes.sol";
import {TransactionRecord} from "./src/types/LedgerTypes.sol";
import {SafeToken} from "./src/libraries/SafeToken.sol";
import {Errors} from "./src/libraries/Errors.sol";
import {Roles} from "./src/libraries/Roles.sol";

contract SettlementManager is RoleControl, ReentrancyGuard {
    using SafeToken for IERC20;

    IERC20 public immutable stablecoin;
    MerchantRegistry public immutable merchants;
    TransactionLedger public immutable ledger;
    Treasury public immutable treasury;
    ICreditManager public immutable credit;

    event PaymentSettled(bytes32 indexed transactionId, address indexed payout, uint256 amount, uint256 fee);

    constructor(
        address admin,
        IERC20 stablecoin_,
        MerchantRegistry merchants_,
        TransactionLedger ledger_,
        Treasury treasury_,
        ICreditManager credit_
    ) RoleControl(admin) {
        if (
            address(stablecoin_) == address(0) || address(merchants_) == address(0) || address(ledger_) == address(0)
                || address(treasury_) == address(0) || address(credit_) == address(0)
        ) revert Errors.ZeroAddress();
        stablecoin = stablecoin_;
        merchants = merchants_;
        ledger = ledger_;
        treasury = treasury_;
        credit = credit_;
        (bool approved, bytes memory result) =
            address(stablecoin_).call(abi.encodeCall(IERC20.approve, (address(credit_), type(uint256).max)));
        if (!approved || (result.length != 0 && !abi.decode(result, (bool)))) revert Errors.TransferFailed();
    }

    function settle(bytes32 transactionId) external onlyRole(Roles.SETTLER) nonReentrant {
        TransactionRecord memory record = ledger.getTransaction(transactionId);
        if (record.status != ProtocolTypes.TransactionStatus.Authorized) revert Errors.InvalidStatus();
        MerchantRegistry.Merchant memory merchantInfo = merchants.getMerchant(record.merchant);
        if (!merchantInfo.enabled) revert Errors.InvalidConfiguration();
        ledger.setStatus(transactionId, ProtocolTypes.TransactionStatus.Settled);
        stablecoin.safeTransfer(merchantInfo.payout, record.amount);
        if (record.fee > 0) stablecoin.safeTransfer(address(treasury), record.fee);
        emit PaymentSettled(transactionId, merchantInfo.payout, record.amount, record.fee);
    }

    function reverse(bytes32 transactionId) external onlyRole(Roles.SETTLER) nonReentrant {
        TransactionRecord memory record = ledger.getTransaction(transactionId);
        if (record.status != ProtocolTypes.TransactionStatus.Authorized) revert Errors.InvalidStatus();
        uint256 fundedAmount = uint256(record.amount) + record.fee;
        uint256 appliedToDebt = credit.repayFromEscrow(record.cardOwner, fundedAmount);
        if (appliedToDebt < fundedAmount) {
            stablecoin.safeTransfer(address(treasury), fundedAmount - appliedToDebt);
        }
        ledger.setStatus(transactionId, ProtocolTypes.TransactionStatus.Reversed);
    }
}
