// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {MockERC20} from "./MockERC20.sol";

contract MockCollateralToken is MockERC20 {
    constructor(uint8 decimals_) MockERC20("Mock Collateral", "mCOL", decimals_) {}
}
