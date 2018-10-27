var ERC20 = artifacts.require('./impl/ERC20.sol');

module.exports = function (deployer) {
    deployer.deploy(ERC20);
};
