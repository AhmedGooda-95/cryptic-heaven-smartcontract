// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {CardRegistry} from "../../CardRegistry.sol";
import {MerchantRegistry} from "../../MerchantRegistry.sol";
import {IComplianceProvider} from "../interfaces/IComplianceProvider.sol";
import {Errors} from "../libraries/Errors.sol";

contract AuthorizationRules {
    CardRegistry public immutable cards;
    MerchantRegistry public immutable merchants;
    IComplianceProvider public immutable compliance;

    constructor(CardRegistry cards_, MerchantRegistry merchants_, IComplianceProvider compliance_) {
        if (
            address(cards_) == address(0) || address(merchants_) == address(0) || address(compliance_) == address(0)
        ) revert Errors.ZeroAddress();
        cards = cards_;
        merchants = merchants_;
        compliance = compliance_;
    }

    function check(bytes32 cardId, address merchant) external view returns (address owner) {
        (address cardOwner, bool active, uint64 expiry) = cards.cards(cardId);
        if (!active || expiry < block.timestamp) revert Errors.Inactive();
        if (!merchants.getMerchant(merchant).enabled || !compliance.isCompliant(cardOwner)) {
            revert Errors.Unauthorized();
        }
        return cardOwner;
    }
}
