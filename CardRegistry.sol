// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {RoleControl} from "./src/access/RoleControl.sol";
import {CardRecord} from "./src/types/CardTypes.sol";
import {Errors} from "./src/libraries/Errors.sol";
import {Roles} from "./src/libraries/Roles.sol";

contract CardRegistry is RoleControl {
    mapping(bytes32 cardId => CardRecord record) public cards;
    mapping(address owner => uint256 count) public cardCount;
    event CardRegistered(bytes32 indexed cardId, address indexed owner);
    event CardStatusChanged(bytes32 indexed cardId, bool active);

    constructor(address admin) RoleControl(admin) {}

    function register(bytes32 cardId, uint64 expiresAt) external {
        if (cardId == bytes32(0) || expiresAt <= block.timestamp) revert Errors.InvalidConfiguration();
        if (cards[cardId].owner != address(0)) revert Errors.AlreadyExists();
        cards[cardId] = CardRecord(msg.sender, true, expiresAt);
        cardCount[msg.sender]++;
        emit CardRegistered(cardId, msg.sender);
    }

    function setActive(bytes32 cardId, bool active) external {
        CardRecord storage card = cards[cardId];
        if (card.owner == address(0)) revert Errors.NotFound();
        if (msg.sender != card.owner && !hasRole(Roles.ADMIN, msg.sender)) revert Errors.Unauthorized();
        card.active = active;
        emit CardStatusChanged(cardId, active);
    }

    function isActive(bytes32 cardId) external view returns (bool) {
        CardRecord memory card = cards[cardId];
        return card.active && card.owner != address(0) && card.expiresAt >= block.timestamp;
    }
}
