const truffleAssert = require('truffle-assertions');

var helpers = require('./helpers');
var generateBlocksGanache = helpers.generateBlocksGanache;


const XCLAIM = artifacts.require("./XCLAIM.sol");


contract('FAIL: XCLAIM', async (accounts) => {
    /* For testing and experiments the following roles apply: */
    const vault = accounts[0];
    const relayer = accounts[1];
    const alice = accounts[2];
    const bob = accounts[3];
    const carol = accounts[4];
    const eve = accounts[5];

    const amount = 1;
    const collateral = '0.01';
    const collateral_user = '0.00000001';
    let vault_collateral = web3.utils.toWei(collateral, "ether");
    let user_collateral = web3.utils.toWei(collateral_user, "ether");

    const btc_address_vault = web3.utils.hexToBytes("0x02a751dc8c10e35fed2c6eddc2575c9af2c71d23");
    const btc_address_bob = web3.utils.hexToBytes("0x69f374b39af4aa342997e0bdff3b3b297a85883c");
    const btc_tx = web3.utils.hexToBytes("0x3a7bdf6d01f068841a99cce22852698df8428d07c68a32d867b112a4b24c8fe0");
    const invalid_tx = web3.utils.hexToBytes("0xfe6c48bbfdc025670f4db0340650ba5a50f9307b091d9aaa19aa44291961c69f");

    // gas limit
    const gas_limit = 6000000;

    beforeEach('setup contract', async function () {
        btc_erc = await XCLAIM.deployed();
    });

    it("Setup", async () => {

        // check if authorize event fired
        let authorize_tx = await btc_erc.registerVault(vault, {
            from: vault,
            value: vault_collateral
        });
        truffleAssert.eventEmitted(authorize_tx, 'RegisterVault');
    })

    it("Issue asset", async () => {
        let balance_alice, balance_bob, balance_carol;
        // check if issue event is fired
        let issue_register_col_tx = await btc_erc.registerIssue(alice, amount, vault, btc_address_vault, {
            from: alice,
            value: user_collateral,
            gas: gas_limit
        });
        truffleAssert.eventEmitted(issue_register_col_tx, "RegisterIssue");
        // issue_fail_col_gas += fail_issue_register_col_tx.receipt.gasUsed;
        // issue_fail_col_txs += 1;

        let fail_issue_col_tx = await btc_erc.issueToken(alice, invalid_tx, {
            from: alice,
            gas: gas_limit
        });
        truffleAssert.eventEmitted(fail_issue_col_tx, "AbortIssue");
        // issue_fail_col_gas += fail_issue_col_tx.receipt.gasUsed;
        // issue_fail_col_txs += 1;

        // check if Alice's balance is updated
        balance_alice = await btc_erc.balanceOf.call(alice);
        balance_alice = balance_alice.toNumber();
        assert.equal(balance_alice, 0, "Alice balance should be 0");
    })

    it("Redeem assets", async () => {

        // check if redeem event fired
        let fail3_issue_register_col_tx = await btc_erc.registerIssue(alice, amount, vault, btc_address_vault, {
            from: alice,
            value: user_collateral,
            gas: gas_limit
        });
        truffleAssert.eventEmitted(fail3_issue_register_col_tx, "RegisterIssue");


        let fail3_issue_col_tx = await btc_erc.issueToken(alice, btc_tx, {
            from: alice,
            gas: gas_limit
        });
        truffleAssert.eventEmitted(fail3_issue_col_tx, "IssueToken");

        let fail_redeem_tx = await await btc_erc.requestRedeem(vault, alice, amount, btc_address_bob, {
            from: alice
        });
        truffleAssert.eventEmitted(fail_redeem_tx, "RequestRedeem");
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
        // await new Promise(resolve => setTimeout(resolve, 2000));

        // fail redeem
        let reimburse_tx = await btc_erc.reimburseRedeem(alice, redeemId, {
            from: alice
        });
        truffleAssert.eventEmitted(reimburse_tx, "Reimburse");
        // redeem_fail_gas += reimburse_tx.receipt.gasUsed;
        // redeem_fail_txs += 1;
    })

    it("Replace vault", async () => {
        // request the replace
        let request_replace_fail_tx = await btc_erc.requestReplace({
            from: vault
        });
        truffleAssert.eventEmitted(request_replace_fail_tx, "RequestReplace");
        // replace_fail_gas += request_replace_fail_tx.receipt.gasUsed;
        // replace_fail_txs += 1;

        // lock collateral
        let lock_col_fail_tx = await btc_erc.lockReplace(vault, {
            from: eve,
            value: vault_collateral
        });
        truffleAssert.eventEmitted(lock_col_fail_tx, "LockReplace");
        // replace_fail_gas += lock_col_fail_tx.receipt.gasUsed;
        // replace_fail_txs += 1;

        // wait for the replace eriod to pass
        let replace_period = await btc_erc.getReplacePeriod.call();
        await generateBlocksGanache(replace_period.toNumber());
        // await new Promise(resolve => setTimeout(resolve, 2000));

        // replace abort
        let replace_fail_tx = await btc_erc.abortReplace(vault, {
            from: eve
        });
        truffleAssert.eventEmitted(replace_fail_tx, "AbortReplace");
        // replace_fail_gas += replace_fail_tx.receipt.gasUsed;
        // replace_fail_txs += 1;

        var current_vault_collateral = await btc_erc.getVaultCollateral.call(vault);
        var eve_collateral = await btc_erc.getVaultCollateral.call(eve);
        assert.equal(current_vault_collateral, vault_collateral, "FAIL: Refunded the vault the collateral");
        assert.equal(eve_collateral.toNumber(), 0, "FAIL: did not refund Eve's collateral");
    })
})