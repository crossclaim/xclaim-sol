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
var helpers = require('../helpers');
var eventFired = helpers.eventFired;

const XCLAIM = artifacts.require("./XCLAIM.sol");


contract('Setup XCLAIM contract', async (accounts) => {
    /* For testing and experiments the following roles apply: */
    const vault = accounts[0];
    const relay = accounts[1];
    const alice = accounts[2];
    const bob = accounts[3];
    const oracle = accounts[10];

    const amount = 1;
    const collateral = "0.01";
    const collateral_user = "0.00000001";

    let user_collateral = web3.utils.toWei(collateral_user, "ether");

    const btc_tx = web3.utils.hexToBytes("0x3a7bdf6d01f068841a99cce22852698df8428d07c68a32d867b112a4b24c8fe0");

    beforeEach('setup contract', async function () {
        btc_erc = await XCLAIM.deployed();
    });

    it("Adjust BTC/ETH conversion rate", async function () {
        const new_conversion_rate = "3";

        let conversion_rate = await btc_erc.getConversionRate.call({from: oracle});
        await btc_erc.setConversionRate(new_conversion_rate);
        assert.notEqual(conversion_rate,new_conversion_rate, "Did not update the conversion rate");
        
        let updated_conversion_rate = await btc_erc.getConversionRate.call({
            from: oracle
        });
        assert.equal(updated_conversion_rate,new_conversion_rate, "Updated the conversion rate to wrong value");
    })

    it("Set conversion rate to 0 not possible", async function () {
        const new_conversion_rate = "0";

        await truffleAssert.reverts(
            btc_erc.setConversionRate(new_conversion_rate),
            "Set rate greater than 0"
        );
    })

    it("Verify that initillay no vault is registered", async function () {
        await truffleAssert.reverts(
            btc_erc.getVaults.call(),
            "No vault registered"
        );
    })

    it("Register vault", async () => {
        await truffleAssert.reverts(
            btc_erc.getVaults.call(),
            "No vault registered"
        );
        // check if authorize event fired
        let authorize_tx = await btc_erc.registerVault(vault, {
            from: vault,
            value: web3.utils.toWei(collateral, "ether")
        });
        truffleAssert.eventEmitted(authorize_tx, "RegisterVault");

        let vaults = await btc_erc.getVaults.call();
        assert.equal(vaults[0], vault, "did not make correct vault the vault");
    })
})