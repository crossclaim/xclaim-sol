var fs = require("fs");

module.exports = {
    getAbi: function () {
        return JSON.parse(fs.readFileSync("./contracts/btcrelay-serpent/btcrelay-abi.json"));
    },
    getBytecode: function () {
        return fs.readFileSync("./contracts/btcrelay-serpent/btcrelay-bytecode", "utf8");
    },
    // for some reason this is not recognised as a function?
    getHex: function (hexstring) {
        var buffer = Buffer.from(hexstring, 'hex')[0];
        return [...buffer];
    },
    eventPrint: function (transaction) {
        for (var i = 0; i < transaction.logs.length; i++) {
            var log = transaction.logs[i];
            console.log(log.event);
        }
    },
}