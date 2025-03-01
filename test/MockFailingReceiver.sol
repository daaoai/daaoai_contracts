// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MockFailingReceiver {
    function failingFunction() external pure {
        revert("Function failed");
    }
}
