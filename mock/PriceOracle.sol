// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "forge-std/console.sol";

contract PriceOracle  {

    using Math for uint;

    mapping(address =>  uint) public prices;

    uint constant BASE_PRICE = 1 ether;


    function setPrice (address token, uint amount) external {
        prices[token] = amount;
    }

    function getPrice(address _token1, address _token2) external view returns (uint) {
        return prices[_token1] * BASE_PRICE / prices[_token2];
    }

    /**
     * To return the amount of token1, equal to a given amount of token2
     * @param _token1 address of the token you want to know the price
     * @param _token2 address of the token you have
     * @param amount2 amount of the token you want to supply
     */
    function calculatePrice(address _token1, address _token2, uint amount2) external view returns(uint) {
        // console.log("%d", prices[_token1][_token2]);
        return Math.mulDiv(amount2 * BASE_PRICE, prices[_token1], prices[_token2]);
        // return (amount2 * prices[_token1] * BASE_PRICE / prices[_token2]);
    }   

}
