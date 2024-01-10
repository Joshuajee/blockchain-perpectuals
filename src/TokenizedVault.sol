// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "forge-std/console.sol";


interface IJeeTrades {
    function totalLPValue(address collateral) external view returns(uint);
    function maxUtilizationPercentage(address asset) external view returns(bool, uint, uint);
    function maxAvailableForWithdraw(address asset) external view returns(uint);
}

contract TokenizedVault is ERC4626, Ownable {

    constructor(IERC20 _asset, string memory _name, string memory _symbol) ERC4626(_asset) ERC20(_name, _symbol) Ownable(msg.sender) { }

    function deposit(uint256 assets, address receiver) public override onlyOwner returns (uint256) {
        return super.deposit(assets, receiver);
    }

    function withdraw(uint256 assets, address receiver, address _owner) public override onlyOwner returns (uint256 result) {
        return super.withdraw(assets, receiver, _owner);
    }

    function redeem(uint256 shares, address receiver, address owner) public override onlyOwner returns (uint256) {
        return super.redeem(shares, receiver, owner);
    }

    function maxWithdraw(address owner) public view override returns (uint256) {
        return super.maxWithdraw(owner);
    }

    function maxRedeem(address owner) public view override returns (uint256) {
        return super.maxRedeem(owner);
    }



    function _withdraw(
        address caller,
        address receiver,
        address _owner,
        uint256 assets,
        uint256 shares
    ) internal override {
        _burn(_owner, shares);
        SafeERC20.safeTransfer(IERC20(asset()), receiver, assets);
        uint maxAvailableForWithdraw = IJeeTrades(owner()).maxAvailableForWithdraw(asset());
        if (totalAssets() - assets < maxAvailableForWithdraw) revert("Cannot Remove Liquidity Reserved For Positions");
        console.log("%d:%d", totalAssets(), maxAvailableForWithdraw);
        emit Withdraw(caller, receiver, _owner, assets, shares);
    }

    function totalAssets() public view override returns (uint) {
        return IJeeTrades(owner()).totalLPValue(asset());
    }

}
