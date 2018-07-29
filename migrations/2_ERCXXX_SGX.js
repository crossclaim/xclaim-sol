var ERCXXX_SGX = artifacts.require("./impl/ERCXXX_SGX.sol");

module.exports = function (deployer) {
    deployer.deploy(ERCXXX_SGX, "BTC-ERC", "BTH", 1);
};
