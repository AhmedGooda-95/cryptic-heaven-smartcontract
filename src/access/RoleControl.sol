// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Errors} from "../libraries/Errors.sol";
import {Roles} from "../libraries/Roles.sol";

abstract contract RoleControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER");
    bytes32 public constant CREDIT_MANAGER_ROLE = keccak256("CREDIT_MANAGER");
    bytes32 public constant SETTLER_ROLE = keccak256("SETTLER");
    bytes32 public constant LIQUIDATOR_ROLE = keccak256("LIQUIDATOR");
    bytes32 public constant COMPLIANCE_ROLE = keccak256("COMPLIANCE");
    bytes32 public constant AUTHORIZER_ROLE = keccak256("AUTHORIZER");
    bytes32 public constant TREASURER_ROLE = keccak256("TREASURER");

    mapping(bytes32 role => mapping(address account => bool)) private _roles;

    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    constructor(address admin) {
        if (admin == address(0)) revert Errors.ZeroAddress();
        _grantRole(Roles.ADMIN, admin);
    }

    modifier onlyRole(bytes32 role) {
        if (!_roles[role][msg.sender]) revert Errors.Unauthorized();
        _;
    }

    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role][account];
    }

    function grantRole(bytes32 role, address account) external onlyRole(Roles.ADMIN) {
        if (account == address(0)) revert Errors.ZeroAddress();
        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) external onlyRole(Roles.ADMIN) {
        _roles[role][account] = false;
        emit RoleRevoked(role, account, msg.sender);
    }

    function _grantRole(bytes32 role, address account) internal {
        _roles[role][account] = true;
        emit RoleGranted(role, account, msg.sender);
    }
}
