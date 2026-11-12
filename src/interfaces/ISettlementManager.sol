// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ISettlementManager {
    function settle(bytes32 transactionId) external;
}
