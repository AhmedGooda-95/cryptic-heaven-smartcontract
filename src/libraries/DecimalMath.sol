// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library DecimalMath {
    function toE18(uint256 amount, uint8 decimals) internal pure returns (uint256) {
        require(decimals <= 18, "UNSUPPORTED_DECIMALS");
        return amount * (10 ** (18 - decimals));
    }

    function fromE18(uint256 value, uint8 decimals) internal pure returns (uint256) {
        require(decimals <= 18, "UNSUPPORTED_DECIMALS");
        return value / (10 ** (18 - decimals));
    }
}
