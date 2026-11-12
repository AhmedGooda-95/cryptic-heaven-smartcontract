// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {RoleControl} from "./src/access/RoleControl.sol";
import {ProtocolTypes} from "./src/types/ProtocolTypes.sol";
import {TransactionRecord} from "./src/types/LedgerTypes.sol";
import {Errors} from "./src/libraries/Errors.sol";
import {Roles} from "./src/libraries/Roles.sol";

contract TransactionLedger is RoleControl {
    mapping(bytes32 transactionId => TransactionRecord record) public transactions;
    event TransactionRecorded(bytes32 indexed transactionId, address indexed owner, uint256 amount);
    event TransactionStatusChanged(bytes32 indexed transactionId, ProtocolTypes.TransactionStatus status);

    constructor(address admin) RoleControl(admin) {}

    function recordAuthorization(bytes32 id, address owner, address merchant, uint128 amount, uint128 fee)
        external
        onlyRole(Roles.AUTHORIZER)
    {
        if (id == bytes32(0) || owner == address(0) || merchant == address(0) || amount == 0) {
            revert Errors.InvalidConfiguration();
        }
        if (transactions[id].status != ProtocolTypes.TransactionStatus.None) revert Errors.AlreadyExists();
        transactions[id] = TransactionRecord(owner, merchant, amount, fee, ProtocolTypes.TransactionStatus.Authorized);
        emit TransactionRecorded(id, owner, amount);
    }

    function setStatus(bytes32 id, ProtocolTypes.TransactionStatus status) external {
        if (!hasRole(Roles.SETTLER, msg.sender) && !hasRole(Roles.AUTHORIZER, msg.sender)) {
            revert Errors.Unauthorized();
        }
        TransactionRecord storage transaction = transactions[id];
        if (transaction.status == ProtocolTypes.TransactionStatus.None) revert Errors.NotFound();
        if (transaction.status != ProtocolTypes.TransactionStatus.Authorized) revert Errors.InvalidStatus();
        transaction.status = status;
        emit TransactionStatusChanged(id, status);
    }

    function getTransaction(bytes32 id) external view returns (TransactionRecord memory) {
        return transactions[id];
    }
}
