var fs = require("fs");

module.exports = function (callback) {
    var source = fs.readFileSync("./contracts/btcrelay-serpent/btcrelay-abi.json");
    var btcrelay_abi = JSON.parse(source);
    var btcrelay_bytes = fs.readFileSync("./contracts/btcrelay-serpent/btcrelay-bytecode");

    var BTCRelay = web3.eth.contract(btcrelay_abi);

    var contract = BTCRelay.new({from: web3.eth.accounts[0], gas: 7988288, data: btcrelay_bytes});

    // Transaction has entered to geth memory pool
    console.log("Your contract is being deployed in transaction at http://testnet.etherscan.io/tx/" + contract.transactionHash);

    // http://stackoverflow.com/questions/951021/what-is-the-javascript-version-of-sleep
    function sleep(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }
    
    // We need to wait until any miner has included the transaction
    // in a block to get the address of the contract
    async function waitBlock() {
        while (true) {
        let receipt = web3.eth.getTransactionReceipt(contract.transactionHash);
        if (receipt && receipt.contractAddress) {
            console.log("Your contract has been deployed at http://testnet.etherscan.io/address/" + receipt.contractAddress);
            console.log("Note that it might take 30 - 90 sceonds for the block to propagate before it's visible in etherscan.io");
            break;
        }
        console.log("Waiting a mined block to include your contract... currently in block " + web3.eth.blockNumber);
        await sleep(4000);
        }
    }

    return waitBlock;
}