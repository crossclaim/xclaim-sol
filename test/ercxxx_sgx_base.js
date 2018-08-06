const ERCXXX_SGX = artifacts.require("./impl/ERCXXX_SGX.sol");

// Writing experiments data to CSV
var fs = require("fs");
var csvWriter = require('csv-write-stream');
var writer = csvWriter();

// Integrate with bitcoin
const Client = require('bitcoin-core');


contract('ERCXXX_SGX', async (accounts) => {
    /* For testing and experiments the following roles apply: */
    const issuer = accounts[0];
    const collateral = 0;
    const alice = accounts[1];
    const bob = accounts[2];
    const carol = accounts[3];
    const btc_tx = "3a7bdf6d01f068841a99cce22852698df8428d07c68a32d867b112a4b24c8fe0";

    // gas price conversion
    const gas_price = web3.toWei(5, "gwei");
    const eth_usd = 409; // USD

    // experiment related vars
    var issue_success_col_gas = 0;
    var issue_fail_col_gas = 0;
    var issue_success_htlc_gas = 0;
    var issue_fail_htlc_gas = 0;
    var trade_success_gas = 0;
    var trade_fail_gas = 0;
    var redeem_success_gas = 0;
    var redeem_fail_gas = 0;

    var issue_success_col_txs = 0;
    var issue_fail_col_txs = 0;
    var issue_success_htlc_txs = 0;
    var issue_fail_htlc_txs = 0;
    var trade_success_txs = 0;
    var trade_fail_txs = 0;
    var redeem_success_txs = 0;
    var redeem_fail_txs = 0;

    before('Create writer for experiments', async () => {
        writer.pipe(fs.createWriteStream(('./experiments/Gas_ERCXXX_SGX.csv')));
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

        writer.write(
            {
                IssueColSuccess: issue_success_col_gas,
                IssueColFail: issue_fail_col_gas,
                IssueHTLCSuccesss: issue_success_htlc_gas,
                IssueHTLCFail: issue_fail_htlc_gas,
                TradeSuccess: trade_success_gas,
                TradeFail: trade_fail_gas,
                RedeemSuccess: redeem_success_gas,
                RedeemFail: redeem_fail_gas
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
                RedeemFail: redeem_fail_usd
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
                RedeemFail: redeem_fail_txs
            });
        writer.end();
    })

    beforeEach('setup contract', async function () {
        btc_erc = await ERCXXX_SGX.new("BTC-ERC", "BTH", 1);
    });

    xit("Authorize issuer", async () => {
        // check if authorize event fired
        let authorize_tx = await btc_erc.authorizeIssuer(issuer, { from: issuer, value: web3.toWei(collateral, "ether") });
        eventFired(authorize_tx, "AuthorizedIssuer");
        authorize_gas = authorize_tx.receipt.gasUsed;

        // check if issuer list is updated
        let updatedIssuer = await btc_erc.issuer.call();

        assert.isTrue(web3.isAddress(updatedIssuer));
        assert.equal(updatedIssuer, issuer);
    });

    xit("Authorize and revoke issuer", async () => {
        // TODO: Implement test to revoke issuer
        let initialIssuer = await btc_erc.issuer.call();

        // check if authorize event fired
        let authorize_tx = await btc_erc.authorizeIssuer(issuer, { from: issuer, value: web3.toWei(collateral, "ether") });
        eventFired(authorize_tx, "AuthorizedIssuer");
        // console.log(authorize_tx.receipt.gasUsed);

        // let revoke_tx = await btc_erc.revokeIssuer(issuer, { from: issuer});
        // eventFired(revoke_tx, "RevokedIssuer");

        // check if issuer list is updated
        // let updatedIssuerList = await btc_erc.issuerList.call();

        // assert.equal(initialIssuerList, updatedIssuerList);
        assert.isTrue(true);
    });

    xit("Issue tokens", async () => {
        let balance_alice;
        let amount = 1;

        // check if authorize event fired
        let authorize_tx = await btc_erc.authorizeIssuer(issuer, { from: issuer, value: web3.toWei(collateral, "ether") });
        eventFired(authorize_tx, "AuthorizedIssuer");

        balance_alice = await btc_erc.balanceOf.call(alice);
        let init_balance_alice = balance_alice.toNumber();

        // check if issue event is fired
        let issue_tx = await btc_erc.issueCol(alice, amount, btc_tx);
        eventFired(issue_tx, "Issue");
        issue_gas = issue_tx.receipt.gasUsed;

        balance_alice = await btc_erc.balanceOf.call(alice);
        let updated_balance_alice = balance_alice.toNumber();
        
        // check if Alice's balance is updated
        assert.isAbove(updated_balance_alice, init_balance_alice)
        assert.equal(updated_balance_alice, 1)        
    });


    xit("Abort token creation", async () => {
        // Not sure if we can test this in Ethereum?

        let btc_erc = await ERCXXX_SGX.deployed();

        assert.isTrue(true);
    });

    xit("Trade tokens", async () => {
        let balance_alice, balance_bob;
        let amount = 1;

        // check if authorize event fired
        let authorize_tx = await btc_erc.authorizeIssuer(issuer, { from: issuer, value: web3.toWei(collateral, "ether") });
        eventFired(authorize_tx, "AuthorizedIssuer");

        // check if issue event is fired
        let issue_tx = await btc_erc.issueCol(alice, amount, btc_tx);
        eventFired(issue_tx, "Issue");

        // check if Alice's balance is updated
        balance_alice = await btc_erc.balanceOf.call(alice);
        balance_alice = balance_alice.toNumber();
        assert.equal(balance_alice, amount, "Alice balance should be 1");

        // Offer exchange of 1 token for 100 wei
        let offer_tx = await btc_erc.offerTrade(1, 100, bob, {from: alice});
        // Check event is fired
        eventFired(offer_tx, "NewTradeOffer");
        trade_offer_gas = offer_tx.receipt.gasUsed;
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
        let trade_tx = await btc_erc.acceptTrade(offerId, {from: bob, value: 100});
        // Check event is fired
        eventFired(trade_tx, "Trade");
        trade_accept_gas = trade_tx.receipt.gasUsed;

        // check if balances are updated
        balance_alice = await btc_erc.balanceOf.call(alice);
        balance_alice = balance_alice.toNumber();
        balance_bob = await btc_erc.balanceOf.call(bob);
        balance_bob = balance_bob.toNumber();

        assert.equal(balance_alice, 0, "Alice balance should be 0");
        assert.equal(balance_bob, amount, "Bob balance should be 1");
    });

    xit("Transfer tokens", async () => {
        let balance_alice, balance_bob;
        let amount = 1;

        // check if authorize event fired
        let authorize_tx = await btc_erc.authorizeIssuer(issuer, { from: issuer, value: web3.toWei(collateral, "ether") });
        eventFired(authorize_tx, "AuthorizedIssuer");

        // check if issue event is fired
        let issue_tx = await btc_erc.issueCol(alice, amount, btc_tx);
        eventFired(issue_tx, "Issue");

        // check if Alice's balance is updated
        balance_alice = await btc_erc.balanceOf.call(alice);
        balance_alice = balance_alice.toNumber();
        assert.equal(balance_alice, amount, "Alice balance should be 1");

        // check if transfer event fired
        let transfer_tx = await btc_erc.transfer(alice, bob, 1, {from: alice});
        eventFired(transfer_tx, "Transfer");
        transfer_gas = transfer_tx.receipt.gasUsed;

        // check if balances are updated
        balance_alice = await btc_erc.balanceOf.call(alice);
        balance_alice = balance_alice.toNumber();
        balance_bob = await btc_erc.balanceOf.call(bob);
        balance_bob = balance_bob.toNumber();

        assert.equal(balance_alice, 0, "Alice balance should be 0");
        assert.equal(balance_bob, amount, "Bob balance should be 1");
    });

    xit("Redeem tokens", async () => {
        let balance_alice;
        let amount = 1;

        // check if authorize event fired
        let authorize_tx = await btc_erc.authorizeIssuer(issuer, { from: issuer, value: web3.toWei(collateral, "ether") });
        eventFired(authorize_tx, "AuthorizedIssuer");

        // check if issue event is fired
        let issue_tx = await btc_erc.issueCol(alice, amount, btc_tx);
        eventFired(issue_tx, "Issue");

        // check if Alice's balance is updated
        balance_alice = await btc_erc.balanceOf.call(alice);
        balance_alice = balance_alice.toNumber();
        assert.equal(balance_alice, 1, "Alice balance should be 1");

        // check if redeem event fired
        let redeem_tx = await btc_erc.redeem(alice, amount, btc_tx, { from: issuer });
        eventFired(redeem_tx, "Redeem");
        redeem_gas = redeem_tx.receipt.gasUsed;
    });

    it("Experiment success", async () => {
        let balance_alice, balance_bob, balance_carol;
        let amount = 1;

        // #### SETUP #####
        // check if authorize event fired
        let authorize_tx = await btc_erc.authorizeIssuer(issuer, { from: issuer, value: web3.toWei(collateral, "ether") });
        eventFired(authorize_tx, "AuthorizedIssuer");

        // #### COLL. ISSUE #####
        // check if issue event is fired
        let issue_register_col_tx = await btc_erc.registerIssue(amount, { from: alice, value: web3.toWei(amount, "ether") });
        eventFired(issue_register_col_tx, "RegisterIssue");
        issue_success_col_gas += issue_register_col_tx.receipt.gasUsed;
        issue_success_col_txs += 1;
        
        let issue_col_tx = await btc_erc.issueCol(alice, amount, btc_tx, {from:issuer});
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

        let issue_htlc_tx = await btc_erc.issueHTLC(carol, amount, btc_tx);
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
        let redeem_tx = await btc_erc.redeem(bob, amount, btc_tx, { from: issuer });
        eventFired(redeem_tx, "Redeem");
        redeem_success_gas += redeem_tx.receipt.gasUsed;
        redeem_success_txs += 1;
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

        let fail_issue_col_tx = await btc_erc.issueCol(alice, amount, "", { from: issuer });
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

        let fail_issue_htlc_tx = await btc_erc.issueHTLC(carol, amount, "");
        eventFired(fail_issue_htlc_tx, "AbortIssue");
        issue_fail_htlc_gas += fail_issue_htlc_tx.receipt.gasUsed;
        issue_fail_htlc_txs += 1;

        // check if Carol's balance is updated
        balance_carol = await btc_erc.balanceOf.call(carol);
        balance_carol = balance_carol.toNumber();
        assert.equal(balance_carol, 0, "Alice balance should be 0");



        // #### TRADE #####
        let fail2_issue_register_col_tx = await btc_erc.registerIssue(amount, { from: alice, value: web3.toWei(amount, "ether") });
        eventFired(fail2_issue_register_col_tx, "RegisterIssue");


        let fail2_issue_col_tx = await btc_erc.issueCol(alice, amount, btc_tx, { from: issuer });
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

        assert.equal(balance_alice, 0, "FAIL: Alice balance should be 0");
        assert.equal(balance_bob, 0, "Bob balance should be 0");

        // #### REDEEM #####
        // no failed stated for centralised SGX

        // let fail_redeem_tx = await btc_erc.redeem(bob, amount, btc_tx, { from: issuer });

        redeem_success_gas += 0;
        redeem_success_txs += 0;
    })

    function eventFired(transaction, eventName) {
        for (var i = 0; i < transaction.logs.length; i++) {
            var log = transaction.logs[i];
            if (log.event == eventName) {
                // We found the event!
                assert.isTrue(true);
            }
            else {
                assert.isTrue(false);
            }
        }
    };

    function convertToUsd(gasCost) {
        return gasCost * web3.fromWei(gas_price, "ether") * eth_usd;
    }

})
