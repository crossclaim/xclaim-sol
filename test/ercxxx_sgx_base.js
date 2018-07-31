const ERCXXX_SGX = artifacts.require("./impl/ERCXXX_SGX.sol");


contract('ERCXXX_SGX', async (accounts) => {
    /* For testing and experiments the following roles apply: */
    const issuer = accounts[0];
    const alice = accounts[1];
    const bob = accounts[2];
    const charlie = accounts[3];

    beforeEach('setup contract', async function () {
        btc_erc = await ERCXXX_SGX.new("BTC-ERC", "BTH", 1);
    });


    it("Register issuer", async () => {
        let initialIssuerList = await btc_erc.issuerList.call();

        // check if authorize event fired
        let authorize_tx = await btc_erc.authorizeIssuer(issuer, "", { from: issuer, value: web3.toWei(1, "ether") });
        eventFired(authorize_tx, "AuthorizedIssuer");
        // console.log(authorize_tx.receipt.gasUsed);

        // check if issuer list is updated
        let updatedIssuerList = await btc_erc.issuerList.call();

        assert.isTrue(web3.isAddress(updatedIssuerList));
        assert.equal(updatedIssuerList[0], issuer);
    });

    it("Issue tokens", async () => {
        let balance_alice;

        // check if authorize event fired
        let authorize_tx = await btc_erc.authorizeIssuer(issuer, "", { from: issuer, value: web3.toWei(1, "ether") });
        eventFired(authorize_tx, "AuthorizedIssuer");

        balance_alice = await btc_erc.balanceOf.call(alice);
        let init_balance_alice = balance_alice.toNumber();

        // check if issue event is fired
        let issue_tx = await btc_erc.issue(alice, "BTC_TX");
        eventFired(issue_tx, "Issue");

        balance_alice = await btc_erc.balanceOf.call(alice);
        let updated_balance_alice = balance_alice.toNumber();
        
        // check if Alice's balance is updated
        assert.isAbove(updated_balance_alice, init_balance_alice)
        assert.equal(updated_balance_alice, 1)        
    });


    it("Abort token creation", async () => {
        // Not sure if we can test this in Ethereum?

        let btc_erc = await ERCXXX_SGX.deployed();

        assert.isTrue(true);
    });

    it("Transfer tokens", async () => {
        let balance_alice, balance_bob;

        // check if authorize event fired
        let authorize_tx = await btc_erc.authorizeIssuer(issuer, "", { from: issuer, value: web3.toWei(1, "ether") });
        eventFired(authorize_tx, "AuthorizedIssuer");

        // check if issue event is fired
        let issue_tx = await btc_erc.issue(alice, "BTC_TX");
        eventFired(issue_tx, "Issue");

        // check if Alice's balance is updated
        balance_alice = await btc_erc.balanceOf.call(alice);
        balance_alice = balance_alice.toNumber();
        assert.equal(balance_alice, 1, "Alice balance should be 1");

        // check if transfer event fired
        let transfer_tx = await btc_erc.transfer(alice, bob, "", {from: alice});
        eventFired(transfer_tx, "Transfer");

        // check if balances are updated
        balance_alice = await btc_erc.balanceOf.call(alice);
        balance_alice = balance_alice.toNumber();
        balance_bob = await btc_erc.balanceOf.call(bob);
        balance_bob = balance_bob.toNumber();

        assert.equal(balance_alice, 0, "Alice balance should be 0");
        assert.equal(balance_bob, 1, "Bob balance should be 1");
    });

    it("Redeem tokens", async () => {
        let balance_alice;

        // check if authorize event fired
        let authorize_tx = await btc_erc.authorizeIssuer(issuer, "", { from: issuer, value: web3.toWei(1, "ether") });
        eventFired(authorize_tx, "AuthorizedIssuer");

        // check if issue event is fired
        let issue_tx = await btc_erc.issue(alice, "BTC_TX");
        eventFired(issue_tx, "Issue");

        // check if Alice's balance is updated
        balance_alice = await btc_erc.balanceOf.call(alice);
        balance_alice = balance_alice.toNumber();
        assert.equal(balance_alice, 1, "Alice balance should be 1");

        // check if redeem event fired
        let redeem_tx = await btc_erc.redeem(alice, "", { from: alice });
        eventFired(transfer_tx, "Redeem");

        // check if balances are updated
        balance_alice = await btc_erc.balanceOf.call(alice);
        balance_alice = balance_alice.toNumber();
        balance_bob = await btc_erc.balanceOf.call(bob);
        balance_bob = balance_bob.toNumber();

        assert.equal(balance_alice, 0, "Alice balance should be 0");
        assert.equal(balance_bob, 1, "Bob balance should be 1");
    });

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

})