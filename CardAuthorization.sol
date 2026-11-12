// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Pausable} from "./src/access/Pausable.sol";
import {ReentrancyGuard} from "./src/access/ReentrancyGuard.sol";
import {ICardProcessor} from "./src/interfaces/ICardProcessor.sol";
import {ICreditManager} from "./src/interfaces/ICreditManager.sol";
import {ISettlementManager} from "./src/interfaces/ISettlementManager.sol";
import {IComplianceProvider} from "./src/interfaces/IComplianceProvider.sol";
import {CardRegistry} from "./CardRegistry.sol";
import {MerchantRegistry} from "./MerchantRegistry.sol";
import {SpendingPolicy} from "./src/risk/SpendingPolicy.sol";
import {FeeManager} from "./FeeManager.sol";
import {TransactionLedger} from "./TransactionLedger.sol";
import {Errors} from "./src/libraries/Errors.sol";
import {Roles} from "./src/libraries/Roles.sol";

contract CardAuthorization is Pausable, ReentrancyGuard {
    CardRegistry public immutable cards;
    MerchantRegistry public immutable merchants;
    IComplianceProvider public immutable compliance;
    SpendingPolicy public immutable spending;
    FeeManager public immutable fees;
    ICreditManager public immutable credit;
    TransactionLedger public immutable ledger;
    ICardProcessor public immutable processor;
    ISettlementManager public immutable settlement;

    event AuthorizationApproved(bytes32 indexed transactionId, bytes32 indexed cardId, uint256 amount, uint256 fee);

    constructor(
        address admin,
        CardRegistry cards_,
        MerchantRegistry merchants_,
        IComplianceProvider compliance_,
        SpendingPolicy spending_,
        FeeManager fees_,
        ICreditManager credit_,
        TransactionLedger ledger_,
        ICardProcessor processor_,
        ISettlementManager settlement_
    ) Pausable(admin) {
        if (
            address(cards_) == address(0) || address(merchants_) == address(0) || address(compliance_) == address(0)
                || address(spending_) == address(0) || address(fees_) == address(0) || address(credit_) == address(0)
                || address(ledger_) == address(0) || address(processor_) == address(0)
                || address(settlement_) == address(0)
        ) revert Errors.ZeroAddress();
        cards = cards_;
        merchants = merchants_;
        compliance = compliance_;
        spending = spending_;
        fees = fees_;
        credit = credit_;
        ledger = ledger_;
        processor = processor_;
        settlement = settlement_;
    }

    function authorize(bytes32 transactionId, bytes32 cardId, address merchant, uint128 amount)
        external
        whenNotPaused
        onlyRole(Roles.AUTHORIZER)
        nonReentrant
        returns (bool)
    {
        if (amount == 0) revert Errors.ZeroAmount();
        (address owner, bool active, uint64 expiresAt) = cards.cards(cardId);
        if (owner == address(0) || !active) revert Errors.Inactive();
        if (expiresAt < block.timestamp) revert Errors.Expired();
        if (!compliance.isCompliant(owner)) revert Errors.Unauthorized();
        MerchantRegistry.Merchant memory merchantInfo = merchants.getMerchant(merchant);
        if (!merchantInfo.enabled) revert Errors.Unauthorized();
        uint256 fee = fees.feeFor(amount);
        if (fee > type(uint128).max || uint256(amount) + fee > type(uint128).max) revert Errors.LimitExceeded();

        spending.consume(owner, merchant, amount);
        ledger.recordAuthorization(transactionId, owner, merchant, amount, uint128(fee));
        credit.borrow(owner, uint256(amount) + fee, address(settlement));
        bool approved = processor.authorize(transactionId, cardId, merchant, amount);
        if (!approved) revert Errors.Unauthorized();
        emit AuthorizationApproved(transactionId, cardId, amount, fee);
        return true;
    }
}
