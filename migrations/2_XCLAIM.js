var XCLAIM = artifacts.require("./XCLAIM.sol");
var MockBTCRelay = artifacts.require("./tests/")
var btcrelay_config = require('../btcrelay-config');

module.exports = function (deployer, network) {
    if (network == "development") {
        let btcrelay = await deployer.deploy(MockBTCRelay);
        deployer.deploy(XCLAIM, "XCLAIM-BTC-ETH", "XBTH", 1, btcrelay.address);
    } else if (network == "ropsten") {
        deployer.deploy(XCLAIM, "XCLAIM-BTC-ETH", "XBTH", 1, btcrelay_config.networks.ropsten.address);
    } else if (network == "main") {
        deployer.deploy(XCLAIM, "XCLAIM-BTC-ETH", "XBTH", 1, btcrelay_config.networks.main.address);
    }
};
