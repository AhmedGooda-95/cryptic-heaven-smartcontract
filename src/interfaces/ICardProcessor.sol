// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ICardProcessor {
    function authorize(bytes32 transactionId, bytes32 cardId, address merchant, uint256 amount)
        external
        returns (bool);
    function capture(bytes32 transactionId, address merchant, uint256 amount) external;
    function reverse(bytes32 transactionId, uint256 amount) external;
}
