// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Pausable} from "./src/access/Pausable.sol";
import {ReentrancyGuard} from "./src/access/ReentrancyGuard.sol";
import {IERC20} from "./src/interfaces/IERC20.sol";
import {ICollateralVault} from "./src/interfaces/ICollateralVault.sol";
import {AssetRegistry} from "./AssetRegistry.sol";
import {SafeToken} from "./src/libraries/SafeToken.sol";
import {Errors} from "./src/libraries/Errors.sol";
import {Roles} from "./src/libraries/Roles.sol";

contract CollateralVault is Pausable, ReentrancyGuard, ICollateralVault {
    using SafeToken for IERC20;

    AssetRegistry public immutable assets;
    mapping(address account => mapping(address asset => uint256 amount)) private _balances;

    event Deposited(address indexed account, address indexed asset, uint256 amount);
    event Withdrawn(address indexed account, address indexed asset, uint256 amount, address recipient);
    event Seized(address indexed account, address indexed asset, uint256 amount, address recipient);

    constructor(address admin, AssetRegistry assets_) Pausable(admin) {
        if (address(assets_) == address(0)) revert Errors.ZeroAddress();
        assets = assets_;
    }

    function deposit(address account, address asset, uint256 amount) external whenNotPaused nonReentrant {
        if (account == address(0) || amount == 0) revert Errors.ZeroAmount();
        if (!assets.configOf(asset).enabled) revert Errors.UnsupportedAsset();
        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
        _balances[account][asset] += amount;
        emit Deposited(account, asset, amount);
    }

    function withdraw(address account, address asset, uint256 amount, address recipient)
        external
        onlyRole(Roles.CREDIT_MANAGER)
        nonReentrant
    {
        if (recipient == address(0) || amount == 0) revert Errors.ZeroAmount();
        uint256 balance = _balances[account][asset];
        if (amount > balance) revert Errors.InsufficientBalance();
        _balances[account][asset] = balance - amount;
        IERC20(asset).safeTransfer(recipient, amount);
        emit Withdrawn(account, asset, amount, recipient);
    }

    function seize(address account, address asset, uint256 amount, address recipient)
        external
        onlyRole(Roles.LIQUIDATOR)
        nonReentrant
    {
        if (recipient == address(0) || amount == 0) revert Errors.ZeroAmount();
        uint256 balance = _balances[account][asset];
        if (amount > balance) revert Errors.InsufficientBalance();
        _balances[account][asset] = balance - amount;
        IERC20(asset).safeTransfer(recipient, amount);
        emit Seized(account, asset, amount, recipient);
    }

    function balanceOf(address account, address asset) external view returns (uint256) {
        return _balances[account][asset];
    }
}
