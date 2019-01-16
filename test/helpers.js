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

module.exports = {
    convertToUsd: function (gasCost) {
        // gas price conversion
        const gas_price = web3.utils.toWei(9, "gwei");
        const eth_usd = 106; // USD

        return gasCost * web3.utils.fromWei(gas_price, "ether") * eth_usd;
    },
    generateBlocksGanache: function(number) {
        return new Promise((resolve, reject) => {
        // ganache uses evm_mine method to generate new blocks
            for (var i = 0; i < number; i++) {
                web3.currentProvider.send({
                    jsonrpc: "2.0",
                    method: "evm_mine",
                    id: 123
                    }, (err, result) => {
                        if (err) { return reject(err); }
                        const newBlockHash = web3.eth.getBlock('latest').hash;
            
                        return resolve(newBlockHash)
                    });
            }
        });
    }
};
