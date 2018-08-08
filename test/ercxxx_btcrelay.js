const ERCXXX_BTCRelay = artifacts.require("./impl/ERCXXX_BTCRelay.sol");
const BTCRelay = artifacts.require("./BTCRelay/BTCRelay.sol");

// Writing experiments data to CSV
var fs = require("fs");
var csvWriter = require('csv-write-stream');
var writer = csvWriter();

// Integrate with bitcoin
const Client = require('bitcoin-core');


contract('ERCXXX_BTCRelay', async (accounts) => {
    /* For testing and experiments the following roles apply: */
    const issuer = accounts[0];
    const relayer = accounts[1];
    const collateral = 0.01;
    const alice = accounts[2];
    const bob = accounts[3];
    const carol = accounts[4];
    const eve = accounts[5];
    const btc_tx = "3a7bdf6d01f068841a99cce22852698df8428d07c68a32d867b112a4b24c8fe0";

    // gas price conversion
    const gas_price = web3.toWei(5, "gwei");
    const eth_usd = 409; // USD
    const gas_limit = 7988288;

    // experiment related vars
    var issue_success_col_gas = 0;
    var issue_fail_col_gas = 0;
    var issue_success_htlc_gas = 0;
    var issue_fail_htlc_gas = 0;
    var trade_success_gas = 0;
    var trade_fail_gas = 0;
    var redeem_success_gas = 0;
    var redeem_fail_gas = 0;
    var replace_success_gas = 0;
    var replace_fail_gas = 0;

    var issue_success_col_txs = 0;
    var issue_fail_col_txs = 0;
    var issue_success_htlc_txs = 0;
    var issue_fail_htlc_txs = 0;
    var trade_success_txs = 0;
    var trade_fail_txs = 0;
    var redeem_success_txs = 0;
    var redeem_fail_txs = 0;
    var replace_success_txs = 0;
    var replace_fail_txs = 0;


    before('Create writer for experiments', async () => {
        writer.pipe(fs.createWriteStream(('./experiments/Gas_ERCXXX_BTCRelay.csv')));
    })

    after('Write experiment data to file', async () => {
        let issue_success_col_usd = convertToUsd(issue_success_col_gas);
        let issue_fail_col_usd = convertToUsd(issue_fail_col_gas);
        let issue_success_htlc_usd = convertToUsd(issue_success_htlc_gas);
        let issue_fail_htlc_usd = convertToUsd(issue_fail_htlc_gas);
        let trade_success_usd = convertToUsd(trade_success_gas);
        let trade_fail_usd = convertToUsd(trade_fail_gas);
        let redeem_success_usd = convertToUsd(redeem_success_gas);
        let redeem_fail_usd = convertToUsd(redeem_fail_gas);
        let replace_success_usd = convertToUsd(replace_success_gas);
        let replace_fail_usd = convertToUsd(replace_fail_gas);

        writer.write(
            {
                IssueColSuccess: issue_success_col_gas,
                IssueColFail: issue_fail_col_gas,
                IssueHTLCSuccesss: issue_success_htlc_gas,
                IssueHTLCFail: issue_fail_htlc_gas,
                TradeSuccess: trade_success_gas,
                TradeFail: trade_fail_gas,
                RedeemSuccess: redeem_success_gas,
                RedeemFail: redeem_fail_gas,
                ReplaceSuccess: replace_success_gas,
                ReplaceFail: replace_fail_gas
            });
        writer.write(
            {
                IssueColSuccess: issue_success_col_usd,
                IssueColFail: issue_fail_col_usd,
                IssueHTLCSuccesss: issue_success_htlc_usd,
                IssueHTLCFail: issue_fail_htlc_usd,
                TradeSuccess: trade_success_usd,
                TradeFail: trade_fail_usd,
                RedeemSuccess: redeem_success_usd,
                RedeemFail: redeem_fail_usd,
                ReplaceSuccess: replace_success_usd,
                ReplaceFail: replace_fail_usd
            });
        writer.write(
            {
                IssueColSuccess: issue_success_col_txs,
                IssueColFail: issue_fail_col_txs,
                IssueHTLCSuccesss: issue_success_htlc_txs,
                IssueHTLCFail: issue_fail_htlc_txs,
                TradeSuccess: trade_success_txs,
                TradeFail: trade_fail_txs,
                RedeemSuccess: redeem_success_txs,
                RedeemFail: redeem_fail_txs,
                ReplaceSuccess: replace_success_txs,
                ReplaceFail: replace_fail_txs
            });
        writer.end();
    })

    beforeEach('setup contract', async function () {
        btc_relay = await BTCRelay.deployed();
        btc_erc = await ERCXXX_BTCRelay.deployed();
    });

    it("Experiment success", async () => {
        let balance_alice, balance_bob, balance_carol;
        let amount = 0.01;

        // #### SETUP #####
        // check if authorize event fired
        let fail_authorize_tx = await btc_erc.authorizeIssuer(issuer, { from: issuer, value: web3.toWei(collateral, "ether") });
        eventFired(fail_authorize_tx, "AuthorizedIssuer");

        // #### COLL. ISSUE #####
        // check if issue event is fired
        let issue_register_col_tx = await btc_erc.registerIssue(amount, { from: alice, value: web3.toWei(amount, "ether") });
        eventFired(issue_register_col_tx, "RegisterIssue");
        issue_success_col_gas += issue_register_col_tx.receipt.gasUsed;
        issue_success_col_txs += 1;

        let issue_col_tx = await btc_erc.issueCol(alice, amount, btc_tx, { from: relayer, gas: gas_limit });
        eventFired(issue_col_tx, "Issue");
        issue_success_col_gas += issue_col_tx.receipt.gasUsed;
        issue_success_col_txs += 1;

        // check if Alice's balance is updated
        balance_alice = await btc_erc.balanceOf.call(alice);
        balance_alice = balance_alice.toNumber();
        assert.equal(balance_alice, amount, "SUCCESS COL: Alice balance should be 1");

        // #### HTLC ISSUE #####
        // check if issue event is fired
        // DIRTY!
        let issue_register_htlc_tx = await btc_erc.registerHTLC(amount, amount, btc_tx, btc_tx, btc_tx, { from: carol });
        eventFired(issue_register_htlc_tx, "RegisterIssue");
        issue_success_htlc_gas += issue_register_htlc_tx.receipt.gasUsed;
        issue_success_htlc_txs += 1;

        let issue_htlc_tx = await btc_erc.issueHTLC(carol, amount, btc_tx, { from: relayer });
        eventFired(issue_htlc_tx, "Issue");
        issue_success_htlc_gas += issue_htlc_tx.receipt.gasUsed;
        issue_success_htlc_txs += 1;

        // check if Alice's balance is updated
        balance_carol = await btc_erc.balanceOf.call(carol);
        balance_carol = balance_carol.toNumber();
        assert.equal(balance_carol, amount, "SUCCESS HTLC: Alice balance should be 1");



        // #### TRADE #####
        // Offer exchange of 1 token for 100 wei
        let offer_tx = await btc_erc.offerTrade(1, 100, bob, { from: alice });
        // Check event is fired
        eventFired(offer_tx, "NewTradeOffer");
        trade_success_gas += offer_tx.receipt.gasUsed;
        trade_success_txs += 1;
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
        trade_success_gas += trade_tx.receipt.gasUsed;
        trade_success_txs += 1;

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

        // #### REPLACE #####
        // request the replace
        let request_replace_success_tx = await btc_erc.requestReplace({ from: issuer });
        eventFired(request_replace_success_tx, "RequestReplace");
        replace_success_gas += request_replace_success_tx.receipt.gasUsed;
        replace_success_txs += 1;

        // lock collateral
        let lock_col_success_tx = await btc_erc.lockCol({ from: eve, value: web3.toWei(collateral, "ether") });
        eventFired(lock_col_success_tx, "LockReplace");
        replace_success_gas += lock_col_success_tx.receipt.gasUsed;
        replace_success_txs += 1;

        // replace the issuer
        let replace_success_tx = await btc_erc.replace(btc_tx, { from: issuer });
        eventFired(replace_success_tx, "Replace");
        replace_success_gas += replace_success_tx.receipt.gasUsed;
        replace_success_txs += 1;

        var current_issuer = await btc_erc.issuer.call();
        assert.equal(current_issuer, eve, "SUCCESS: Did not make Eve the issuer")
    })

    it("Experiment fail", async () => {
        let balance_alice, balance_bob, balance_carol;
        let amount = 1;

        // #### SETUP #####
        // check if authorize event fired
        let fail_authorize_tx = await btc_erc.authorizeIssuer(issuer, { from: issuer, value: web3.toWei(collateral, "ether") });
        eventFired(fail_authorize_tx, "AuthorizedIssuer");


        // #### COLL. ISSUE #####
        // check if issue event is fired
        let fail_issue_register_col_tx = await btc_erc.registerIssue(amount, { from: alice, value: web3.toWei(amount, "ether") });
        eventFired(fail_issue_register_col_tx, "RegisterIssue");
        issue_fail_col_gas += fail_issue_register_col_tx.receipt.gasUsed;
        issue_fail_col_txs += 1;

        let fail_issue_col_tx = await btc_erc.issueCol(alice, amount, "", { from: relayer });
        eventFired(fail_issue_col_tx, "AbortIssue");
        issue_fail_col_gas += fail_issue_col_tx.receipt.gasUsed;
        issue_fail_col_txs += 1;

        // check if Alice's balance is updated
        balance_alice = await btc_erc.balanceOf.call(alice);
        balance_alice = balance_alice.toNumber();
        assert.equal(balance_alice, 0, "Alice balance should be 0");

        // #### HTLC ISSUE #####
        // check if issue event is fired
        // DIRTY!
        let fail_issue_register_htlc_tx = await btc_erc.registerHTLC(amount, amount, btc_tx, btc_tx, btc_tx, { from: carol });
        eventFired(fail_issue_register_htlc_tx, "RegisterIssue");
        issue_fail_htlc_gas += fail_issue_register_htlc_tx.receipt.gasUsed;
        issue_fail_htlc_txs += 1;

        let fail_issue_htlc_tx = await btc_erc.issueHTLC(carol, amount, "", { from: relayer });
        eventFired(fail_issue_htlc_tx, "AbortIssue");
        issue_fail_htlc_gas += fail_issue_htlc_tx.receipt.gasUsed;
        issue_fail_htlc_txs += 1;

        // check if Carol's balance is updated
        balance_carol = await btc_erc.balanceOf.call(carol);
        balance_carol = balance_carol.toNumber();
        assert.equal(balance_carol, 0, "Carol balance should be 0");



        // #### TRADE #####
        let fail2_issue_register_col_tx = await btc_erc.registerIssue(amount, { from: alice, value: web3.toWei(amount, "ether") });
        eventFired(fail2_issue_register_col_tx, "RegisterIssue");


        let fail2_issue_col_tx = await btc_erc.issueCol(alice, amount, btc_tx, { from: relayer });
        eventFired(fail2_issue_col_tx, "Issue");

        // Offer exchange of 1 token for 100 wei
        let fail_offer_tx = await btc_erc.offerTrade(1, 100, bob, { from: alice });
        // Check event is fired
        eventFired(fail_offer_tx, "NewTradeOffer");
        trade_fail_gas += fail_offer_tx.receipt.gasUsed;
        trade_fail_txs += 1;
        /* Get offer id*/
        // var offerId = 0;
        // for (var i = 0; i < offer_tx.logs.length; i++) {
        //     var log = offer_tx.logs[i];
        //     if (log.event == "NewTradeOffer") {
        //         // We found the event!
        //         offerId = log.args.id.toString();
        //     }
        // }
        // Do not complete the transfer
        // let trade_tx = await btc_erc.acceptTrade(offerId, { from: bob, value: 100 });
        // Check event is fired
        // eventFired(trade_tx, "Trade");
        // trade_success_gas += trade_tx.receipt.gasUsed;
        // trade_success_txs += 1;

        // check if balances are updated
        balance_alice = await btc_erc.balanceOf.call(alice);
        balance_alice = balance_alice.toNumber();
        balance_bob = await btc_erc.balanceOf.call(bob);
        balance_bob = balance_bob.toNumber();
        balance_carol = await btc_erc.balanceOf.call(carol);
        balance_carol = balance_carol.toNumber();

        assert.equal(balance_alice, 0, "FAIL: Alice balance should be 0");
        assert.equal(balance_bob, 0, "Bob balance should be 0");
        assert.equal(balance_carol, 0, "Carol balance should be 0");

        // #### REDEEM #####
        // check if redeem event fired
        let fail3_issue_register_col_tx = await btc_erc.registerIssue(amount, { from: alice, value: web3.toWei(amount, "ether") });
        eventFired(fail3_issue_register_col_tx, "RegisterIssue");


        let fail3_issue_col_tx = await btc_erc.issueCol(alice, amount, btc_tx, { from: relayer });
        eventFired(fail3_issue_col_tx, "Issue");

        let fail_redeem_tx = await btc_erc.redeem(alice, amount, btc_tx, { from: relayer });
        eventFired(fail_redeem_tx, "Redeem");
        redeem_fail_gas += fail_redeem_tx.receipt.gasUsed;
        redeem_fail_txs += 1;

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
        redeem_fail_gas += reimburse_tx.receipt.gasUsed;
        redeem_fail_txs += 1;

        // #### REPLACE #####
        // request the replace
        let request_replace_fail_tx = await btc_erc.requestReplace({ from: issuer });
        eventFired(request_replace_fail_tx, "RequestReplace");
        replace_fail_gas += request_replace_fail_tx.receipt.gasUsed;
        replace_fail_txs += 1;

        // lock collateral
        let this_collateral = await btc_erc.issuerCollateral.call();
        this_collateral = this_collateral.toNumber();
        let lock_col_fail_tx = await btc_erc.lockCol({ from: eve, value: this_collateral });
        eventFired(lock_col_fail_tx, "LockReplace");
        replace_fail_gas += lock_col_fail_tx.receipt.gasUsed;
        replace_fail_txs += 1;

        // wait for timeout
        await new Promise(resolve => setTimeout(resolve, 2000));

        // replace abort
        let replace_fail_tx = await btc_erc.abortReplace({ from: eve });
        eventFired(replace_fail_tx, "AbortReplace");
        replace_fail_gas += replace_fail_tx.receipt.gasUsed;
        replace_fail_txs += 1;

        var current_issuer = await btc_erc.issuer.call();
        assert.equal(current_issuer, issuer, "FAIL: Made Eve the issuer")
    })

    function eventFired(transaction, eventName) {
        for (var i = 0; i < transaction.logs.length; i++) {
            var log = transaction.logs[i];
            if (log.event == eventName) {
                // We found the event!
                assert.isTrue(true);
            }
            else {
                assert.isTrue(false, "Did not find " + eventName);
            }
        }
    };

    function convertToUsd(gasCost) {
        return gasCost * web3.fromWei(gas_price, "ether") * eth_usd;
    }


})
