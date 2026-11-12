// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {RoleControl} from "./src/access/RoleControl.sol";
import {AssetConfig} from "./src/types/AssetConfig.sol";
import {Errors} from "./src/libraries/Errors.sol";
import {Roles} from "./src/libraries/Roles.sol";

contract AssetRegistry is RoleControl {
    mapping(address asset => AssetConfig config) private _assets;
    mapping(address asset => bool known) private _known;
    address[] private _listed;

    event AssetConfigured(address indexed asset, bool enabled, uint16 ltvBps, uint16 liquidationBps);

    constructor(address admin) RoleControl(admin) {}

    function configure(address asset, bool enabled, uint16 ltvBps, uint16 liquidationBps, uint16 bonusBps)
        external
        onlyRole(Roles.ADMIN)
    {
        if (
            asset == address(0) || ltvBps == 0 || ltvBps > liquidationBps || liquidationBps > 10_000
                || bonusBps > 2_000
        ) {
            revert Errors.InvalidConfiguration();
        }
        if (!_known[asset]) {
            _known[asset] = true;
            _listed.push(asset);
        }
        _assets[asset] = AssetConfig(enabled, ltvBps, liquidationBps, bonusBps);
        emit AssetConfigured(asset, enabled, ltvBps, liquidationBps);
    }

    function configOf(address asset) external view returns (AssetConfig memory) {
        return _assets[asset];
    }

    function assetAt(uint256 index) external view returns (address) {
        return _listed[index];
    }

    function assetCount() external view returns (uint256) {
        return _listed.length;
    }
}
