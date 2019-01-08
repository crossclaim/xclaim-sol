var helpers = require('./helpers');
var eventFired = helpers.eventFired;


const XCLAIM = artifacts.require("./XCLAIM.sol");


contract('FAIL: XCLAIM', async (accounts) => {
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
    let user_collateral = web3.utils.toWei(collateral_user, "ether");

    const btc_tx = web3.utils.hexToBytes("0x3a7bdf6d01f068841a99cce22852698df8428d07c68a32d867b112a4b24c8fe0");
    const invalid_tx = web3.utils.hexToBytes("0x");

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

        // check if issue event is fired
        let issue_register_col_tx = await btc_erc.registerIssue(amount, invalid_tx, {
            from: alice,
            value: user_collateral,
            gas: gas_limit
        });
        eventFired(issue_register_col_tx, "RegisterIssue");
        // issue_fail_col_gas += fail_issue_register_col_tx.receipt.gasUsed;
        // issue_fail_col_txs += 1;

        let fail_issue_col_tx = await btc_erc.issueToken(alice, amount, invalid_tx, {
            from: relayer
        });
        eventFired(fail_issue_col_tx, "AbortIssue");
        // issue_fail_col_gas += fail_issue_col_tx.receipt.gasUsed;
        // issue_fail_col_txs += 1;

        // check if Alice's balance is updated
        balance_alice = await btc_erc.balanceOf.call(alice);
        balance_alice = balance_alice.toNumber();
        assert.equal(balance_alice, 0, "Alice balance should be 0");
    })

    it("Redeem assets", async () => {

        // check if redeem event fired
        let fail3_issue_register_col_tx = await btc_erc.registerIssue(amount, btc_tx, {
            from: alice,
            value: user_collateral,
            gas: gas_limit
        });
        eventFired(fail3_issue_register_col_tx, "RegisterIssue");


        let fail3_issue_col_tx = await btc_erc.issueToken(alice, amount, btc_tx, {
            from: alice
        });
        eventFired(fail3_issue_col_tx, "IssueToken");

        let fail_redeem_tx = await btc_erc.redeem(alice, amount, btc_tx, {
            from: relayer
        });
        eventFired(fail_redeem_tx, "RequestRedeem");
        // redeem_fail_gas += fail_redeem_tx.receipt.gasUsed;
        // redeem_fail_txs += 1;

        /* Get redeem id*/
        var redeemId;
        for (var i = 0; i < fail_redeem_tx.logs.length; i++) {
            var log = fail_redeem_tx.logs[i];
            if (log.event == "RequestRedeem") {
                // We found the event!
                redeemId = log.args.id.toNumber();
            }
        }

        // wait for timeout
        await new Promise(resolve => setTimeout(resolve, 2000));

        // fail redeem
        let reimburse_tx = await btc_erc.reimburse(alice, redeemId, btc_tx, {
            from: alice
        });
        eventFired(reimburse_tx, "Reimburse");
        // redeem_fail_gas += reimburse_tx.receipt.gasUsed;
        // redeem_fail_txs += 1;
    })

    it("Replace issuer", async () => {
        // request the replace
        var current_issuer = await btc_erc.issuer.call();
        let request_replace_fail_tx = await btc_erc.requestReplace({
            from: current_issuer
        });
        eventFired(request_replace_fail_tx, "RequestReplace");
        // replace_fail_gas += request_replace_fail_tx.receipt.gasUsed;
        // replace_fail_txs += 1;

        // lock collateral
        let lock_col_fail_tx = await btc_erc.lockCol({
            from: eve,
            value: web3.utils.toWei(collateral, "ether")
        });
        eventFired(lock_col_fail_tx, "LockReplace");
        // replace_fail_gas += lock_col_fail_tx.receipt.gasUsed;
        // replace_fail_txs += 1;

        // wait for timeout
        await new Promise(resolve => setTimeout(resolve, 2000));

        // replace abort
        let replace_fail_tx = await btc_erc.abortReplace({
            from: eve
        });
        eventFired(replace_fail_tx, "AbortReplace");
        // replace_fail_gas += replace_fail_tx.receipt.gasUsed;
        // replace_fail_txs += 1;

        var current_issuer = await btc_erc.issuer.call();
        assert.equal(current_issuer, issuer, "FAIL: Made another person the issuer")
    })
})