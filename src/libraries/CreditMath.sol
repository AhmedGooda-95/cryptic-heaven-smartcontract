// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Math} from "./Math.sol";

library CreditMath {
    uint256 internal constant BPS = 10_000;

    function borrowingLimit(uint256 valueE18, uint16 ltvBps) internal pure returns (uint256) {
        return Math.mulDiv(valueE18, ltvBps, BPS);
    }

    function liquidationValue(uint256 debt, uint16 thresholdBps) internal pure returns (uint256) {
        return Math.mulDiv(debt, BPS, thresholdBps);
    }
}
