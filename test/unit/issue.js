/**
 * Copyright (C) 2019 Alexei Zamyatin and Dominik Harz
 * 
 * This file is part of XCLAIM.
 * 
 * XCLAIM is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * XCLAIM is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with XCLAIM.  If not, see <http://www.gnu.org/licenses/>.
 */

const truffleAssert = require('truffle-assertions');

const XCLAIM = artifacts.require("./XCLAIM.sol");

contract('Issue: unit tests', async (accounts) => {
    /* For testing and experiments the following roles apply: */
    const vault = accounts[0];
    const relay = accounts[1];
    const alice = accounts[2];
    const bob = accounts[3];
    const oracle = accounts[10];

    const amount = 1;
    const collateral_vault = "0.01";
    const collateral_user = "1";

    let vault_collateral = web3.utils.toWei(collateral_vault, "ether");
    let user_collateral = web3.utils.toWei(collateral_user, "wei");

    const btc_address_vault = web3.utils.hexToBytes("0x02a751dc8c10e35fed2c6eddc2575c9af2c71d23");
    const btc_address_bob = web3.utils.hexToBytes("0x69f374b39af4aa342997e0bdff3b3b297a85883c");
    const btc_tx = web3.utils.hexToBytes("0x3a7bdf6d01f068841a99cce22852698df8428d07c68a32d867b112a4b24c8fe0");

    beforeEach('setup contract', async () => {
        btc_erc = await XCLAIM.deployed();
    });

    it("Register vault", async () => {

        // check if authorize event fired
        let authorize_tx = await btc_erc.registerVault(vault, {
            from: vault,
            value: vault_collateral
        });
        truffleAssert.eventEmitted(authorize_tx, "RegisterVault");
    })
    
    it("registerIssue: too little collateral by Alice", async () => {
        var issue_amount = amount * 10;
        await truffleAssert.reverts(
            btc_erc.registerIssue(alice, issue_amount, vault, btc_address_vault, {
                from: alice,
                value: user_collateral,
            }),
            "Collateral too small"
        )
    })

})