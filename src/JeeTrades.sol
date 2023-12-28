// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./TokenizedVault.sol";
import "forge-std/console.sol";

import "./interface/IPriceOracle.sol";

contract JeeTrades {

    event DepositLiquidity(address indexed liquidityProvider, uint amount);
    event DepositCollateral(address indexed liquidityProvider, uint amount);
    event WithdrawLiquidity(address indexed asset, address indexed trader, uint amount);
    event PositionOpened(address indexed collateral, address indexed asset, address indexed trader, uint256 size, bool isLong);
    event PositionClosed(address indexed collateral, address indexed asset, address indexed trader, uint256 size);
    event PositionSizeIncrease(uint indexed id, uint inc);
    event PositionCollateralIncreased(uint indexed id, uint inc);

    using SafeERC20 for IERC20;

    struct PositionStruct {
        address trader;
        address collateral;
        address asset;
        uint collateralDeposit;
        uint size;
        uint value;
        bool isLong;
        bool isOpen;
    }

    uint constant BASE_PRICE = 1 ether;

    uint constant public MAX_UTILIZATION_PERCENTAGE = 50;

    uint public positionId = 0;

    // vaults deposits
    mapping(address => TokenizedVault) public vaults;

    // store deposits
    mapping(address => uint) public deposits;
    // store user deposits for a given asset
    mapping(address => mapping(address => uint)) public myDeposits;

    //  mapping of assets to long Interest
    mapping(address =>  uint) public longInterest;

    //  mapping of assets to long Interest
    mapping(address =>  uint) public longInterestInTokens;

    //  mapping of assets to short Interest
    mapping(address => uint) public shortInterest;

    //  mapping of assets to short Interest
    mapping(address => uint) public shortInterestInTokens;

    // mapping position ID to position
    mapping(uint => PositionStruct) public positions;



    uint8 constant public MAX_LEVERAGE = 20;
    uint constant public LOT_SIZE = 0.01 ether;

    uint public tradingLiquidity = 0;

    address public priceOracle;

    constructor(address _priceOracle) {
        priceOracle = _priceOracle;
    }

    function deposit(address asset, uint256 amount) external {
        TokenizedVault vault = getVault(asset);
        address liquidityProvider = msg.sender;
        IERC20(asset).safeTransferFrom(liquidityProvider, address(this), amount);
        IERC20(asset).approve(address(vault), amount);
        vault.deposit(amount, liquidityProvider) ;
        deposits[asset] += amount;
        myDeposits[liquidityProvider][asset] += amount;
        emit DepositLiquidity(liquidityProvider, amount);
    }

    function withdraw(address asset, uint256 amount) external {
        address liquidityProvider = msg.sender;
        vaults[asset].withdraw(amount, liquidityProvider, liquidityProvider); 
        deposits[asset] -= amount;
        myDeposits[liquidityProvider][asset] -= amount;
        emit WithdrawLiquidity(asset, liquidityProvider, amount);
    }

    function openPosition(address _collateral, address _asset, uint _collateralDeposit, uint _size, bool _isLong) external {

        uint amount = IPriceOracle(priceOracle).calculatePrice(_asset, _collateral, _size);

        IERC20(_collateral).safeTransferFrom(msg.sender, address(this), _collateralDeposit);

        if (!isBelowLeverage(_collateralDeposit, _size)) revert("Deposit is below leverage");

        positions[++positionId] = PositionStruct({
            trader: msg.sender,
            collateral: _collateral,
            asset: _asset,
            collateralDeposit: _collateralDeposit,
            size: _size,
            value: amount,
            isLong: _isLong,
            isOpen: true
        });

        _updatePositions(_collateral, _size, amount, _isLong);

        emit PositionOpened(_collateral, _asset, msg.sender, _size, true);
    }


    function increasePositionSize(uint id,  uint inc) external {
        PositionStruct storage position = positions[id];
        position.size += inc;
        position.value += IPriceOracle(priceOracle).calculatePrice(position.asset, position.collateral, inc);
        _updatePositions(position.collateral, position.size, position.value, position.isLong);
        emit PositionSizeIncrease(id, inc);
    }


    function getPrice(address _asset1, address _asset2) external view returns(uint) {
        return IPriceOracle(priceOracle).getPrice(_asset1, _asset2);
    }

    function isBelowLeverage(uint _collateral, uint _size) public pure returns(bool) {
        return (uint(MAX_LEVERAGE) * 1 ether) > ((_size * 1 ether) / _collateral);
    }

    function getVault(address asset) private returns(TokenizedVault vault) {
        vault = vaults[asset];
        if (address(vault) == address(0)) {
            string memory _name = "JT-"; 
            string memory _symbol = "JT-";
            vault = new TokenizedVault(IERC20(asset), _name, _symbol);
            vaults[asset] = vault;
        }
    }

    function positionPnL(uint _positionId) public view returns(uint pnl, bool isProfit) {
        PositionStruct memory position = positions[_positionId]; 
        uint currentValue =  IPriceOracle(priceOracle).calculatePrice(position.collateral, position.asset, position.value);
        uint borrowedAmount = position.size * BASE_PRICE ** 2; //position.size * position.value;
        if (currentValue >= borrowedAmount) {
            pnl = currentValue - borrowedAmount;
            if (position.isLong) {
                isProfit = true;
            } else {
                isProfit = false;
            }
        } else {
            pnl = borrowedAmount - currentValue;
            if (position.isLong) {
                isProfit = false;
            } else {
                isProfit = true;
            }
        }

        pnl /= BASE_PRICE ** 2; 
    }

    function totalPnL(address collateral, address asset) public view returns(uint pnl, bool isProfit) {
        uint _longInterestInTokens = longInterestInTokens[collateral];
        uint _shortInterestInTokens = shortInterestInTokens[collateral];
        uint currentValueLong = IPriceOracle(priceOracle).calculatePrice(collateral, asset, _longInterestInTokens);
        uint currentValueShort = IPriceOracle(priceOracle).calculatePrice(collateral, asset, _shortInterestInTokens);
        
        (uint longProfit, bool isProfitLong) = getPnL(currentValueLong, longInterest[collateral], true);
        (uint shortProfit, bool isProfitShort) = getPnL(currentValueShort, shortInterest[collateral], false);

        if (isProfitLong && isProfitShort) {
            pnl = longProfit + shortProfit;
            isProfit = true;
        // } else if (isProfitLong) {
        //     if (longProfit > shortProfit) {
        //         pnl = longProfit - shortProfit;
        //         isProfit = true;
        //     } else {
        //         pnl = shortProfit - longProfit;
        //         isProfit = false;
        //     }
        } else {
            if (longProfit > shortProfit) {
                pnl = longProfit - shortProfit;
                isProfit = true;
            } else {
                pnl = shortProfit - longProfit;
                isProfit = false;
            }
        }

    }

    function maxUtilizationPercentage(address asset) public view returns(bool, uint, uint) {
        uint totalOpenInterest = shortInterest[asset] + longInterest[asset];
        uint maxAllowed = deposits[asset] * MAX_UTILIZATION_PERCENTAGE;
        return (totalOpenInterest < maxAllowed, totalOpenInterest, maxAllowed);
    }


    function getPnL(uint currentValue, uint _borrowedAmount, bool isLong) public pure returns(uint pnl, bool isProfit) {
        uint borrowedAmount = _borrowedAmount * BASE_PRICE ** 2;
        if (currentValue >= borrowedAmount) {
            pnl = currentValue - borrowedAmount;
            if (isLong) {
                isProfit = true;
            } else {
                isProfit = false;
            }
        } else {
            pnl = borrowedAmount - currentValue;
            if (isLong) {
                isProfit = false;
            } else {
                isProfit = true;
            }
        }
        pnl /= BASE_PRICE ** 2; 
    }

    function _updatePositions(address asset, uint _size, uint _amount, bool _isLong) internal {

        if (_isLong) {
            longInterest[asset] += _size;
            longInterestInTokens[asset] += _amount;
        }   else {
            shortInterest[asset] += _size;
            shortInterestInTokens[asset] += _amount;
        }
        
        (bool canOpen, ,) = maxUtilizationPercentage(asset);

        if (!canOpen) revert ("Make not open this position now");

    }


}

