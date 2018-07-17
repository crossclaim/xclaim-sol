pragma solidity ^0.4.11;

import "./ERCXXX_interface.sol";

contract AbstractERCXXX is ERCXXXInterface {

    /**
    * Denotes the maximum supply of the backing cryptocurrency.
    */
    uint public maxSupply;

    /**
    * Total supply that can be issued by this contract.
    * Of only once instance is to be used, set contractSupply = maxSupply
    */
    uint public contractSupply;

    /**
    * Duration of the contest period, during which the issuing process can be aborted (requires fraud proof)
    * Measured in Ethereum blocks. Optional: add minimum seconds duration as fallback (threat: timestamp tampering)
    */
    uint public contestationPeriod;

    /**
    * Duration of the grace period, until which the Issuer must have sent the burned tokens to the redeemer d
    * Measured in Ethereum blocks. Optional: add maximum seconds duration as fallback (threat: timestamp tampering)
    */
    uint public graceRedeemPeriod;

    /**
   * List of trusted relayers / relayer contracts.
   */
    mapping(address => uint) issuers;

    /**
    * List of trusted SGX relayers / relayer contracts.
    */
    mapping(address => uint) relayers;

    /**
    * Mapping of user address to token UTXO.
    * A UTXO has the following (imaginary JSON) format:
    * address : {
    *   "ID": uint : {
    *       "value": uint,
    *       "status": string/enum,
    *       "createdOn": uint,
    *       "redeemedOn": uint
    *   },
    *   ...
    * }
    *
    */
    mapping(address => uint) balances;
    // TODO: can we combine the following properties into a single list of objects efficiently, without running risk of OUT-OF-GAS?
    // Mapping utxoID - value
    mapping(uint => uint) values;
    // Mapping utxoID - token state (ISSUED, TRADEABLE, REDEEMED)
    mapping(uint => uint) states;
    // Mapping utxoID - token creation date
    mapping(uint => uint) createdOn;
    // Mappint utxoID - token redeem date
    mapping(uint => uint) redeemedOn;


    // TODO: add methods from interface

}
