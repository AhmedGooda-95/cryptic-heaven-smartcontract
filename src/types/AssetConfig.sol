// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

struct AssetConfig {
    bool enabled;
    uint16 maxLtvBps;
    uint16 liquidationThresholdBps;
    uint16 liquidationBonusBps;
}
