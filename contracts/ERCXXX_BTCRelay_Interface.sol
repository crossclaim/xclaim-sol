pragma solidity ^0.4.24;

import "./ERCXXX_Interface.sol";
import "./ERCXXX_Tribunal_Interface.sol";

/**
* ERCXXX using BTCRelay Interface
*/
contract ERCXXX_BTCRelay_Interface is ERCXXX_Interface, ERCXXX_Tribunal_Interface{

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
     * @newRelay - address of new relay
     * @data - [OPTIONAL] data
     *
     * ASSERT: only callable by contract owner / maintainer
     *
     * CAUTION: evaluate advantages vs risks of this functionality
     */
    function replaceRelay(address newRelay, byte data);

    // #####################
    // HELPER FUNCTIONS
    // #####################

    // #####################
    // EVENTS
    // #####################

    /**
   * Replace Relay revent:
   * @oldRelay - ETH address of the replaced relay
   * @newRelay - ETH address of the new relay
   * @data - data, contains evtl. necessary data
   */
    event REPLACE_RELAY(address indexed oldRelay, address newRelay, bytes data);

}
