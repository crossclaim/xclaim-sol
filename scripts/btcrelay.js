var fs = require("fs");

module.exports = function (callback) {
    const btcrelay_abi = fs.readFileSync("./contracts/btcrelay-serpent/btcrelay-abi.json");
    const btcrelay_bytes = fs.readFileSync("./contracts/btcrelay-serpent/btcrelay-bytecode", "utf8");

    

    deploy = () => {
        console.log("Trying to deploy");
        // const accounts = await web3.eth.getAccounts();
        const accounts = web3.eth.accounts;
        console.log('Attempting to deploy from account ',accounts[0]);
        var contract = web3.eth.contract(JSON.parse(btcrelay_abi))
        var address;
        contract.new({ 
            data:'0x'+btcrelay_bytes, 
            from:accounts[0], 
            gas: 3000000 }, function (err, contract) {
                if (!err) {
                    if(!contract.address) {
                        console.log("transaction hash: ", contract.transactionHash);
                        const transaction = web3.eth.getTransactionReceipt(contract.transactionHash);
                        address = transaction.contractAddress;
                        console.log("contract address: ", address);
                    } else {
                        address = contract.address;
                        console.log("contract address: ", address);
                    }
                }
            });
    };
    deploy();
    console.log("BTC Relay deployed");

    return callback ();
}