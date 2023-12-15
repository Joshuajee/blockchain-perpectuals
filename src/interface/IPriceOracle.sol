// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IPriceOracle  {
    function getPrice(address _token1, address _token2) external view returns (uint);
}
