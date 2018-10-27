pragma solidity ^0.4.24;

/// @title ERCXXX ReferenceToken Contract
/// @author Dominik Harz, Panayiotis Panayiotou
/// @dev This token contract's goal is to give an example implementation
///  of ERCXXX with ERC20 compatibility.
///  This contract does not define any standard, but can be taken as a reference
///  implementation in case of any ambiguity into the standard
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../ERCXXX_Base_Interface.sol";
import "./ERC20.sol";

contract ERCXXX_Base is ERCXXX_Base_Interface, ERC20 {
    using SafeMath for uint256;

    // #####################
    // CONTRACT VARIABLES
    // #####################

    // general
    string public _name;
    string public _symbol;
    uint256 public _granularity;

    // issuer
    address public _issuer;
    uint256 public _issuerTokenSupply; // token supply per issuer
    uint256 public _issuerCommitedTokens; // token commited by issuer
    uint256 public _issuerCollateral;
    address public _issuerCandidate;
    bool public _issuerReplace;
    uint256 public _issuerReplaceTimelock;

    // relayer
    address public _relayer;

    // time
    uint256 public _contestationPeriod;
    uint256 public _graceRedeemPeriod;
    
    // collateral
    uint256 public _minimumCollateralIssuer;
    uint256 public _minimumCollateralUser;
    
    // conversion rate
    uint256 public _conversionRateBTCETH; // 10*5 granularity?
    
    // issue - collateral
    struct CommitedCollateral {
        uint256 commitTimeLimit;
        uint256 collateral;
    }
    mapping(address => CommitedCollateral) public _userCommitedCollateral;
    
    // issue - HTLC
    struct HTLC {
        uint256 locktime;
        uint256 amount;
        bytes32 script;
        bytes32 siganture;
        bytes tx_id;
    }
    mapping(address => HTLC) public _userHTLC;
    
    // trade
    struct TradeOffer {
        address tokenParty;
        address ethParty;
        uint256 tokenAmount;
        uint256 ethAmount;
        bool completed;
    }
    mapping(uint256 => TradeOffer) public _tradeOfferStore;
    uint256 public _tradeOfferId; //todo: do we need this?

    // redeem
    struct RedeemRequest {
        address redeemer;
        uint value;
        uint redeemTime;
    }
    mapping(uint => RedeemRequest) public _redeemRequestMapping;
    uint256[] public _redeemRequestList;
    uint256 public _redeemRequestId;

    constructor (string myname, string mysymbol, uint256 mygranularity) public {
        _name = myname;
        _symbol = mysymbol;
        _granularity = mygranularity;
        _totalSupply = 0;
        // issuer
        _issuerTokenSupply = 0;
        _issuerCommitedTokens = 0;
        // time
        _contestationPeriod = 1 seconds;
        _graceRedeemPeriod = 1 seconds;
        // collateral
        _minimumCollateralUser = 1 wei;
        // conversion rate
        _conversionRateBTCETH = 2 * 10^5; // equals 1 BTC = 2 ETH
        // init id counters
        _tradeOfferId = 0;
        _redeemRequestId = 0;
    }

    function name() public view returns (string) {
        return _name;
    }

    function symbol() public view returns (string) {
        return _symbol;
    }

    function granularity() public view returns (uint256) {
        return _granularity;
    }

    // note: single issuer case
    function issuer() public view returns(address) {
        return _issuer;
    }

    function pendingRedeemRequests() public view returns(uint256[]) {
        return _redeemRequestList;
    }


    // #####################
    // FUNCTIONS
    // #####################

    // ---------------------
    // SETUP
    // ---------------------
    function getEthtoBtcConversion() public returns (uint256) {
        return _conversionRateBTCETH;
    }

    function setEthtoBtcConversion(uint256 rate) public {
        // todo: require maximum fluctuation
        // todo: only from "trusted" oracles
        _conversionRateBTCETH = rate;
    }

    // Issuers
    function authorizeIssuer(address toRegister) public payable {
        require(msg.value >= _minimumCollateralIssuer, "Collateral too low");
        require(_issuer == address(0), "Issuer already set");

        _issuer = toRegister;
        /* Total amount of tokens that issuer can issue */
        _issuerTokenSupply = _convertEthToBtc(msg.value);
        _issuerCollateral = msg.value;
        _issuerReplace = false;

        emit AuthorizedIssuer(toRegister, msg.value);
    }

    function revokeIssuer(address toUnlist) private {
        require(msg.sender == _issuer, "Can only be invoked by current issuer");

        _issuer = address(0);
        if (_issuerCollateral > 0) {
            _issuer.transfer(_issuerCollateral);
        }

        emit RevokedIssuer(toUnlist);
    }

    // Relayers
    function authorizeRelayer(address toRegister) public {
        // TODO: Implement SGX or BTC Relay
        emit AuthorizedRelayer(toRegister);
    }

    function revokeRelayer(address toUnlist) public {
        _relayer = address(0);
        emit RevokedRelayer(_relayer);
    }

    // ---------------------
    // ISSUE
    // ---------------------

    function registerIssue(uint256 amount) public payable {
        require(msg.value >= _minimumCollateralUser);
        /* If there is not enough tokens, return back the collateral */
        // Not required in case of centralised SGX issuer
        // if (issuerTokenSupply < amount + issuerCommitedTokens) { // TODO might need a 3rd variable here
        //     msg.sender.transfer(msg.value);
        //     return;
        // }
        uint8 issueType = 0;
        if (_issuerTokenSupply < amount + _issuerCommitedTokens) { // TODO might need a 3rd variable here
            msg.sender.transfer(msg.value);
            return;
        }

        uint256 timelock = now + 1 seconds;
        _issuerCommitedTokens += amount;
        _userCommitedCollateral[msg.sender] = CommitedCollateral(timelock, amount);
        
        // TODO: need to lock issuers collateral
        
        // emit event
        emit RegisterIssue(msg.sender, amount, timelock, issueType);
    }

    // Individual implementation
    function issueCol(address receiver, uint256 amount, bytes lock_tx) public {
        // TODO: Implement

        emit AbortIssue(msg.sender, receiver, amount, lock_tx);
    }

    function registerHTLC(uint256 timelock, uint256 amount, bytes32 script, bytes32 signature, bytes data) public {
        _userHTLC[msg.sender] = HTLC(timelock, amount, script, signature, data);
        uint8 issueType = 1;

        emit RegisterIssue(msg.sender, amount, timelock, issueType);
    }

    // Individual implementation
    function issueHTLC(address receiver, uint256 amount, bytes lock_tx) public {
        // TODO: Implement
        
        emit AbortIssue(msg.sender, receiver, amount, lock_tx);
    }

    // ---------------------
    // TRADE
    // ---------------------

    function offerTrade(uint256 tokenAmount, uint256 ethAmount, address ethParty) public {
        require(_balances[msg.sender] >= tokenAmount, "Insufficient balance");

        _balances[msg.sender] -= tokenAmount;
        _tradeOfferStore[_tradeOfferId] = TradeOffer(msg.sender, ethParty, tokenAmount, ethAmount, false);
        
        _tradeOfferId += 1;
        emit NewTradeOffer(_tradeOfferId, msg.sender, tokenAmount, ethParty, ethAmount);
    }

    function acceptTrade(uint256 offerId) payable public {
        /* Verify offer exists and the provided ether is enough */
        require(_tradeOfferStore[offerId].completed == false, "Trade completed");
        require(msg.value >= _tradeOfferStore[offerId].ethAmount, "Insufficient amount");

        /* Complete the offer */
        _tradeOfferStore[offerId].completed = true;
        _balances[msg.sender] = _balances[msg.sender] + _tradeOfferStore[offerId].tokenAmount;
        _tradeOfferStore[offerId].tokenParty.transfer(msg.value);

        emit Trade(offerId, _tradeOfferStore[offerId].tokenParty, _tradeOfferStore[offerId].tokenAmount, msg.sender, msg.value);
    }

    // ---------------------
    // REDEEM
    // ---------------------

    // Individual implementation
    function redeem(address redeemer, uint256 amount, bytes data) public {
        emit Redeem(redeemer, msg.sender, amount, data, 0);
    }

    // ---------------------
    // REPLACE
    // ---------------------

    function requestReplace() public {
        require(msg.sender == _issuer);
        require(!_issuerReplace);

        _issuerReplace = true;
        _issuerReplaceTimelock = now + 1 seconds;

        emit RequestReplace(_issuer, _issuerCollateral);
    }

    function lockCol() public payable {
        require(_issuerReplace);
        require(msg.sender != _issuer);
        require(msg.value >= _issuerCollateral);

        _issuerCandidate = msg.sender;

        emit LockReplace(_issuerCandidate, msg.value);
    }

    // Idividual implementation
    // function replace(bytes data)

    function abortReplace() public {
        require(_issuerReplace);
        require(msg.sender == _issuerCandidate);
        require(_issuerReplaceTimelock < now);

        _issuerReplace = false;

        _issuerCandidate.transfer(_issuerCollateral);

        emit AbortReplace(_issuerCandidate, _issuerCollateral);
    }

    // ---------------------
    // HELPERS
    // ---------------------

    function _convertEthToBtc(uint256 eth) private view returns(uint256) {
        /* TODO use a contract that uses middleware to get the conversion rate */
        return eth * _conversionRateBTCETH;
    }
}