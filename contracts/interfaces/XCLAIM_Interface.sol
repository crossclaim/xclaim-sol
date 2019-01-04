pragma solidity ^0.5.0;


import "./ERC20_Interface.sol";

/**
* Base ERCXXX Interface
*/
contract XCLAIM_Interface is ERC20_Interface {

    // #####################
    // CONTRACT VARIABLES
    // #####################

    function name() public view returns (string memory);
    function symbol() public view returns (string memory);
    function granularity() public view returns (uint256);
    function issuer() public view returns(address);
    function relayer() public view returns (address);
    function pendingRedeemRequests() public view returns(uint256[] memory);

    // #####################
    // FUNCTIONS
    // #####################

    // ---------------------
    // SETUP
    // ---------------------
    function getEthtoBtcConversion() public returns (uint256);
    function setEthtoBtcConversion(uint256 rate) public;

    function authorizeIssuer(address toRegister) public payable;
    function revokeIssuer(address toUnlist) private;

    function authorizeRelayer(address toRegister) public;
    function revokeRelayer(address toUnlist) public;

    // ---------------------
    // ISSUE
    // ---------------------

    function registerIssue(uint256 amount, bytes memory btcAddress) public payable; 

    function issueCol(address receiver, uint256 amount, bytes memory data) public;

    // ---------------------
    // SWAP
    // ---------------------
    function offerTrade(uint256 tokenAmount, uint256 ethAmount, address ethParty) public;

    function acceptTrade(uint256 offerId) payable public;

    // ---------------------
    // REDEEM
    // ---------------------

    function redeem(address redeemer, uint256 amount, bytes memory data) public;

    function redeemConfirm(address redeemer, uint256 id, bytes memory data) public;

    function reimburse(address redeemer, uint256 id, bytes memory data) public;

    // ---------------------
    // REPLACE
    // ---------------------
    function requestReplace() public;

    function lockCol() public payable;

    function replace(bytes memory data) public;

    function abortReplace() public;


    // #####################
    // EVENTS
    // #####################

    /**
   * Register Issue revent:
   * @param issuer - ETH address of the newly registered/unlisted issuer
   * @param collateral - provided collateral
   * data - data, contains evtl. necessary data (e.g., lock transaction for native currency collateral)
   */
    event AuthorizedIssuer(address indexed issuer, uint collateral);

    event RevokedIssuer(address indexed issuer);

    event AuthorizedRelayer(address indexed relayer);

    event RevokedRelayer(address indexed relayer);

    /**
    * Transfer event:
    * @param sender - ETH address of the sender
    * @param receiver - ETH address of the receiver
    * @param value - transferred value
    */
    event Transfer(address indexed sender, address indexed receiver, uint value);

    event NewTradeOffer(uint256 id, address indexed tokenParty, uint256 tokenAmount, address indexed ethParty, uint256 ethAmount);
    /**
    * Trade event:
    * @param transferOfferId - Index of transfer offer completed
    * @param tokenParty - ETH address of the party exchanging tokens
    * @param tokenAmount - amount in tokens transferred
    * @param ethParty - ETH address of the party exchanging Ether
    * @param ethAmount - amount in Ether transferred
    */
    event Trade(uint256 transferOfferId, address indexed tokenParty, uint256 tokenAmount, address indexed ethParty, uint256 ethAmount);

    /**
    * Redeem event:
    * @param redeemer - ETH address of the redeemer
    * @param issuer - ETH address of the issuer
    * @param value - number of tokens to be redeemed (and hence burned)
    * @param data - data, contains 'redeem' transaction (to be signed by the issuer)
    */
    event Redeem(address indexed redeemer, address indexed issuer, uint value, bytes data, uint id);

    event RedeemSuccess(address indexed redeemer, uint256 id);

    event Reimburse(address indexed redeemer, address indexed issuer, uint value);

    event Replace(address indexed new_issuer, uint256 amount);

    event RequestReplace(address indexed issuer, uint256 amount, uint256 timelock);

    event LockReplace(address indexed candidate, uint256 amount);

    event AbortReplace(address indexed candidate, uint256 amount);
}