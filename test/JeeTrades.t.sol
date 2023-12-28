// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {JeeTrades} from "../src/JeeTrades.sol";
import {TokenizedVault} from "../src/TokenizedVault.sol";
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
        priceOracle.setPrice(address(USDT), 50000);
        priceOracle.setPrice(address(BTC), 1);
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

        TokenizedVault vault = jeeTrades.vaults(address(USDT));

        assertEq(jeeTrades.deposits(address(USDT)), amount);

        assertEq(jeeTrades.myDeposits(user1, address(USDT)), amount);

        assertEq(USDT.balanceOf(address(vault)), amount);

        assertEq(vault.balanceOf(address(user1)), amount);
    }

    function testFuzz_Withdraw(uint amount) public {

        vm.assume(amount > 1 ether && amount < 100 ether);

        testFuzz_Deposit(amount);

        uint currentContractBalance = USDT.balanceOf(address(jeeTrades.vaults(address(USDT))));

        uint currentUserBalance = USDT.balanceOf(address(user1));

        vm.prank(user1);

        jeeTrades.withdraw(address(USDT), amount); 

        assertEq(USDT.balanceOf(address(jeeTrades)), currentContractBalance - amount);

        assertEq(USDT.balanceOf(user1), currentUserBalance + amount);

    }


    function testFuzz_OpenPosition(uint _size, bool _type) public {

        uint amount = 10000000 ether;
        uint collateral = 10000 ether;

        vm.assume(_size > collateral * 10 && _size < collateral * 20);

        depositAssets(amount);

        uint initBalance = USDT.balanceOf(address(jeeTrades));

        vm.prank(user1);

        USDT.approve(address(jeeTrades), collateral);

        assertEq(jeeTrades.positionId(), 0);

        vm.prank(user1);

        jeeTrades.openPosition(address(USDT), address(BTC), collateral, _size, _type);

        assertEq(jeeTrades.positionId(), 1);

        assertEq(initBalance + collateral, USDT.balanceOf(address(jeeTrades)));

        if (_type) {
            assertEq(jeeTrades.longInterest(address(USDT)), _size);
        } else {
            assertEq(jeeTrades.shortInterest(address(USDT)), _size);
        }

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
        assertEq(isLong, _type);
        assertEq(isOpen, true);

    }

    function testFuzz_IncreasePositionSize(uint _size, uint inc, bool _isLong) public {

        vm.assume(inc < 1000000);
        vm.assume(_size > 1);

        testFuzz_OpenPosition(_size, _isLong);

        jeeTrades.increasePositionSize(1, inc);

        assertEq(jeeTrades.positionId(), 1);

        (
            address trader, address collateralAddress, address token, , uint size, , 
            bool isLong, bool isOpen
        ) = jeeTrades.positions(1);

        (bool utilized, uint total, uint deposited) = jeeTrades.maxUtilizationPercentage(collateralAddress);

        console.log(utilized);

        console.log("%d",total);

        console.log("%d", deposited);


        assertEq(trader, user1);
        assertEq(address(USDT), collateralAddress);
        assertEq(token, address(BTC));
        assertEq(size, _size + inc);
        //assertEq(value, pr);
        assertEq(isLong, _isLong);
        assertEq(isOpen, true);

    }


    function testFuzz_Pnl_long(uint _size) public {
        
        testFuzz_OpenPosition(_size, true);

        (uint initialPnL, ) = jeeTrades.positionPnL(1);

        assertEq(initialPnL, 0);

        priceOracle.setPrice(address(USDT), 100000);

        (uint currentPnL, bool isProfit) = jeeTrades.positionPnL(1);
        
        assert(isProfit);
        
        assertEq(currentPnL, _size);

    }

    function testFuzz_Pnl_total(uint _size) public {
        
        testFuzz_OpenPosition(_size, true);

        address collateral = address(USDT);

        address asset = address(BTC);

        (uint initialPnL, ) = jeeTrades.totalPnL(collateral, asset);

        assertEq(initialPnL, 0);

        priceOracle.setPrice(address(USDT), 100000);

        (uint currentPnL, bool isProfit) = jeeTrades.totalPnL(collateral, asset);
        
        assert(isProfit);
        
        assertEq(currentPnL, _size);

    }

}
