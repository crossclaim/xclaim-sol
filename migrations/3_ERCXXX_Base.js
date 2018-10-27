var ERCXXX_Base = artifacts.require('./impl/ERCXXX_Base.sol');

module.exports = function (deployer) {
    deployer.deploy(ERCXXX_Base, 'BASE', 'BTH', 1);
};
