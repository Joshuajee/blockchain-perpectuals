# Perpertuals

This is the first challenge given by Owen Thurm, in his Advance Web3 security course, build a Perpertual.

## What is Perpetuals

Perpertuals are essentially just a way for a Trader to bet on the price of a certain index token without actually buying the token, while enabling the Trader to employ leverage.

## Features

- Liquidity Providers can deposit and withdraw liquidity
- A way to get realtime price of the asset being traded
- Traders can open a Perpetual position for BTC, with a given size and Collateral
- Traders can increase size of a Perpetual position
- Traders can not utilize more than a configured percentage of the deposited Liquidity
- Liquity Providers cannot withdraw liquidity that is reserved for positions

## How it works

- Liquidity Provider Deposit an asset into the protocol, this asset acts as liquidity. `deposits(address(USDT)), amount)`
- Trader opens a position with a collateral

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
