// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ProtocolTypes} from "./ProtocolTypes.sol";

struct TransactionRecord {
    address cardOwner;
    address merchant;
    uint128 amount;
    uint128 fee;
    ProtocolTypes.TransactionStatus status;
}
