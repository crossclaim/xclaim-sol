// var BTCRelay = artifacts.require("./BTCRelay/BTCRelay.sol");
var ERCXXX_BTCRelay = artifacts.require("./impl/ERCXXX_BTCRelay.sol");

module.exports = function (deployer, network) {
    if (network == "development") {
        deployer.deploy(ERCXXX_BTCRelay, '0x1688b53547407c75d698c51706812dd468f8ad36');
    } else if (network == "ropsten") {
        // Use existing deployed contracts
    }
};
