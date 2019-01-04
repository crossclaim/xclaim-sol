pragma solidity ^0.5.0;

import "./interfaces/XCLAIM_Interface.sol";
import "./protocols/ERC20.sol";
import "./protocols/Issue.sol";
import "./protocols/Swap.sol";
import "./protocols/Redeem.sol";
import "./protocols/Replace.sol";

contract XCLAIM is XCLAIM_Interface, ERC20, Issue, Swap, Redeem, Replace {

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

    constructor (string myname, string mysymbol, uint256 mygranularity, address _relay) public {
        _name = myname;
        _symbol = mysymbol;
        _granularity = mygranularity;
        _totalSupply = 0;
        // issuer
        _issuerTokenSupply = 0;
        _issuerCommitedTokens = 0;
        _issuerCollateral = 0;
        // relay
        authorizeRelayer(_relay);
        // time
        _contestationPeriod = 1 seconds;
        _graceRedeemPeriod = 1 seconds;
        // collateral
        _minimumCollateralUser = 1 wei;
        _minimumCollateralIssuer = 1 wei;
        // conversion rate
        _conversionRateBTCETH = 2 * 10^5; // equals 1 BTC = 2 ETH
        // init id counters
        _tradeOfferId = 0;
        _redeemRequestId = 0;
    }

    // #####################
    // FUNCTIONS
    // #####################

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

    function relayer() public view returns(address) {
        return _relayer;
    }

    function pendingRedeemRequests() public view returns(uint256[]) {
        return _redeemRequestList;
    }

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

    // Vaults
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
        /* TODO: who authroizes this? */
        // Does the relayer need to provide collateral?
        require(_relayer == address(0));
        require(msg.sender != _relayer);

        _relayer = toRegister;
        // btcRelay = BTCRelay(toRegister);
        emit AuthorizedRelayer(toRegister);
    }

    function revokeRelayer(address toUnlist) public {
        // TODO: who can do that?
        _relayer = address(0);
        // btcRelay = BTCRelay(address(0));
        emit RevokedRelayer(_relayer);
    }

    // ---------------------
    // ISSUE
    // ---------------------
    // see protocols/Issue.sol

    // ---------------------
    // TRANSFER
    // ---------------------
    // see protocols/ERC20.sol

    // ---------------------
    // SWAP
    // ---------------------
    // see protocols/Swap.sol

    // ---------------------
    // REDEEM
    // ---------------------
    // see protocols/Redeem.sol

    // ---------------------
    // REPLACE
    // ---------------------
    // see protocols/Replace.sol

    // ---------------------
    // HELPERS
    // ---------------------

    function _convertEthToBtc(uint256 eth) private view returns(uint256) {
        /* TODO use a contract that uses middleware to get the conversion rate */
        return eth * _conversionRateBTCETH;
    }
}
