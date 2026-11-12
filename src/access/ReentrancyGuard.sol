// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

abstract contract ReentrancyGuard {
    uint256 private _entered = 1;

    modifier nonReentrant() {
        require(_entered == 1, "REENTRANT_CALL");
        _entered = 2;
        _;
        _entered = 1;
    }
}
