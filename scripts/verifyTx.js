var config = require('./btcrelay-config');
var helpers = require('./helpers');

module.exports = function (callback) {

    var address;
    address = config.networks.development.address;

    console.log("Verifying tx in btc relay at ", address);

    var contract = web3.eth.contract(helpers.getAbi());
    var btcrelay = contract.at(address);

    b0 = '0x000000000003ba27aa200b1cecaad478d2b00432346c3f1f3986da1afd33e506';
    b1 = '0x00000000000080b66c911bd5ba14a74260057311eaeb1982802f7010f1a9f090';
    b2 = '0x0000000000013b8ab2cd513b0261a14096412195a72a0c4827d229dcc7e0f7af';
    b3 = '0x000000000002a0a74129007b1481d498d0ff29725e9f403837d517683abac5e1';
    b4 = '0x000000000000b0b8b4e8105d62300d63c8ec1a1df0af1c2cdbd943b156a8cd79';
    b5 = '0x000000000000dab0130bbcc991d3d7ae6b81aa6f50a798888dfe62337458dc45';
    b6 = '0x0000000000009b958a82c10804bd667722799cc3b457bc061cd4b7779110cd60';

    rawTx = '01000000010000000000000000000000000000000000000000000000000000000000000000ffffffff08044c86041b020602ffffffff0100f2052a010000004341041b0e8c2567c12536aa13357b79a073dc4444acb83c4ec7a0e2f99dd7457516c5817242da796924ca4e99947d087fedf9ce467cb9f7c6287078f801df276fdf84ac00000000';
    txHash = '0x8c14f0db3df150123e6f3dbbf30f8b955a8249b62ac1d1ff16284aefa3d06d87';
    txIndex = 0;
    sibling = [];
    sibling[0] = '0xfff2525b8931402dd09222c50775608f75787bd2b87e56995a7bdd30f79702c4';
    sibling[1] = '0x8e30899078ca1813be036a073bbf80b86cdddde1c96e9e9c99e9e3782df4ae49';

    verifyTransaction = async (rawTx, txIndex, sibling, txBlockHash) => {
        var bufferTx = Buffer.from(rawTx, 'hex');
        var Tx = [...bufferTx];

        let gas = await btcrelay.verifyTx.estimateGas(Tx, txIndex, sibling, txBlockHash, {from: web3.eth.accounts[0]});
        console.log(gas);

        let result = await btcrelay.verifyTx.call(Tx, txIndex, sibling, txBlockHash, {from: web3.eth.accounts[0]});
        if (result.toNumber() != 0 ) {
            console.log("SUCCESS verified tx ", rawTx);
            console.log(result.toNumber());
            // console.log(web3.eth.getTransactionReceipt(result));
        } else {
            console.log("FAILED to verify tx ", rawTx);
            console.log(result.toNumber());
        }
    }

    txBlockHash = b0;

    verifyTransaction(rawTx, txIndex, sibling, txBlockHash);


    // txBlockHash = b1;
    // verifyTx(rawTx, txIndex, sibling, txBlockHash);

    return callback();
}