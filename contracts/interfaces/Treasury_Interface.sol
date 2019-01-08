pragma solidity ^0.5.0;

/**
* Base Treasury Interface
*/
contract Treasury_Interface {

    // #####################
    // CONTRACT VARIABLES
    // #####################

    // function name() public view returns (string memory);
    // function symbol() public view returns (string memory);
    // function granularity() public view returns (uint256);
    function issuer() public view returns(address);
    function relayer() public view returns (address);

    // #####################
    // FUNCTIONS
    // #####################

    // ---------------------
    // SETUP
    // ---------------------
    function getEthtoBtcConversion() public returns (uint256);
    
    function setEthtoBtcConversion(uint256 rate) public;

    function authorizeIssuer(address payable toRegister) public payable;
    
    function revokeIssuer(address toUnlist) private;

    function authorizeRelayer(address toRegister) public;

    function revokeRelayer(address toUnlist) public;

    event AuthorizedIssuer(address indexed issuer, uint collateral);

    event RevokedIssuer(address indexed issuer);

    event AuthorizedRelayer(address indexed relayer);

    event RevokedRelayer(address indexed relayer);

    // ---------------------
    // ISSUE
    // ---------------------

    function registerIssue(uint256 amount, bytes memory btcAddress) public payable; 

    function issueToken(address receiver, uint256 amount, bytes memory data) public;

    event RegisterIssue(address indexed sender, uint256 value, uint256 timelock);

    event IssueToken(address indexed issuer, address indexed receiver, uint value, bytes data);

    event AbortIssue(address indexed issuer, address indexed receiver, uint value, bytes data);

    // ---------------------
    // SWAP
    // ---------------------
    function offerTrade(uint256 tokenAmount, uint256 ethAmount, address payable ethParty) public;

    function acceptTrade(uint256 offerId) payable public;
    
    event NewTradeOffer(uint256 id, address indexed tokenParty, uint256 tokenAmount, address indexed ethParty, uint256 ethAmount);

    event Trade(uint256 transferOfferId, address indexed tokenParty, uint256 tokenAmount, address indexed ethParty, uint256 ethAmount);

    // ---------------------
    // REDEEM

    // ---------------------

    function redeem(address payable redeemer, uint256 amount, bytes memory data) public;

    function redeemConfirm(address redeemer, uint256 id, bytes memory data) public;

    function reimburse(address payable redeemer, uint256 id, bytes memory data) public;

    event RequestRedeem(address indexed redeemer, address indexed issuer, uint value, bytes data, uint id);

    event ConfirmRedeem(address indexed redeemer, uint256 id);

    event Reimburse(address indexed redeemer, address indexed issuer, uint value);

    // ---------------------
    // REPLACE
    // ---------------------
    function requestReplace() public;

    function lockCol() public payable;

    function replace(bytes memory data) public;

    function abortReplace() public;

    event RequestReplace(address indexed issuer, uint256 amount, uint256 timelock);

    event LockReplace(address indexed candidate, uint256 amount);

    event ExecuteReplace(address indexed new_issuer, uint256 amount);

    event AbortReplace(address indexed candidate, uint256 amount);
}