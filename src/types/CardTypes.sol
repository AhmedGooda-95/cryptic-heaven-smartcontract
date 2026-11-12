// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

struct CardRecord {
    address owner;
    bool active;
    uint64 expiresAt;
}
