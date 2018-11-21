# Function signatures

## Register Issuer

This function locks initial collateral and increases the collateral. The fee can also be update once more collateral is added.

`function lockCollateral(uint fee) payable;`

This function updates the fee an issuer takes.
`function updateFee(uint fee);`

This function withdraws collateral from an issuer. It updates the current amount an issuer is able to issue (affects the registerIssue function).
`function withdrawCollateral(uint collateral);`

Possibly do announanceWithdraw and withdraw in two step protocol.

## Issue
`function registerIssue(address issuer, uint amountBTC, bytes32 addressBTC, address addressETH) payable;`