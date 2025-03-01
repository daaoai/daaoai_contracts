// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {console2} from "forge-std/console2.sol";

import {Script} from "forge-std/Script.sol";
import {DaaoToken} from "../src/DaaoToken.sol"; // Adjust the path based on your project structure
import {Daao} from "../src/Daao.sol"; // Adjust the path based on your project structure

contract WhitelistUser is Script {
    function run() public {
        // Load private key
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address DAO_CONTRACT_ADDRESS = 0x29F07AA75328194C274223F11cffAa329fD1c319;

        Daao daosWorldV1 = Daao(DAO_CONTRACT_ADDRESS);

        bool goalReached = daosWorldV1.goalReached();
        console2.log("Goal reached: ", goalReached);

        // Finalize fundraising
        daosWorldV1.finalizeFundraising(0, 0);

        vm.stopBroadcast();
    }
}
