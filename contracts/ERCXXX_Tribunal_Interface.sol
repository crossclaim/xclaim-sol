pragma solidity ^0.4.24;

/**
* Base ERCXXX Tribunal Interface
*/
contract ERCXXX_Tribunal_Interface {

    // #####################
    // CONTRACT VARIABLES
    // #####################

    // #####################
    // MODIFIERS
    // #####################

    // #####################
    // FUNCTIONS
    // #####################

    /**
    * Accuses the issuer of not releasing the locked funds to the redeemer, despite the corresponding tokens having
    * been burned.
    * @param redeemer - redeemer address
    * @param id - id of the token struct which was supposed to be redeemed (issue of dispute)
    *
    * ASSERT: user has provided sufficient collateral.
    */
    function accuse(address redeemer, uint id) public;

    /**
    * Issuer (or any user on behalf of the issuer)
    *
    * ASSERT: callable only by issuers
    */
    function rebut(uint id, bytes data) public;


    // #####################
    // HELPER FUNCTIONS
    // #####################


    // #####################
    // EVENTS
    // #####################

    /**
    * Events related to the tribunal procedures
    * @param issuer - ETH address of the accused issuer
    * @param accuser - ETH address of the accuser
    * @param value - value of disputed tokens
    * @param data - data, contains necessary data on accusation and rebuttal (fraud proofs)
    */
    event ACCUSE(address indexed issuer, address indexed accuser, uint value, bytes data);
    event REBUT(address indexed sender, address indexed accuser, uint value, bytes data);
    event ACCUSATION_WINS(address indexed issuer, address indexed accuser, uint value, byte data);
    event REBUTTAL_WINS(address indexed issuer, address indexed accuser, uint value, byte data);

}
