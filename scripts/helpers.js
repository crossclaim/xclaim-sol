var fs = require("fs");

module.exports = {
    getAbi: function () {
        return JSON.parse(fs.readFileSync("./contracts/btcrelay-serpent/btcrelay-abi.json"));
    },
    getBytecode: function () {
        return fs.readFileSync("./contracts/btcrelay-serpent/btcrelay-bytecode", "utf8");
    }
}