pragma solidity ^0.4.11;

import "./ERCXXX_Interface.sol";
import "./ERCXXX_Tribunal_Interface.sol";

/**
* ERCXXX using SGX relays Interface
*/
contract ERCXXX_SGXRelay_Interface is ERCXXX_Interface, ERCXXX_Tribunal_Interface {

    // #####################
    // CONTRACT VARIABLES
    // #####################


    /**
    * List of trusted SGX relayers
    */
    mapping(address => uint) relayers;


    // #####################
    // MODIFIERS
    // #####################

    // #####################
    // FUNCTIONS
    // #####################


    /**
    * Registers / unlists a new relayer
    * @toRegister - address to be registered/unlisted
    * @data - [OPTIONAL] data, contains any necessary data for validating the relayer
    *
    * ASSERT: sufficient collateral provided
    */
    function registerRelayer(address toRegister, byte data);
    function unlistRelayer(address toUnlist, byte data);

    /**
   * Register/Unlist Relayer revent:
   * @relayer - ETH address of the newly registered/unlisted relayer
   * @value - provided collateral
   * @data - data, contains evtl. necessary data (e.g., lock transaction for native currency collateral)
   */
    event REGISTER_RELAYER(address indexed relayer, uint collateral, bytes data);
    event UNLIST_RELAYER(address indexed relayer, uint collateral, bytes data);

}
