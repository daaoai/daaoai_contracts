// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {console2} from "forge-std/console2.sol";

import {Script} from "forge-std/Script.sol";
import {DaaoToken} from "../src/DaaoToken.sol"; // Adjust the path based on your project structure
import {Daao} from "../src/Daao.sol"; // Adjust the path based on your project structure
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract WhitelistUser is Script {
    address public constant PAYMENT_TOKEN = 0xDfc7C877a950e49D2610114102175A06C2e3167a;

    function run() public {
        // Load private key
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address DAO_CONTRACT_ADDRESS = 0x29F07AA75328194C274223F11cffAa329fD1c319;

        uint256 CONTRIBUTION_AMOUNT = 10 ether;

        Daao daosWorldV1 = Daao(DAO_CONTRACT_ADDRESS);

        IERC20(PAYMENT_TOKEN).approve(DAO_CONTRACT_ADDRESS, CONTRIBUTION_AMOUNT);
        daosWorldV1.contribute(CONTRIBUTION_AMOUNT);

        vm.stopBroadcast();
    }
}
