// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

struct AuthorizationRequest {
    bytes32 transactionId;
    bytes32 cardId;
    address cardOwner;
    address merchant;
    uint256 amount;
    uint32 merchantCategory;
}
