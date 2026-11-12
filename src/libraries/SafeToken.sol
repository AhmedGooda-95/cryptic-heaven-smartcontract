// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "../interfaces/IERC20.sol";
import {Errors} from "./Errors.sol";

library SafeToken {
    function safeTransfer(IERC20 token, address to, uint256 amount) internal {
        (bool ok, bytes memory result) =
            address(token).call(abi.encodeCall(IERC20.transfer, (to, amount)));
        if (!ok || (result.length != 0 && !abi.decode(result, (bool)))) revert Errors.TransferFailed();
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 amount) internal {
        (bool ok, bytes memory result) =
            address(token).call(abi.encodeCall(IERC20.transferFrom, (from, to, amount)));
        if (!ok || (result.length != 0 && !abi.decode(result, (bool)))) revert Errors.TransferFailed();
    }
}
