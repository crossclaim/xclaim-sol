var helpers = require('./helpers');
var eventFired = helpers.eventFired;
var convertToUsd = helpers.convertToUsd;

const XCLAIM = artifacts.require("./XCLAIM.sol");


contract('XCLAIM', async (accounts) => {
    /* For testing and experiments the following roles apply: */
    const issuer = accounts[0];
    const relayer = accounts[1];
    const collateral = 0.01;
    const alice = accounts[2];
    const bob = accounts[3];
    const carol = accounts[4];
    const eve = accounts[5];
    const btc_tx = "3a7bdf6d01f068841a99cce22852698df8428d07c68a32d867b112a4b24c8fe0";

    // gas limit
    const gas_limit = 7988288;

    beforeEach('setup contract', async function () {
        // btc_relay = await BTCRelay.deployed();
        btc_erc = await XCLAIM.deployed();
    });

    it("Setup", async () => {
        // #### SETUP #####
        // check if authorize event fired
        let authorize_tx = await btc_erc.authorizeIssuer(issuer, { from: issuer, value: web3.toWei(collateral, "ether") });
        eventFired(authorize_tx, "AuthorizedIssuer");
    })

    it("Experiment success", async () => {
        let balance_alice, balance_bob, balance_carol;
        let amount = 1;
        let user_collateral = web3.toWei(0.00000001, "ether")

        // #### COLL. ISSUE #####
        // check if issue event is fired
        let issue_register_col_tx = await btc_erc.registerIssue(amount, { from: alice, value: user_collateral, gas: gas_limit });
        eventFired(issue_register_col_tx, "RegisterIssue");
        // issue_success_col_gas += issue_register_col_tx.receipt.gasUsed;
        // issue_success_col_txs += 1;

        let issue_col_tx = await btc_erc.issueCol(alice, amount, btc_tx, { from: alice, gas: gas_limit });
        eventFired(issue_col_tx, "Issue");
        // issue_success_col_gas += issue_col_tx.receipt.gasUsed;
        // issue_success_col_txs += 1;

        // check if Alice's balance is updated
        balance_alice = await btc_erc.balanceOf.call(alice);
        balance_alice = balance_alice.toNumber();
        assert.equal(balance_alice, amount, "SUCCESS COL: Alice balance should be 1");

        // #### TRANSFER #####
        let transfer_one = await btc_erc.transfer(bob, 1, { from: alice });
        eventFired(transfer_one, "Transfer");
        // transfer_success_gas = transfer_one.receipt.gasUsed;
        // transfer_success_txs = 1;
        
        let transfer_two = await btc_erc.transfer(alice, 1, { from: bob });
        eventFired(transfer_two, "Transfer");

        // #### TRADE #####
        // Offer exchange of 1 token for 100 wei
        let offer_tx = await btc_erc.offerTrade(1, 100, bob, { from: alice });
        // Check event is fired
        eventFired(offer_tx, "NewTradeOffer");
        // trade_success_gas += offer_tx.receipt.gasUsed;
        // trade_success_txs += 1;
        /* Get offer id*/
        var offerId = 0;
        for (var i = 0; i < offer_tx.logs.length; i++) {
            var log = offer_tx.logs[i];
            if (log.event == "NewTradeOffer") {
                // We found the event!
                offerId = log.args.id.toString();
            }
        }
        // Complete the transfer
        let trade_tx = await btc_erc.acceptTrade(offerId, { from: bob, value: 100 });
        // Check event is fired
        eventFired(trade_tx, "Trade");
        // trade_success_gas += trade_tx.receipt.gasUsed;
        // trade_success_txs += 1;

        // check if balances are updated
        balance_alice = await btc_erc.balanceOf.call(alice);
        balance_alice = balance_alice.toNumber();
        balance_bob = await btc_erc.balanceOf.call(bob);
        balance_bob = balance_bob.toNumber();

        assert.equal(balance_alice, 0, "Alice balance should be 0");
        assert.equal(balance_bob, amount, "Bob balance should be 1");

        // #### REDEEM #####
        // check if redeem event fired
        let redeem_tx = await btc_erc.redeem(bob, amount, btc_tx, { from: relayer });
        eventFired(redeem_tx, "Redeem");
        // redeem_success_gas += redeem_tx.receipt.gasUsed;
        // redeem_success_txs += 1;

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
        let redeem_success_tx = await btc_erc.redeemConfirm(bob, redeemId, btc_tx, { from: bob, gas: gas_limit});
        eventFired(redeem_success_tx, "RedeemSuccess");
        // redeem_success_gas += redeem_success_tx.receipt.gasUsed;
        // redeem_success_txs += 1;

        // #### REPLACE #####
        // request the replace
        let request_replace_success_tx = await btc_erc.requestReplace({ from: issuer });
        eventFired(request_replace_success_tx, "RequestReplace");
        // replace_success_gas += request_replace_success_tx.receipt.gasUsed;
        // replace_success_txs += 1;

        // lock collateral
        let lock_col_success_tx = await btc_erc.lockCol({ from: eve, value: web3.toWei(collateral, "ether") });
        eventFired(lock_col_success_tx, "LockReplace");
        // replace_success_gas += lock_col_success_tx.receipt.gasUsed;
        // replace_success_txs += 1;

        // replace the issuer
        let replace_success_tx = await btc_erc.replace(btc_tx, { from: issuer, gas: gas_limit });
        eventFired(replace_success_tx, "Replace");
        // replace_success_gas += replace_success_tx.receipt.gasUsed;
        // replace_success_txs += 1;

        var current_issuer = await btc_erc.issuer.call();
        assert.equal(current_issuer, eve, "SUCCESS: Did make Eve the issuer")
    })

    it("Experiment fail", async () => {
        let balance_alice, balance_bob, balance_carol;
        let amount = 1;

        // #### COLL. ISSUE #####
        // check if issue event is fired
        let fail_issue_register_col_tx = await btc_erc.registerIssue(amount, { from: alice, value: web3.toWei(amount, "ether") });
        eventFired(fail_issue_register_col_tx, "RegisterIssue");
        // issue_fail_col_gas += fail_issue_register_col_tx.receipt.gasUsed;
        // issue_fail_col_txs += 1;

        let fail_issue_col_tx = await btc_erc.issueCol(alice, amount, "", { from: relayer });
        eventFired(fail_issue_col_tx, "AbortIssue");
        // issue_fail_col_gas += fail_issue_col_tx.receipt.gasUsed;
        // issue_fail_col_txs += 1;

        // check if Alice's balance is updated
        balance_alice = await btc_erc.balanceOf.call(alice);
        balance_alice = balance_alice.toNumber();
        assert.equal(balance_alice, 0, "Alice balance should be 0");

        // #### TRADE #####
        let fail2_issue_register_col_tx = await btc_erc.registerIssue(amount, { from: alice, value: web3.toWei(amount, "ether") });
        eventFired(fail2_issue_register_col_tx, "RegisterIssue");


        let fail2_issue_col_tx = await btc_erc.issueCol(alice, amount, btc_tx, { from: relayer });
        eventFired(fail2_issue_col_tx, "Issue");

        // Offer exchange of 1 token for 100 wei
        let fail_offer_tx = await btc_erc.offerTrade(1, 100, bob, { from: alice });
        // Check event is fired
        eventFired(fail_offer_tx, "NewTradeOffer");
        // trade_fail_gas += fail_offer_tx.receipt.gasUsed;
        // trade_fail_txs += 1;

        // check if balances are updated
        balance_alice = await btc_erc.balanceOf.call(alice);
        balance_alice = balance_alice.toNumber();
        balance_bob = await btc_erc.balanceOf.call(bob);
        balance_bob = balance_bob.toNumber();
        balance_carol = await btc_erc.balanceOf.call(carol);
        balance_carol = balance_carol.toNumber();

        assert.equal(balance_alice, 0, "FAIL: Alice balance should be 0");
        assert.equal(balance_bob, 0, "Bob balance should be 0");
        assert.equal(balance_carol, init_balance_carol, "Carol balance should be 0");

        // #### REDEEM #####
        // check if redeem event fired
        let fail3_issue_register_col_tx = await btc_erc.registerIssue(amount, { from: alice, value: web3.toWei(amount, "ether") });
        eventFired(fail3_issue_register_col_tx, "RegisterIssue");


        let fail3_issue_col_tx = await btc_erc.issueCol(alice, amount, btc_tx, { from: relayer });
        eventFired(fail3_issue_col_tx, "Issue");

        let fail_redeem_tx = await btc_erc.redeem(alice, amount, btc_tx, { from: relayer });
        eventFired(fail_redeem_tx, "Redeem");
        // redeem_fail_gas += fail_redeem_tx.receipt.gasUsed;
        // redeem_fail_txs += 1;

        /* Get redeem id*/
        var redeemId;
        for (var i = 0; i < fail_redeem_tx.logs.length; i++) {
            var log = fail_redeem_tx.logs[i];
            if (log.event == "Redeem") {
                // We found the event!
                redeemId = log.args.id.toNumber();
            }
        }

        // wait for timeout
        await new Promise(resolve => setTimeout(resolve, 2000));

        // fail redeem
        let reimburse_tx = await btc_erc.reimburse(alice, redeemId, btc_tx, { from: alice });
        eventFired(reimburse_tx, "Reimburse");
        // redeem_fail_gas += reimburse_tx.receipt.gasUsed;
        // redeem_fail_txs += 1;

        // #### REPLACE #####
        // request the replace
        let request_replace_fail_tx = await btc_erc.requestReplace({ from: eve });
        eventFired(request_replace_fail_tx, "RequestReplace");
        // replace_fail_gas += request_replace_fail_tx.receipt.gasUsed;
        // replace_fail_txs += 1;

        // lock collateral
        let lock_col_fail_tx = await btc_erc.lockCol({ from: issuer, value: web3.toWei(collateral, "ether") });
        eventFired(lock_col_fail_tx, "LockReplace");
        // replace_fail_gas += lock_col_fail_tx.receipt.gasUsed;
        // replace_fail_txs += 1;

        // wait for timeout
        await new Promise(resolve => setTimeout(resolve, 2000));

        // replace abort
        let replace_fail_tx = await btc_erc.abortReplace({ from: issuer });
        eventFired(replace_fail_tx, "AbortReplace");
        // replace_fail_gas += replace_fail_tx.receipt.gasUsed;
        // replace_fail_txs += 1;

        var current_issuer = await btc_erc.issuer.call();
        assert.equal(current_issuer, eve, "FAIL: Made another person the issuer")
    })
})
