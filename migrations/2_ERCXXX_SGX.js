var ERCXXX_SGX = artifacts.require("./impl/ERCXXX_SGX.sol");

module.exports = function (deployer) {
    if (network == "development") {
        deployer.deploy(ERCXXX_SGX, "BTC-ERC", "BTH", 1);
    } else {
        // Perform a different step otherwise.
    }
};
