pragma solidity ^0.4.24;

/// @title ERCXXX ReferenceToken Contract
/// @author Dominik Harz, Panayiotis Panayiotou
/// @dev This token contract's goal is to give an example implementation
///  of ERCXXX with ERC20 compatibility.
///  This contract does not define any standard, but can be taken as a reference
///  implementation in case of any ambiguity into the standard
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../ERCXXX_Base_Interface.sol";
import "ERC20.sol";

contract ERCXXX_Base is ERCXXX_Base_Interface, ERC20 {
    using SafeMath for uint256;

    // #####################
    // CONTRACT VARIABLES
    // #####################

    // general
    string private _name;
    string private _symbol;
    uint256 private _granularity;

    // issuer
    address private _issuer;
    uint256 private _issuerTokenSupply; // token supply per issuer
    uint256 private _issuerCommitedTokens; // token commited by issuer
    uint256 private _issuerCollateral;
    address private _issuerCandidate; //what is this?
    bool private _issuerReplace;
    uint256 private _issuerReplaceTimelock;

    // relayer
    address private _relayer;

    // time
    uint256 private _contestationPeriod;
    uint256 private _graceRedeemPeriod;
    
    // collateral
    uint256 private _minimumCollateralIssuer;
    uint256 private _minimumCollateralUser;
    
    // conversion rate
    uint256 private _conversionRateBTCETH; // 10*5 granularity?
    
    // issue - collateral
    struct CommitedCollateral {
        uint256 commitTimeLimit;
        uint256 collateral;
    }
    mapping(address => CommitedCollateral) private _userCommitedCollateral;
    
    // issue - HTLC
    struct HTLC {
        uint256 locktime;
        uint256 amount;
        bytes32 script;
        bytes32 siganture;
        bytes tx_id;
    }
    mapping(address => HTLC) private _userHTLC;
    
    // trade
    struct TradeOffer {
        address tokenParty;
        address ethParty;
        uint256 tokenAmount;
        uint256 ethAmount;
        bool completed;
    }
    mapping(uint256 => TradeOffer) private _tradeOfferStore;
    uint256 private _tradeOfferId; //todo: do we need this?

    // redeem
    struct RedeemRequest {
        address redeemer;
        uint value;
        uint redeemTime;
    }
    mapping(uint => RedeemRequest) private _redeemRequestMapping;
    uint256[] private _redeemRequestList;
    uint256 private _redeemRequestId;

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
    
    // function authorizeRelayer in implementations

    function revokeRelayer(address toUnlist) public {
        _relayer = address(0);
        emit RevokeRelayer(relayer, data);
    }

    // ---------------------
    // ISSUE
    // ---------------------

    function registerIssue(uint256 amount) public payable; 

    function issueCol(address receiver, uint256 amount, bytes lock_tx) public;

    function registerHTLC(uint256 locktime, uint256 amount, bytes32 script, bytes32 signature, bytes data) public;

    function issueHTLC(address receiver, uint256 amount, bytes lock_tx) public;

    // ---------------------
    // TRADE
    // ---------------------

    function offerTrade(uint256 tokenAmount, uint256 ethAmount, address ethParty) public {
        require(_balances[msg.sender] >= tokenAmount, "Insufficient balance");

        _balances[msg.sender] -= tokenAmount;
        _tradeOfferStore[tradeOfferId] = TradeOffer(msg.sender, ethParty, tokenAmount, ethAmount, false);
        
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

    function redeem(address redeemer, uint256 amount, bytes redeem_tx) public;

    // ---------------------
    // REPLACE
    // ---------------------


    // ---------------------
    // HELPERS
    // ---------------------

    function _convertEthToBtc(uint256 eth) private pure returns(uint256) {
        /* TODO use a contract that uses middleware to get the conversion rate */
        return eth * _conversionRateBTCETH;
    }

    function _verifyHTLC() private pure returns (bool) {
        // TODO: store bytes
        // signature
        // locktime
        // script
        return true;
    }

    function _verifyTx(bytes data) private returns (bool verified) {
        // data from line 256 https://github.com/ethereum/btcrelay/blob/develop/test/test_btcrelay.py
        bytes memory rawTx = "0x8c14f0db3df150123e6f3dbbf30f8b955a8249b62ac1d1ff16284aefa3d06d87";
        uint256 txIndex = 0;
        uint256[] memory merkleSibling = new uint256[](2);
        merkleSibling[0] = uint256(sha256("0xfff2525b8931402dd09222c50775608f75787bd2b87e56995a7bdd30f79702c4"));
        merkleSibling[1] = uint256(sha256("0x8e30899078ca1813be036a073bbf80b86cdddde1c96e9e9c99e9e3782df4ae49"));
        uint256 blockHash = uint256(sha256("0x0000000000009b958a82c10804bd667722799cc3b457bc061cd4b7779110cd60"));

        uint256 result = btcRelay.verifyTx(rawTx, txIndex, merkleSibling, blockHash);

        // TODO: Implement this correctly, now for testing only
        if (data.length == 0) {
            return false;
        } else {
            return true;
        }
    }
}