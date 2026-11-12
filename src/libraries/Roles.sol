// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library Roles {
    bytes32 internal constant ADMIN = keccak256("ADMIN");
    bytes32 internal constant PAUSER = keccak256("PAUSER");
    bytes32 internal constant CREDIT_MANAGER = keccak256("CREDIT_MANAGER");
    bytes32 internal constant SETTLER = keccak256("SETTLER");
    bytes32 internal constant LIQUIDATOR = keccak256("LIQUIDATOR");
    bytes32 internal constant COMPLIANCE = keccak256("COMPLIANCE");
    bytes32 internal constant AUTHORIZER = keccak256("AUTHORIZER");
    bytes32 internal constant TREASURER = keccak256("TREASURER");
}
