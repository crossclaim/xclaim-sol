/**
 * Copyright (C) 2019 Alexei Zamyatin and Dominik Harz
 * 
 * This file is part of XCLAIM.
 * 
 * XCLAIM is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * XCLAIM is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with XCLAIM.  If not, see <http://www.gnu.org/licenses/>.
 */

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
