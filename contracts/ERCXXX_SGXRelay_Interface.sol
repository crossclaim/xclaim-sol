pragma solidity ^0.4.24;

import "./ERCXXX_Base_Interface.sol";

/**
* ERCXXX using SGX relays Interface
*/
contract ERCXXX_SGXRelay_Interface is ERCXXX_Base_Interface {

    // #####################
    // CONTRACT VARIABLES
    // #####################


    /**
    * List of trusted SGX relayers
    */
    // mapping(address => uint) relayers;


    // #####################
    // MODIFIERS
    // #####################

    // #####################
    // FUNCTIONS
    // #####################

    function pendingRedeemRequests() public view returns(uint256[]);

    /**
    * Registers / unlists a new relayer
    * @param toRegister - address to be registered/unlisted
    * @param data - [OPTIONAL] data, contains any necessary data for validating the relayer
    *
    * ASSERT: sufficient collateral provided
    */
    function authorizeRelayer(address toRegister, bytes data) public;
    function revokeRelayer(address toUnlist, bytes data) public;


    event RedeemSuccess(address indexed redeemer, uint256 id);
    /**
   * Register/Unlist Relayer revent:
   * @param relayer - ETH address of the newly registered/unlisted relayer
   * collateral - provided collateral // not needed
   * @param data - data, contains evtl. necessary data (e.g., lock transaction for native currency collateral)
   */
    event AuthorizeRelayer(address indexed relayer, bytes data);
    event RevokeRelayer(address indexed relayer, bytes data);

}
