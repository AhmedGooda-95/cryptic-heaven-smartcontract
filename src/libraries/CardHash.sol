// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library CardHash {
    function derive(address issuer, bytes32 opaqueIdentifier) internal pure returns (bytes32) {
        return keccak256(abi.encode(issuer, opaqueIdentifier));
    }
}
