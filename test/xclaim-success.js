var helpers = require('./helpers');
var eventFired = helpers.eventFired;


const XCLAIM = artifacts.require("./XCLAIM.sol");


contract('SUCCESS: XCLAIM', async (accounts) => {
    /* For testing and experiments the following roles apply: */
    const issuer = accounts[0];
    const relayer = accounts[1];
    const alice = accounts[2];
    const bob = accounts[3];
    const carol = accounts[4];
    const eve = accounts[5];

    const amount = 1;
    const collateral = "0.01";
    const collateral_user = "0.00000001";
    const collateral_user_number = 0.00000001;
    const btc_tx = web3.utils.hexToBytes("0x3a7bdf6d01f068841a99cce22852698df8428d07c68a32d867b112a4b24c8fe0");

    // gas limit
    const gas_limit = 6000000;

    beforeEach('setup contract', async function () {
        btc_erc = await XCLAIM.deployed();
    });

    it("Setup", async () => {

        // check if authorize event fired
        let authorize_tx = await btc_erc.authorizeIssuer(issuer, {
            from: issuer,
            value: web3.utils.toWei(collateral, "ether")
        });
        eventFired(authorize_tx, "AuthorizedIssuer");
    })

    it("Issue asset", async () => {
        let balance_alice, balance_bob, balance_carol;

        let user_collateral = web3.utils.toWei(collateral_user, "ether")

        // check if issue event is fired
        let issue_register_col_tx = await btc_erc.registerIssue(amount, btc_tx, {
            from: alice,
            value: user_collateral,
            gas: gas_limit
        });
        eventFired(issue_register_col_tx, "RegisterIssue");
        // issue_success_col_gas += issue_register_col_tx.receipt.gasUsed;
        // issue_success_col_txs += 1;

        let issue_col_tx = await btc_erc.issueCol(alice, amount, btc_tx, {
            from: alice,
            gas: gas_limit
        });
        eventFired(issue_col_tx, "IssueToken");
        // issue_success_col_gas += issue_col_tx.receipt.gasUsed;
        // issue_success_col_txs += 1;

        // check if Alice's balance is updated
        balance_alice = await btc_erc.balanceOf.call(alice);
        balance_alice = balance_alice.toNumber();
        assert.equal(balance_alice, amount, "SUCCESS COL: Alice balance should be 1");

    })

    it("Swap assets", async () => {
        let transfer_one = await btc_erc.transfer(bob, 1, {
            from: alice
        });
        eventFired(transfer_one, "Transfer");
        // transfer_success_gas = transfer_one.receipt.gasUsed;
        // transfer_success_txs = 1;

        let transfer_two = await btc_erc.transfer(alice, 1, {
            from: bob
        });
        eventFired(transfer_two, "Transfer");

        // #### TRADE #####
        // Offer exchange of 1 token for 100 wei
        let offer_tx = await btc_erc.offerTrade(1, 100, bob, {
            from: alice
        });
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
        let trade_tx = await btc_erc.acceptTrade(offerId, {
            from: bob,
            value: 100
        });
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
    })

    it("Redeem assets", async () => {
        // check if redeem event fired
        let redeem_tx = await btc_erc.redeem(bob, amount, btc_tx, {
            from: relayer
        });
        eventFired(redeem_tx, "RequestRedeem");
        // redeem_success_gas += redeem_tx.receipt.gasUsed;
        // redeem_success_txs += 1;

        /* Get redeem id*/
        var redeemId;
        for (var i = 0; i < redeem_tx.logs.length; i++) {
            var log = redeem_tx.logs[i];
            if (log.event == "RequestRedeem") {
                // We found the event!
                redeemId = log.args.id.toNumber();
            }
        }

        // check if redeem succeeded
        let redeem_success_tx = await btc_erc.redeemConfirm(bob, redeemId, btc_tx, {
            from: bob,
            gas: gas_limit
        });
        eventFired(redeem_success_tx, "ConfirmRedeem");
        // redeem_success_gas += redeem_success_tx.receipt.gasUsed;
        // redeem_success_txs += 1;
    })

    it("Replace issuer", async () => {
        // request the replace
        let request_replace_success_tx = await btc_erc.requestReplace({
            from: issuer
        });
        eventFired(request_replace_success_tx, "RequestReplace");
        // replace_success_gas += request_replace_success_tx.receipt.gasUsed;
        // replace_success_txs += 1;

        // lock collateral
        let lock_col_success_tx = await btc_erc.lockCol({
            from: eve,
            value: web3.utils.toWei(collateral, "ether")
        });
        eventFired(lock_col_success_tx, "LockReplace");
        // replace_success_gas += lock_col_success_tx.receipt.gasUsed;
        // replace_success_txs += 1;

        // replace the issuer
        let replace_success_tx = await btc_erc.replace(btc_tx, {
            from: issuer,
            gas: gas_limit
        });
        eventFired(replace_success_tx, "ExecuteReplace");
        // replace_success_gas += replace_success_tx.receipt.gasUsed;
        // replace_success_txs += 1;

        var current_issuer = await btc_erc.issuer.call();
        assert.equal(current_issuer, eve, "SUCCESS: Did make Eve the issuer")
    })

})