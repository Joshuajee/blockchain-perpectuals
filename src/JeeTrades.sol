// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract JeeTrades {

    using SafeERC20 for IERC20;

    // store user deposits for a given asset
    mapping(address => mapping(address => uint)) deposits;

    function deposit(address token, uint256 amount) external {
        IERC20(token).safeTransferFrom();
        deposits[msg.sender][token] += amount;
    }

    function increment() public {
        number++;
    }
}
