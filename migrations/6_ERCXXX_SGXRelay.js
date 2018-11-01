var ERCXXX_SGXRelay = artifacts.require("./impl/ERCXXX_SGXRelay.sol");

module.exports = function (deployer) {
    deployer.deploy(ERCXXX_SGXRelay);
};
