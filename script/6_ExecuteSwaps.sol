// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {CLPoolRouter} from "../src/CLPoolRouter.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployCLPoolRouter is Script {
    address public constant MODE_TOKEN_ADDRESS = 0xDfc7C877a950e49D2610114102175A06C2e3167a;
    function run() public {
        vm.startBroadcast();

        address pool = 0x6Ffc554157E44699641B47EE279c9BbB8AaAb4e5;

        address DAO = IUniswapV3Pool(pool).token0() == MODE_TOKEN_ADDRESS ? IUniswapV3Pool(pool).token1() : IUniswapV3Pool(pool).token0();

        CLPoolRouter swapTest = CLPoolRouter(0xC3a15f812901205Fc4406Cd0dC08Fe266bF45a1E);

        int256 modeAmount = 1e16;
        int256 daoAmount = 0;
        bool isZeroForOne = true;
        
        uint160 sqrtPrice = isZeroForOne ? 4295128750 : 1461446703485210103287273052203988822378723970340;

        if(daoAmount > 0){
            IERC20(DAO).approve(address(swapTest), uint256(daoAmount));
            swapTest.getSwapResult(pool, isZeroForOne, daoAmount, sqrtPrice,0,block.timestamp + 300);
        }

        if(modeAmount > 0){
            IERC20(MODE_TOKEN_ADDRESS).approve(address(swapTest), uint256(modeAmount));
            swapTest.getSwapResult(pool, isZeroForOne, modeAmount, sqrtPrice,0,block.timestamp + 300);
        }

        vm.stopBroadcast();
    }
}

// 4295128750 - if true
// 1461446703485210103287273052203988822378723970340