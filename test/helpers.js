module.exports = {
    convertToUsd: function (gasCost) {
        // gas price conversion
        const gas_price = web3.utils.toWei(9, "gwei");
        const eth_usd = 106; // USD

        return gasCost * web3.utils.fromWei(gas_price, "ether") * eth_usd;
    },
    generateBlocksGanache: function(number) {
        return new Promise((resolve, reject) => {
        // ganache uses evm_mine method to generate new blocks
            for (var i = 0; i < number; i++) {
                web3.currentProvider.send({
                    jsonrpc: "2.0",
                    method: "evm_mine",
                    id: 123
                    }, (err, result) => {
                        if (err) { return reject(err); }
                        const newBlockHash = web3.eth.getBlock('latest').hash;
            
                        return resolve(newBlockHash)
                    });
            }
        });
    }
};
