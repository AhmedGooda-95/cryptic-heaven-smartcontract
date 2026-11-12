// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library Events {
    event CollateralDeposited(address indexed account, address indexed asset, uint256 amount);
    event CollateralWithdrawn(address indexed account, address indexed asset, uint256 amount);
    event Borrowed(address indexed account, uint256 amount);
    event Repaid(address indexed account, uint256 amount);
    event Authorized(bytes32 indexed transactionId, bytes32 indexed cardId, uint256 amount);
    event Settled(bytes32 indexed transactionId, address indexed merchant, uint256 amount);
}
