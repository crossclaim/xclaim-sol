# XCLAIM(BTC,ETH)

** Disclaimer: this project is still under development and not safe to use!**

## Overview
XCLAIM is a framework for achieving trustless and efficient cross-chain exchanges using cryptocurrency-backed assets (CbAs). XCLAIM allows to create assets which are 1:1 backed by existing cryptocurrencies, without requiring trust in a central operator. While this approach is applicable to a wide range of cryptocurrencies, we currently focus on implementing Bitcoin-backed tokens on Ethereum, i.e. <b>XCLAIM(BTC,ETH)</b>.

XCLAIM introduces three main protocols to achieve decentralized, transparent, consistent, atomic, and censorship resistant blockchain interoperability for cryptocurrencies:

+ <b>Issue</b>: Create Bitcoin-backed tokens on Ethereum.
+ <b>Swap</b>: Swap Bitcoin-backed tokens on Ethereum with Ether.
+ <b>Redeem</b>: Burn Bitcoin-backed tokens on Ethereum and receive Bitcoins in return,

The current XCLAIM prototype is compliant with the ERC20 standard. An overview of the protocols is presented below:

![overview of XCLAIM issue, swap and redeem protocols](https://github.com/crossclaim/crossclaim.github.io/blob/master/images/xclaim/xclaim-process.png)

XCLAIM guarantees that Bitcoin-backed tokens can be redeemed for the corresponding amount of Bitcoin, or the equivalent economic value in Ethereum. Thereby, XCLAIM overcomes the limitations of centralized approaches through three primary techniques:
+ <b>Secure audit logs</b>: Logs are constructed to record actions of all users both on Bitcoin and Ethereum.
+ <b>Transaction inclusion proofs</b>: Chain relays are used to prove correct behavior on Bitcoin to the smart contract on Ethereum.
+ <b>Over-collateralization</b>: Incentivize honest behavior following a proof-or-punishment approach. All involved parties must actively prove correct behaviour to the smart contract, e.g. by providing inclusion proofs for Bitcoin transactions.

## Paper
Read more about XCLAIM in our <a href="https://eprint.iacr.org/2018/643.pdf">paper</a> (currently under submission).


## Protocol Summary and Components

A concise overview is **coming soon**. 
For now, please refer to the <a href="https://eprint.iacr.org/2018/643.pdf">paper</a>.


## API 
**Coming soon**. 
For now, please refer to the <a href="https://eprint.iacr.org/2018/643.pdf">paper</a>.

## Installation

Make sure ganache-cli and truffle are installed as global packages. Then, install the required packages with:

```
npm install
```

## Testing

Start ganache:

```
ganache-cli
```

Migrate contracts:

```
truffle migrate
```

Run tests: 

```
truffle test
```
This will also re-run migration scripts. 
