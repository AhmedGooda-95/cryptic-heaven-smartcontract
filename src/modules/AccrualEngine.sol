// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {InterestMath} from "../libraries/InterestMath.sol";
import {Errors} from "../libraries/Errors.sol";

contract AccrualEngine {
    uint256 public immutable annualRateWad;

    constructor(uint256 annualRateWad_) {
        if (annualRateWad_ > 1e18) revert Errors.InvalidConfiguration();
        annualRateWad = annualRateWad_;
    }

    function interestSince(uint256 principal, uint256 elapsed) external view returns (uint256) {
        return InterestMath.simpleInterest(principal, annualRateWad, elapsed);
    }
}
