// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256) {
        return x * y / denominator;
    }
}
