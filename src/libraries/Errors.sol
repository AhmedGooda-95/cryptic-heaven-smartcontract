// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library Errors {
    error ZeroAddress();
    error ZeroAmount();
    error Unauthorized();
    error InvalidConfiguration();
    error UnsupportedAsset();
    error InsufficientBalance();
    error InsufficientCredit();
    error DebtOutstanding();
    error StalePrice();
    error InvalidPrice();
    error AlreadyExists();
    error NotFound();
    error Inactive();
    error Expired();
    error LimitExceeded();
    error InvalidStatus();
    error TransferFailed();
}
