var helpers = require('./helpers');
var eventFired = helpers.eventFired;

const ERCXXX_BTCRelay = artifacts.require("./impl/ERCXXX_BTCRelay.sol");
// const BTCRelay = artifacts.require("./BTCRelay/BTCRelay.sol");

contract('ERCXXX_BTCRelay', async (accounts) => {
    /* For testing and experiments the following roles apply: */
    const issuer = accounts[0];
    const relayer = accounts[1];
    const alice = accounts[2];
    const bob = accounts[3];

    const eth_amount = 0.01;
    let amount = web3.toWei(eth_amount, "ether");
    const collateral = 0.01;
    // const gas_limit = 7988288;
    const btc_tx = "3a7bdf6d01f068841a99cce22852698df8428d07c68a32d867b112a4b24c8fe0";

    // experiment related vars
    var issue_success_col_gas = 0;
    var issue_success_col_txs = 0;
    
    var redeem_success_txs = 0;
    var redeem_success_gas = 0;

    it('setup contract', async function () {
        // btc_relay = await BTCRelay.deployed();
        btc_erc = await ERCXXX_BTCRelay.deployed();

        // #### SETUP #####
        // check if authorize event fired
        let success_authorize_tx = await btc_erc.authorizeIssuer(issuer, { from: issuer, value: web3.toWei(collateral, "ether") });
        eventFired(success_authorize_tx, "AuthorizedIssuer");
    });

    it("Alice issue collateralized BTC-ERC", async () => {
        let balance_alice;
        // #### COLL. ISSUE #####
        // check if issue event is fired
        let issue_register_col_tx = await btc_erc.registerIssue(amount, { from: alice, value: amount });
        eventFired(issue_register_col_tx, "RegisterIssue");
        issue_success_col_gas += issue_register_col_tx.receipt.gasUsed;
        issue_success_col_txs += 1;

        let issue_col_tx = await btc_erc.issueCol(alice, amount, btc_tx, { from: relayer});
        eventFired(issue_col_tx, "Issue");
        issue_success_col_gas += issue_col_tx.receipt.gasUsed;
        issue_success_col_txs += 1;

        // check if Alice's balance is updated
        balance_alice = await btc_erc.balanceOf.call(alice);
        balance_alice = balance_alice.toNumber();
        assert.equal(balance_alice, amount, "SUCCESS COL: Alice balance should be 0.01");

    });

    it("Redeem BTC-ERC from Bob", async () => {
        let balance_bob;

        // #### COLL. ISSUE #####
        // Fund Bob with BTC-ERC
        // check if issue event is fired
        let issue_register_col_tx = await btc_erc.registerIssue(amount, { from: bob, value: amount });
        eventFired(issue_register_col_tx, "RegisterIssue");

        let issue_col_tx = await btc_erc.issueCol(bob, amount, btc_tx, { from: relayer});
        eventFired(issue_col_tx, "Issue");

        // check if Bob's balance is updated
        balance_bob = await btc_erc.balanceOf.call(alice);
        balance_bob = balance_bob.toNumber();
        assert.equal(balance_bob, amount, "SUCCESS COL: Bob balance should be 0.01");

        // #### REDEEM #####
        // check if redeem event fired
        let redeem_tx = await btc_erc.redeem(bob, amount, btc_tx, { from: relayer });
        eventFired(redeem_tx, "Redeem");
        redeem_success_gas += redeem_tx.receipt.gasUsed;
        redeem_success_txs += 1;

        /* Get redeem id*/
        var redeemId;
        for (var i = 0; i < redeem_tx.logs.length; i++) {
            var log = redeem_tx.logs[i];
            if (log.event == "Redeem") {
                // We found the event!
                redeemId = log.args.id.toNumber();
            }
        }

        // check if redeem succeeded
        let redeem_success_tx = await btc_erc.redeemConfirm(bob, redeemId, btc_tx, { from: bob });
        eventFired(redeem_success_tx, "RedeemSuccess");
        redeem_success_gas += redeem_success_tx.receipt.gasUsed;
        redeem_success_txs += 1;
    });
})
