// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "./interfaces/IERC20Minimal.sol";
import {IUniswapV3SwapCallback} from "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract CLPoolRouter is IUniswapV3SwapCallback {
    using SafeERC20 for ERC20;

    address public constant UNISWAP_V3_FACTORY = 0x04625B046C69577EfC40e6c0Bb83CDBAfab5a55F;

    event SwapExecuted(
        address indexed pool,
        address indexed sender,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        int256 amount0Delta,
        int256 amount1Delta,
        uint256 outputAmount
    );

    function getSwapResult(
        address pool,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        uint256 minimumOutputAmount,
        uint256 deadline
    ) external returns (int256 amount0Delta, int256 amount1Delta, uint160 nextSqrtRatio) {
        (amount0Delta, amount1Delta) = IUniswapV3Pool(pool).swap(
            msg.sender, zeroForOne, amountSpecified, sqrtPriceLimitX96, abi.encode(msg.sender)
        );

        (nextSqrtRatio,,,,,,) = IUniswapV3Pool(pool).slot0();
        uint256 outputAmount;
        if (zeroForOne) {
            require(amount1Delta < 0, "Invalid amount1Delta");
            outputAmount = uint256(-amount1Delta);
        } else {
            require(amount0Delta < 0, "Invalid amount0Delta");
            outputAmount = uint256(-amount0Delta);
        }

        require(outputAmount >= minimumOutputAmount, "Output amount is less than minimum output amount");
        require(block.timestamp <= deadline, "Deadline exceeded");

        emit SwapExecuted(
            pool, msg.sender, zeroForOne, amountSpecified, sqrtPriceLimitX96, amount0Delta, amount1Delta, outputAmount
        );
    }

    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external override {
        address token0 = IUniswapV3Pool(msg.sender).token0();
        address token1 = IUniswapV3Pool(msg.sender).token1();
        uint24 fee = IUniswapV3Pool(msg.sender).fee();

        address pool = IUniswapV3Factory(UNISWAP_V3_FACTORY).getPool(token0, token1, fee);
        require(pool == msg.sender, "Invalid pool");

        address sender = abi.decode(data, (address));

        if (amount0Delta > 0) {
            IERC20Minimal(token0).transferFrom(sender, msg.sender, uint256(amount0Delta));
        } else if (amount1Delta > 0) {
            IERC20Minimal(token1).transferFrom(sender, msg.sender, uint256(amount1Delta));
        }
    }
}
