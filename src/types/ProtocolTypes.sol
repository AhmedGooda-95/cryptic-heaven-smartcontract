// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library ProtocolTypes {
    enum TransactionStatus {
        None,
        Authorized,
        Settled,
        Reversed,
        Refunded,
        Declined
    }

    struct Price {
        uint256 valueE18;
        uint256 updatedAt;
    }
}
