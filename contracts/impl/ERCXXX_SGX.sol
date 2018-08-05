pragma solidity ^0.4.24;

/// @title ERCXXX ReferenceToken Contract
/// @author Dominik Harz, Panayiotis Panayiotou
/// @dev This token contract's goal is to give an example implementation
///  of ERCXXX with ERC20 compatibility.
///  This contract does not define any standard, but can be taken as a reference
///  implementation in case of any ambiguity into the standard
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../ERCXXX_Base_Interface.sol";


contract ERCXXX_SGX is ERCXXX_Base_Interface {
    using SafeMath for uint256;

    // #####################
    // CONTRACT VARIABLES
    // #####################


    string public name;
    string public symbol;
    uint256 public granularity;
    uint256 public totalSupply;

    uint256 public contestationPeriod;
    uint256 public graceRedeemPeriod;
    /* TODO: work out a value for minimum collateral */
    uint256 public minimumCollateral;
    /* Commitment by user for issuing of tokens */
    uint256 public minimumCollateralCommitment = 1;

    mapping(address => uint) public balances;

    address public issuer;
    // mapping(address => bool) public issuers;
    

    /* The below shall be converted to mappings when multiple issuers are introduced */
    /* Total token supply, depends on provided issuer collateral */
    uint256 issuerTokenSupply;
    /* Total commited tokens, shouldn't exceed the supply */
    uint256 issuerCommitedTokens; // modify on issue and redeem
    struct CommitedCollateral {
        uint256 commitTimeLimit;
        uint256 collateral;
    }
    /* This can be enriched to allow multiple requests per user, but it's not of huge importance at the moment */
    mapping(address => CommitedCollateral) userCommitedCollateral;

    struct TradeOffer {
        address tokenParty;
        address ethParty;
        uint256 tokenAmount;
        uint256 ethAmount;
        bool completed;
    }
    event NewTradeOffer(uint256 id, address indexed tokenParty, uint256 tokenAmount, address indexed ethParty, uint256 ethAmount);
    mapping(uint256 => TradeOffer) tradeOfferStore;
    uint256 tradeOfferId;

    // All events are defined in the interface contract - no need to double it here
    /* Event emitted when a transfer is done */
    // event Transfer(address indexed from, address indexed to, uint256 amount);

    // #####################
    // CONSTRUCTOR
    // #####################
    constructor(string _name, string _symbol, uint256 _granularity) public {
        require(_granularity >= 1);

        name = _name;
        symbol = _symbol;
        granularity = _granularity;
        totalSupply = 0;
        // TODO: value
        contestationPeriod = 1;
        // TODO: value
        graceRedeemPeriod = 1;
        // No collateral for SGX since we fully trust the issuer
        minimumCollateral = 0;
        // Minimum Ether to be commited by user for issuing of tokens
        minimumCollateralCommitment = 1;
        issuerTokenSupply = 0;
        issuerCommitedTokens = 0;
        tradeOfferId = 0;
    }

    // #####################
    // MODIFIERS
    // #####################

    // #####################
    // HELPER FUNCTIONS
    // #####################

    function name() public view returns (string) {
        return name;
    }

    function symbol() public view returns (string) {
        return symbol;
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint) {
        return balances[_owner];
    }

    function granularity() public view returns (uint256) {
        return granularity;
    }

    // #####################
    // FUNCTIONS
    // #####################

    function issuer() public view returns(address) {
        return issuer;
    }

    function authorizeIssuer(address toRegister) public payable {
        require(msg.value >= minimumCollateral);
        /* Allows only 1 Issuer */
        require(issuer == address(0));
        issuer = toRegister;
        /* Total amount of tokens that you can issue */
        issuerTokenSupply = convertEthToBtc(msg.value);
        emit AuthorizedIssuer(toRegister, msg.value);
    }

    function convertEthToBtc(uint256 eth) private pure returns(uint256) {
        /* TODO use a contract that uses middleware to get the conversion rate */
        uint256 conversionRate = 2;
        return eth * conversionRate;
    }

    function revokeIssuer(address toUnlist) private {
        /* TODO add checks on who calls this */
        /* TODO return collateral to issuer */
        issuer = address(0);
        emit RevokedIssuer(toUnlist);
    }

    function requestTokenIssue(uint256 amount) public payable {
        require(msg.value >= minimumCollateralCommitment);
        /* If there is not enough tokens, return back the collateral */
        if (issuerTokenSupply < amount + issuerCommitedTokens) { // TODO might need a 3rd variable here
            msg.sender.transfer(msg.value);
            return;
        }
        uint256 timelock = now + 1 days;
        issuerCommitedTokens += amount;
        userCommitedCollateral[msg.sender] = CommitedCollateral(timelock, amount);
        // emit event
    }

    function issue(address receiver, uint256 amount, bytes data) public {
        /* This method can only be called by an Issuer */
        require(msg.sender == issuer);

        totalSupply += amount;
        balances[receiver] += amount;

        emit Issue(msg.sender, receiver, amount, data);
    }

    /* Call this method to make a transfer offer to another party */
    function offerTrade(uint256 tokenAmount, uint256 ethAmount, address ethParty) public {
        require(balances[msg.sender] >= tokenAmount);
        balances[msg.sender] -= tokenAmount;
        tradeOfferStore[tradeOfferId] = TradeOffer(msg.sender, ethParty, tokenAmount, ethAmount, false);
        emit NewTradeOffer(tradeOfferId, msg.sender, tokenAmount, ethParty, ethAmount);
        tradeOfferId += 1;
    }

    /* Call this method to accept a transfer offer made by another party */
    function acceptTrade(uint256 offerId) payable public {
        /* Verify offer exists and the provided ether is enough */
        require(tradeOfferStore[offerId].completed == false);
        require(msg.value >= tradeOfferStore[offerId].ethAmount);

        /* Complete the offer */
        tradeOfferStore[offerId].completed = true;
        balances[msg.sender] = balances[msg.sender] + tradeOfferStore[offerId].tokenAmount;
        tradeOfferStore[offerId].tokenParty.transfer(msg.value);
        emit Trade(offerId, tradeOfferStore[offerId].tokenParty, tradeOfferStore[offerId].tokenAmount, msg.sender, msg.value);
    }

    function transfer(address sender, address receiver, uint256 amount) public {
        require(balances[sender] >= amount);
        balances[sender] = balances[sender] - amount;
        balances[receiver] = balances[receiver] + amount;
        emit Transfer(sender, receiver, amount);
    }

    function redeem(address redeemer, uint256 amount, bytes data) public {
        /* This method can only be called by an Issuer */
        require(msg.sender == issuer);

        /* The redeemer must have enough tokens to burn */
        require(balances[redeemer] >= amount);

        totalSupply -= amount;
        balances[redeemer] -= amount;
        emit Redeem(redeemer, msg.sender, amount, data);
    }
}
