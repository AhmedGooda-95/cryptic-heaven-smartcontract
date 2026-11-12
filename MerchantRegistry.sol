// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {RoleControl} from "./src/access/RoleControl.sol";
import {Errors} from "./src/libraries/Errors.sol";
import {Roles} from "./src/libraries/Roles.sol";

contract MerchantRegistry is RoleControl {
    struct Merchant {
        address payout;
        uint32 category;
        bool enabled;
    }

    mapping(address merchant => Merchant) public merchants;
    event MerchantConfigured(address indexed merchant, address payout, uint32 category, bool enabled);

    constructor(address admin) RoleControl(admin) {}

    function configure(address merchant, address payout, uint32 category, bool enabled)
        external
        onlyRole(Roles.ADMIN)
    {
        if (merchant == address(0) || payout == address(0)) revert Errors.ZeroAddress();
        merchants[merchant] = Merchant(payout, category, enabled);
        emit MerchantConfigured(merchant, payout, category, enabled);
    }

    function getMerchant(address merchant) external view returns (Merchant memory) {
        return merchants[merchant];
    }
}
