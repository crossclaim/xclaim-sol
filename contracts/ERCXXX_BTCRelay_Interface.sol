pragma solidity ^0.4.24;

import "./ERCXXX_Interface.sol";
import "./ERCXXX_Tribunal_Interface.sol";

/**
* ERCXXX using BTCRelay Interface
*/
contract ERCXXX_BTCRelay_Interface is ERCXXX_Interface, ERCXXX_Tribunal_Interface {

    // #####################
    // CONTRACT VARIABLES
    // #####################

    /**
    * Address of the relay contract for the backed cryptocurrency
    */
    address public relayContract;


    // #####################
    // MODIFIERS
    // #####################

    // #####################
    // FUNCTIONS
    // #####################

    /**
     * Replaces existing relay contract
     * @param newRelay - address of new relay
     * @param data - [OPTIONAL] data
     *
     * ASSERT: only callable by contract owner / maintainer
     *
     * CAUTION: evaluate advantages vs risks of this functionality
     */
    function replaceRelay(address newRelay, bytes data);

    // #####################
    // HELPER FUNCTIONS
    // #####################

    // #####################
    // EVENTS
    // #####################

    /**
   * Replace Relay revent:
   * @param oldRelay - ETH address of the replaced relay
   * @param newRelay - ETH address of the new relay
   * @param data - data, contains evtl. necessary data
   */
    event REPLACE_RELAY(address indexed oldRelay, address newRelay, bytes data);

}
