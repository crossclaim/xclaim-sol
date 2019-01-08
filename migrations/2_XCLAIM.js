var XCLAIM = artifacts.require("./XCLAIM.sol");
var MockBTCRelay = artifacts.require("./tests/MockBTCRelay.sol")
var btcrelay_config = require('../btcrelay-config');

module.exports = function (deployer, network) {
    if (network == "development") {
        deployer.deploy(MockBTCRelay).then(function () {
            return deployer.deploy(XCLAIM, "XCLAIM-BTC-ETH", "XBTH", 1, MockBTCRelay.address);
        });
    } else if (network == "ropsten") {
        deployer.deploy(XCLAIM, "XCLAIM-BTC-ETH", "XBTH", 1, btcrelay_config.networks.ropsten.address);
    } else if (network == "main") {
        deployer.deploy(XCLAIM, "XCLAIM-BTC-ETH", "XBTH", 1, btcrelay_config.networks.main.address);
    }
};
