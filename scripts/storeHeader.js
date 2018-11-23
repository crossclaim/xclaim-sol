var config = require('./btcrelay-config');
var helpers = require('./helpers');

module.exports = function (callback) {

    var address;
    address = config.networks.development.address;

    console.log("Storing BTC headers in btc relay at ", address);

    var contract = web3.eth.contract(helpers.getAbi());
    var btcrelay = contract.at(address);

    var headers = [
        "0100000050120119172a610421a6c3011dd330d9df07b63616c2cc1f1cd00200000000006657a9252aacd5c0b2940996ecff952228c3067cc38d4885efb5a4ac4247e9f337221b4d4c86041b0f2b5710",
        "0100000006e533fd1ada86391f3f6c343204b0d278d4aaec1c0b20aa27ba0300000000006abbb3eb3d733a9fe18967fd7d4c117e4ccbbac5bec4d910d900b3ae0793e77f54241b4d4c86041b4089cc9b",
        "0100000090f0a9f110702f808219ebea1173056042a714bad51b916cb6800000000000005275289558f51c9966699404ae2294730c3c9f9bda53523ce50e9b95e558da2fdb261b4d4c86041b1ab1bf93",
        "01000000aff7e0c7dc29d227480c2aa79521419640a161023b51cdb28a3b0100000000003779fc09d638c4c6da0840c41fa625a90b72b125015fd0273f706d61f3be175faa271b4d4c86041b142dca82",
        "01000000e1c5ba3a6817d53738409f5e7229ffd098d481147b002941a7a002000000000077ed2af87aa4f9f450f8dbd15284720c3fd96f565a13c9de42a3c1440b7fc6a50e281b4d4c86041b08aecda2",
        "0100000079cda856b143d9db2c1caff01d1aecc8630d30625d10e8b4b8b0000000000000b50cc069d6a3e33e3ff84a5c41d9d3febe7c770fdcc96b2c3ff60abe184f196367291b4d4c86041b8fa45d63",
        "0100000045dc58743362fe8d8898a7506faa816baed7d391c9bc0b13b0da00000000000021728a2f4f975cc801cb3c672747f1ead8a946b2702b7bd52f7b86dd1aa0c975c02a1b4d4c86041b7b47546d"
    ]

    addHeader = async (header) => {
        let result = await btcrelay.storeBlockHeader(header, {from: web3.eth.accounts[0]});
        if (result != 0) {
            console.log("Stored header ", header);
            // console.log(web3.eth.getTransactionReceipt(result));
        } else {
            console.log("error storing header ", header);
        }
    }

    for (var i = 0; i < headers.length ; i++) {
        addHeader(headers[i]);
    }

    console.log("Added headers");

    return callback();
}