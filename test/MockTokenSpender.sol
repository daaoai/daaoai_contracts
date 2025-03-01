// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockTokenSpender {
    bool public tokenSpent;

    function spendTokens(address token, uint256 amount) external {
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        tokenSpent = true;
    }
}
