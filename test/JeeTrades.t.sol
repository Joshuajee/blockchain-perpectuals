// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {JeeTrades} from "../src/JeeTrades.sol";
import {TestUSDC} from "../mock/TestUSDC.sol";
import {PriceOracle} from "../mock/PriceOracle.sol";

contract JeeTradesTest is Test {

    PriceOracle public priceOracle;
    JeeTrades public jeeTrades;
    TestUSDC public USDT;
    TestUSDC public BTC;

    address public user1 = vm.addr(1);
    address public user2 = vm.addr(2);

    function setUp() public {
        priceOracle = new PriceOracle();
        jeeTrades = new JeeTrades(address(priceOracle));
        vm.prank(user1);
        USDT = new TestUSDC();
        vm.prank(user1);
        BTC = new TestUSDC();
    }


    function depositAssets(uint amount) public {
        priceOracle.setPrice(address(USDT), address(BTC), 1000000, 9);
        vm.prank(user1);
        USDT.approve(address(jeeTrades), amount);
        vm.prank(user1);
        jeeTrades.deposit(address(USDT), amount); 
        vm.prank(user1);
        BTC.approve(address(jeeTrades), amount);
        vm.prank(user1);
        jeeTrades.deposit(address(BTC), amount); 
    }

    function depositCollateral(uint amount) public {
        vm.prank(user1);
        USDT.approve(address(jeeTrades), amount);
        vm.prank(user1);
        jeeTrades.deposit(address(USDT), amount); 
        vm.prank(user1);
        BTC.approve(address(jeeTrades), amount);
        vm.prank(user1);
        jeeTrades.deposit(address(BTC), amount); 
    }


    function testFuzz_Deposit(uint amount) public {

        vm.prank(user1);

        USDT.approve(address(jeeTrades), amount);

        vm.prank(user1);

        jeeTrades.deposit(address(USDT), amount); 

        assertEq(jeeTrades.deposits(address(USDT)), amount);

        assertEq(jeeTrades.myDeposits(user1, address(USDT)), amount);

        assertEq(USDT.balanceOf(address(jeeTrades)), amount);
    }

    function testFuzz_Withdraw(uint amount) public {

        testFuzz_Deposit(amount);

        uint currentContractBalance = USDT.balanceOf(address(jeeTrades));

        uint currentUserBalance = USDT.balanceOf(address(user1));

        vm.prank(user1);

        jeeTrades.withdraw(address(USDT), amount); 

        assertEq(USDT.balanceOf(address(jeeTrades)), currentContractBalance - amount);

        assertEq(USDT.balanceOf(user1), currentUserBalance + amount);

    }


    function testFuzz_OpenPosition( uint _size) public {

        uint amount = 10000000 ether;
        uint collateral = 10000 ether;

        vm.assume(_size < 1000 && _size > 0);

        depositAssets(amount);

        uint initBalance = USDT.balanceOf(address(jeeTrades));

        vm.assume(_size < 10);

        vm.prank(user1);

        USDT.approve(address(jeeTrades), collateral);

        assertEq(jeeTrades.positionId(), 0);

        vm.prank(user1);

        jeeTrades.openPosition(address(USDT), address(BTC), collateral, _size, true);

        assertEq(jeeTrades.positionId(), 1);

        assertEq(initBalance + collateral, USDT.balanceOf(address(jeeTrades)));

        (
            address trader, address collateralAddress, address token, 
            uint collateralDeposit, uint size, uint value, 
            bool isLong, bool isOpen
        ) = jeeTrades.positions(1);

        assertEq(trader, user1);
        assertEq(address(USDT), collateralAddress);
        assertEq(token, address(BTC));
        assertEq(collateralDeposit, collateral);
        assertEq(size, _size);
        //assertEq(value, pr);
        assertEq(isLong, true);
        assertEq(isOpen, true);


        console.log(value);
    }



    function testFuzz_IncreasePositionSize(uint _size, uint inc) public {

        vm.assume(inc < 1000000);

        testFuzz_OpenPosition(_size);

        jeeTrades.increasePositionSize(1, inc);

        assertEq(jeeTrades.positionId(), 1);


        (
            address trader, address collateralAddress, address token, , uint size, uint value, 
            bool isLong, bool isOpen
        ) = jeeTrades.positions(1);

        assertEq(trader, user1);
        assertEq(address(USDT), collateralAddress);
        assertEq(token, address(BTC));
        //assertEq(size + inc, _size);
        //assertEq(value, pr);
        assertEq(isLong, true);
        assertEq(isOpen, true);


    }

}
