// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "forge-std/console.sol";

import "./interface/IPriceOracle.sol";

contract JeeTrades {

    event DepositLiquidity(address indexed liquidityProvider, uint amount);
    event DepositCollateral(address indexed liquidityProvider, uint amount);
    event WithdrawLiquidity(address indexed trader, uint amount);
    event PositionOpened(address indexed collateral, address indexed token, address indexed trader, uint256 size, bool isLong);
    event PositionClosed(address indexed collateral, address indexed token, address indexed trader, uint256 size);
    event PositionSizeIncrease(uint indexed id, uint inc);
    event PositionCollateralIncreased(uint indexed id, uint inc);

    using SafeERC20 for IERC20;

    struct PositionStruct {
        address trader;
        address collateral;
        address token;
        uint collateralDeposit;
        uint size;
        uint value;
        bool isLong;
        bool isOpen;
    }

    uint public positionId = 0;

    // store deposits
    mapping(address => uint) public deposits;
    // store user deposits for a given asset
    mapping(address => mapping(address => uint)) public myDeposits;

    // mapping position ID to position
    mapping(uint => PositionStruct) public positions;



    uint8 constant public MAX_LEVERAGE = 20;
    uint constant public LOT_SIZE = 0.01 ether;

    uint public tradingLiquidity = 0;

    address public priceOracle;

    constructor(address _priceOracle) {
        priceOracle = _priceOracle;
    }

    function deposit(address token, uint256 amount) external {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        deposits[token] += amount;
        myDeposits[msg.sender][token] += amount;
        emit DepositLiquidity(msg.sender, amount);
    }

    function withdraw(address token, uint256 amount) external {
        deposits[token] -= amount;
        myDeposits[msg.sender][token] -= amount;
        IERC20(token).safeTransfer(msg.sender, amount);
        emit WithdrawLiquidity(msg.sender, amount);
    }

    function openPosition(address _collateral, address _token, uint _collateralDeposit, uint _size, bool _isLong) external {

        uint price = IPriceOracle(priceOracle).getPrice(_collateral, _token);

        uint amount = price * _size;

        IERC20(_collateral).safeTransferFrom(msg.sender, address(this), _collateralDeposit);

        if (!isBelowLeverage(_collateralDeposit, _size)) revert();

        positions[++positionId] = PositionStruct({
            trader: msg.sender,
            collateral: _collateral,
            token: _token,
            collateralDeposit: _collateralDeposit,
            size: _size,
            value: amount,
            isLong: _isLong,
            isOpen: true
        });
        
        emit PositionOpened(_collateral, _token, msg.sender, _size, true);
    }


    function increasePositionSize(uint id,  uint inc) external {
        PositionStruct storage position = positions[id];
        position.size += inc;
        emit PositionSizeIncrease(id, inc);
    }


    function getPrice(address _token1, address _token2) external view returns(uint) {
        return IPriceOracle(priceOracle).getPrice(_token1, _token2);
    }

    function isBelowLeverage(uint _collateral, uint _size) public pure returns(bool) {
        return (uint(MAX_LEVERAGE) * 1 ether) > ((_size * 1 ether) / _collateral);
    }



}
