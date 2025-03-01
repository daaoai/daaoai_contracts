// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {console2} from "forge-std/console2.sol";
import {Script} from "forge-std/Script.sol";
import {CLPoolRouter} from "../src/CLPoolRouter.sol";
import {Quoter} from "../src/Quoter.sol";

contract DeployCLPoolRouter is Script {
    function run() public {
        vm.startBroadcast();

        CLPoolRouter swapTest = new CLPoolRouter();
        Quoter quoter = new Quoter();

        console2.log("CLPoolRouter is ", address(swapTest));
        console2.log("Quoter is ", address(quoter));

        vm.stopBroadcast();
    }
}
