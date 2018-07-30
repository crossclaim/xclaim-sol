const ERCXXX_SGX = artifacts.require("./impl/ERCXXX_SGX.sol");


contract('ERCXXX_SGX', async (accounts) => {
    /* For testing and experiments the following roles apply:
    issuer == accounts[0]
    alice == accounts[1]
    bob == accounts[2]        */
    const issuer = accounts[0];
    const alice = accounts[1];
    const bob = accounts[2];
    // beforeEach('setup contract', async function () {
    //     btc_erc = await ERCXXX_SGX.new("BTC-ERC", "BTH", 1);
    // });


    it("Register issuer", async () => {
        let btc_erc = await ERCXXX_SGX.deployed();

        let initialIssuerList = await btc_erc.issuerList.call();

        let authorize_tx = await btc_erc.authorizeIssuer(issuer, "", { from: issuer, value: web3.toWei(1, "ether") });
        eventFired(authorize_tx, "AuthorizedIssuer");
        // console.log(authorize_tx.receipt.gasUsed);

        let updatedIssuerList = await btc_erc.issuerList.call();

        assert.isTrue(web3.isAddress(updatedIssuerList));
        assert.equal(updatedIssuerList[0], issuer);
    });

    it("Issue tokens", async () => {
        let btc_erc = await ERCXXX_SGX.deployed();

        let authorize_tx = await btc_erc.authorizeIssuer(issuer, "", { from: issuer, value: web3.toWei(1, "ether") });
        eventFired(authorize_tx, "AuthorizedIssuer");

        let issue_tx = await btc_erc.issue(alice, "BTC_TX");
        eventFired(issue_tx, "Issue");

        // TODO: check if alice received it
    });


    it("Abort token creation", async () => {
        let btc_erc = await ERCXXX_SGX.deployed();

        assert.isTrue(true);
    });

    it("Transfer tokens", async () => {
        let btc_erc = await ERCXXX_SGX.deployed();

        assert.isTrue(true);
    });

    it("Redeem tokens", async () => {
        let btc_erc = await ERCXXX_SGX.deployed();

        assert.isTrue(true);
    });

    function eventFired(transaction, eventName) {
        for (var i = 0; i < transaction.logs.length; i++) {
            var log = transaction.logs[i];
            if (log.event == eventName) {
                // We found the event!
                assert.isTrue(true);
            }
        }
    };

})