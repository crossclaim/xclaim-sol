module.exports = {
    eventFired: function (transaction, eventName) {
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
    },
    convertToUsd: function (gasCost) {
        // gas price conversion
        const gas_price = web3.toWei(5, "gwei");
        const eth_usd = 409; // USD

        return gasCost * web3.fromWei(gas_price, "ether") * eth_usd;
    }
};
