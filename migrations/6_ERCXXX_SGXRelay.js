var ERCXXX_SGXRelay = artifacts.require("./impl/ERCXXX_SGXRelay.sol");

module.exports = function (deployer, network) {
    if (network == "development") {
        deployer.deploy(ERCXXX_SGXRelay);
    } else {
        // Perform a different step otherwise.
    }
    // 
};
