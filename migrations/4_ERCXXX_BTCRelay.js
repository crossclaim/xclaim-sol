// var BTCRelay = artifacts.require("./BTCRelay/BTCRelay.sol");
var ERCXXX_BTCRelay = artifacts.require("./impl/ERCXXX_BTCRelay.sol");
var btcrelay_config = require('../scripts/btcrelay-config');

module.exports = function (deployer, network) {
    if (network == "development") {
        deployer.deploy(ERCXXX_BTCRelay, btcrelay_config.networks.development.address);
    } else if (network == "ropsten") {
        // Use existing deployed contracts
    }
};
