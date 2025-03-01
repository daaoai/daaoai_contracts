// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILockerFactory {
    function deploy(
        address token,
        address beneficiary,
        uint256 durationSeconds,
        uint256 tokenId,
        uint256 fees,
        address daoTreasury
    ) external payable returns (address);
}

interface ILocker {
    function initializer(uint256 tokenId) external;

    function extendFundExpiry(uint256 fundExpiry) external;
}

struct ExactInputSingleParams {
    address tokenIn;
    address tokenOut;
    uint24 fee;
    address recipient;
    uint256 amountIn;
    uint256 amountOutMinimum;
    uint160 sqrtPriceLimitX96;
}

interface IWETH is IERC20 {
    /// @notice Deposit ETH and get back WETH in return
    function deposit() external payable;

    /// @notice Withdraw WETH and get back ETH
    /// @param wad The amount of WETH to withdraw (in wei)
    function withdraw(uint256 wad) external;
}

interface ISwapRouter {
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}
