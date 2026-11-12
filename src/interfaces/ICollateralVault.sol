// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ICollateralVault {
    function deposit(address account, address asset, uint256 amount) external;
    function withdraw(address account, address asset, uint256 amount, address recipient) external;
    function balanceOf(address account, address asset) external view returns (uint256);
    function seize(address account, address asset, uint256 amount, address recipient) external;
}
