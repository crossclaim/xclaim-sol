pragma solidity ^0.4.11;

contract ERCXXXInterface {

    // #####################
    // CONTRACT VARIABLES
    // #####################

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
    * Duration of the contest period - contract will only consider transactions with sufficient confirmations as
    * valid.
    * Optional: add minimum seconds duration as fallback (threat: timestamp tampering)
    */
    uint public contestationPeriod;

    /**
    * Duration of the grace period, until which the Issuer must have sent the burned tokens to the redeemer d
    * Measured in Ethereum blocks. Optional: add maximum seconds duration as fallback (threat: timestamp tampering)
    */
    uint public graceRedeemPeriod;

    /**
    * Collateral amounts for relayers, issuers and accusations
    */
    uint public relayerCollateral;
    uint public issuerCollateral;
    uint public accusationCollateral;

    /**
    * List of issuers
    */
    mapping(address => uint) issuers;

    /**
    * List of trusted SGX relayers
    */
    mapping(address => uint) relayers;

    /**
    * List of user balances.
    */
    mapping(address => uint) balances;

    /**
    * Struct containing information on a redeem request
    */
    struct RedeemRequest{
        address redeemer;
        uint value;
        uint redeemTime;
    }

    /**
    * List of pending redeem requests
    */
    mapping(uint => RedeemRequest) redeemRequests;

    /**
    * List of accusations of failed redeems
    */
    mapping(uint => uint) accusations;


    // #####################
    // MODIFIERS
    // #####################

    // #####################
    // FUNCTIONS
    // #####################


    /**
    * Registers a new relayer
    * @toRegister - address to be registered
    * @data - [OPTIONAL] data, contains any necessary data for validating the relayer
    *
    * ASSERT: sufficient collateral provided
    */
    function registerRelayer(address toRegister, byte data)


    /**
    * Registers a new issuer
    * @toRegister - address to be registered
    * @data - [OPTIONAL] data, contains issuers address in the backed cryptocurrency and
    *         any other necessary info for validating the issuer
    *
    * ASSERT: sufficient collateral provided
    */
    function registerIssuer(address toRegister, byte data)

    /**
    * Issues new units of cryptocurrency-backed token.
    * @receiver - ETH address of the receiver, as provided in the 'lock' transaction in the native native currency
    * @id - id of the token struct to be spent
    * @data - data, contains 'lock' transaction [OPTIONAL?]
    * TODO: decide if data this is required. We probably only need the txid
    *
    * ASSERT: msg.sender in relayer list, abort otherwise.
    */
    function issue(address receiver, bytes data);

    /**
    * Transfers ownership of tokens to another user. Allows to potentially lock the funds with another issuer.
    * @sender - sender address
    * @receiver - receiver address
    * @id - id of the token struct to be transferred
    * @date - data, contains the new 'lock' transaction
    *
    * ASSERT:
    * -) Sender actually owns the specified tokens.
    *
    * TODO: optional checks:
    * -) is the first 'lock' TX still unspent. Will require call to relay.
    * -) does this tx actually spend from the first 'lock' tx correctly. Will require call to relay.
    * -) is the transferred amount high enough to cover native tx fees. Will require call to relay.
    */
    function transfer(address sender, address receiver, bytes data);

    /**
    * Initiates the redeeming of backed-tokens in the native cryptocurrency. Redeemed tokens are 'burned' in the process.
    * @redeemer - redeemer address
    * @id - id of the token struct to be redeemed (and hence burned)
    * @date - data, contains the 'redeem' transaction to be signed by the issuer
    *
    * ASSERT:
    * -) redeemer actually owns the given amount of tokens (including transaction fees in the native blockchain)
    *
    * TODO: optional: add checks - is the first 'lock' TX still unspent and does this tx actually spend from the first 'lock' tx correctly. Will require call to relay.
    */
    function redeem(address redeemer,  bytes data);

    /**
    * Accuses the issuer of not releasing the locked funds to the redeemer, despite the corresponding tokens having
    * been burned.
    * @redeemer - redeemer address
    * @id - id of the token struct which was supposed to be redeemed (issue of dispute)
    *
    * ASSERT: user has provided sufficient collateral.
    */
    function accuse(uint id);

    /**
    * Issuer (or any user on behalf of the issuer)
    *
    * ASSERT: callable only by issuers
    */
    function rebut(uint id, byte data);


    // #####################
    // HELPER FUNCTIONS
    // #####################

    /**
    * Returns the balance of user associated with the provided address
    * @who - inquired address
    */
    function balanceOf(address who) constant returns (uint);


    // #####################
    // EVENTS
    // #####################

    /**
    * Issue event:
    * @issuer - ETH address of the issuer
    * @receiver - ETH address of the receiver, as provided in the 'lock' transaction in the native native currency
    * @value - number of issuer tokens
    * @data - data, contains 'lock' transaction
    */
    event Issue(address indexed issuer, address indexed receiver, uint value, bytes data);

    /**
    * Transfer event:
    * @sender - ETH address of the sender
    * @receiver - ETH address of the receiver
    * @value - transferred value
    * @data - data, contains new 'lock' transaction
    */
    event Transfer(address indexed sender, address indexed receiver, uint value, bytes data);

    /**
    * Redeem event:
    * @redeemer - ETH address of the redeemer
    * @issuer - ETH address of the issuer
    * @value - number of tokens to be redeemed (and hence burned)
    * @data - data, contains 'redeem' transaction (to be signed by the issuer)
    */
    event Redeem(address indexed redeemer, address indexed issuer, uint value, bytes data);

}
