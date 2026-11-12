// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library InterestMath {
    uint256 internal constant YEAR = 365 days;
    uint256 internal constant WAD = 1e18;

    function simpleInterest(uint256 principal, uint256 annualRateWad, uint256 elapsed)
        internal
        pure
        returns (uint256)
    {
        return principal * annualRateWad * elapsed / WAD / YEAR;
    }
}
