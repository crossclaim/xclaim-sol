# Instructions

## General

Start ganache with enough gas limit:

```
ganache-cli -l 7988288
```

## BTC Relay setup

Deploy BTC Relay from truffle:

```
truffle console
exec scripts/btcrelay.js
```

This will print the deployed BTC Relay address on your console. Copy this address and include it in `scripts/btcrelay-config.js` under network development (and override the current address there).

TODO: make this automatic.


Initialise BTC Relay with blocks from your truffle console:

```
exec scripts/storeHeaders.js
```

## Migrate contracts

From your truffle console:

```
migrate
```

## Test

From your truffle console:

```
test
```

Tests will execute locally and override the gas values in `experiments` for the three different contracts.

## Function signatures

### Register Issuer

This function locks initial collateral and increases the collateral. The fee can also be update once more collateral is added.

`function lockCollateral(uint fee) payable;`

This function updates the fee an issuer takes.
`function updateFee(uint fee);`

This function withdraws collateral from an issuer. It updates the current amount an issuer is able to issue (affects the registerIssue function).
`function withdrawCollateral(uint collateral);`

Possibly do announanceWithdraw and withdraw in two step protocol.

### Issue
`function registerIssue(address issuer, uint amountBTC, bytes32 addressBTC, address addressETH) payable;`