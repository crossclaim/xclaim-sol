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
    
    function setEthtoBtcConversion(uint256 rate) public returns (bool);

    function authorizeIssuer(address payable toRegister) public payable returns (bool);
    
    function revokeIssuer(address toUnlist) private returns (bool);

    function authorizeRelayer(address toRegister) public returns (bool);

    function revokeRelayer(address toUnlist) public returns (bool);

    event AuthorizedIssuer(address indexed issuer, uint collateral);

    event RevokedIssuer(address indexed issuer);

    event AuthorizedRelayer(address indexed relayer);

    event RevokedRelayer(address indexed relayer);

    // ---------------------
    // ISSUE
    // ---------------------

    function registerIssue(uint256 amount, bytes memory btcAddress) public payable returns (bool); 

    function issueToken(address receiver, uint256 amount, bytes memory data) public returns (bool);

    event RegisterIssue(address indexed sender, uint256 value, uint256 timelock);

    event IssueToken(address indexed issuer, address indexed receiver, uint value, bytes data);

    event AbortIssue(address indexed issuer, address indexed receiver, uint value, bytes data);

    // ---------------------
    // SWAP
    // ---------------------
    function offerTrade(uint256 tokenAmount, uint256 ethAmount, address payable ethParty) public returns (bool);

    function acceptTrade(uint256 offerId) payable public returns (bool);
    
    event NewTradeOffer(uint256 id, address indexed tokenParty, uint256 tokenAmount, address indexed ethParty, uint256 ethAmount);

    event AcceptTrade(uint256 transferOfferId, address indexed tokenParty, uint256 tokenAmount, address indexed ethParty, uint256 ethAmount);

    // ---------------------
    // REDEEM

    // ---------------------

    function requestRedeem(address payable redeemer, uint256 amount, bytes memory data) public returns (bool);

    function confirmRedeem(address payable redeemer, uint256 id, bytes memory data) public returns (bool);

    event RequestRedeem(address indexed redeemer, address indexed issuer, uint value, bytes data, uint id);

    event ConfirmRedeem(address indexed redeemer, uint256 id);

    event Reimburse(address indexed redeemer, address indexed issuer, uint value);

    // ---------------------
    // REPLACE
    // ---------------------
    function requestReplace() public returns (bool);

    function lockCol() public payable returns (bool);

    function replace(bytes memory data) public returns (bool);

    function abortReplace() public returns (bool);

    event RequestReplace(address indexed issuer, uint256 amount, uint256 timelock);

    event LockReplace(address indexed candidate, uint256 amount);

    event ExecuteReplace(address indexed new_issuer, uint256 amount);

    event AbortReplace(address indexed candidate, uint256 amount);
}