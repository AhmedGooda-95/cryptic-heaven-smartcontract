// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ICardProcessor} from "../interfaces/ICardProcessor.sol";

contract MockCardProcessor is ICardProcessor {
    bool public approvalsEnabled = true;
    mapping(bytes32 transactionId => bool captured) public captured;
    event MockAuthorization(bytes32 indexed transactionId, bytes32 indexed cardId, address merchant, uint256 amount);
    event MockCapture(bytes32 indexed transactionId, address merchant, uint256 amount);
    event MockReversal(bytes32 indexed transactionId, uint256 amount);

    function setApprovalsEnabled(bool enabled) external {
        approvalsEnabled = enabled;
    }

    function authorize(bytes32 transactionId, bytes32 cardId, address merchant, uint256 amount)
        external
        returns (bool)
    {
        emit MockAuthorization(transactionId, cardId, merchant, amount);
        return approvalsEnabled;
    }

    function capture(bytes32 transactionId, address merchant, uint256 amount) external {
        captured[transactionId] = true;
        emit MockCapture(transactionId, merchant, amount);
    }

    function reverse(bytes32 transactionId, uint256 amount) external {
        emit MockReversal(transactionId, amount);
    }
}
