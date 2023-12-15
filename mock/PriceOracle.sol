// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract PriceOracle  {

    mapping(address => mapping(address => uint)) public prices;

    uint constant BASE_PRICE = 1 ether;


    function setPrice (address _token1, address _token2, uint _amount1, uint _amount2) external {
        prices[_token1][_token2] = _amount1 * BASE_PRICE / _amount2;
        prices[_token2][_token1] = _amount2 * BASE_PRICE / _amount1;
    }

    function getPrice(address _token1, address _token2) external view returns (uint) {
        return prices[_token1][_token2];
    }

}
