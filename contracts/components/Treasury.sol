pragma solidity ^ 0.5 .0;

import "../interfaces/Treasury_Interface.sol";
import "../components/ERC20.sol";

contract Treasury is Treasury_Interface, ERC20 {

    // #####################
    // CONTRACT VARIABLES
    // #####################

    // issuer
    address payable public _issuer;
    uint256 public _issuerTokenSupply; // token supply per issuer
    uint256 public _issuerCommitedTokens; // token commited by issuer
    uint256 public _issuerCollateral;
    address payable public _issuerCandidate;
    bool public _issuerReplace;
    uint256 public _issuerReplaceTimelock;

    // relayer
    address public _relayer;

    // block periods
    uint256 public _confirmations;
    uint256 public _contestationPeriod;
    uint256 public _graceRedeemPeriod;

    // collateral
    uint256 public _minimumCollateralIssuer;
    uint256 public _minimumCollateralUser;

    // conversion rate
    uint256 public _conversionRateBTCETH; // 10*5 granularity?

    // issue
    struct CommitedCollateral {
        uint256 blocknumber;
        uint256 collateral;
        bytes btcAddress;
    }
    mapping(address => CommitedCollateral) public _userCommitedCollateral;

    // swap
    struct TradeOffer {
        address payable tokenParty;
        address payable ethParty;
        uint256 tokenAmount;
        uint256 ethAmount;
        bool completed;
    }
    mapping(uint256 => TradeOffer) public _tradeOfferStore;
    uint256 public _tradeOfferId; //todo: do we need this?


    // redeem
    struct RedeemRequest {
        address payable redeemer;
        uint256 value;
        uint256 redeemTime;
    }
    mapping(uint => RedeemRequest) public _redeemRequestMapping;
    uint256 public _redeemRequestId;

    constructor() public {
        _totalSupply = 0;
        // issuer
        _issuerTokenSupply = 0;
        _issuerCommitedTokens = 0;
        _issuerCollateral = 0;
        // block
        _confirmations = 12;
        _contestationPeriod = 30;
        _graceRedeemPeriod = 30;
        // collateral
        _minimumCollateralUser = 1 wei;
        _minimumCollateralIssuer = 1 wei;
        // conversion rate
        _conversionRateBTCETH = 2 * 10 ^ 5; // equals 1 BTC = 2 ETH
        // init id counters
        _tradeOfferId = 0;
        _redeemRequestId = 0;
    }

    // #####################
    // FUNCTIONS
    // #####################

    // note: single issuer case
    function issuer() public view returns(address) {
        return _issuer;
    }

    function relayer() public view returns(address) {
        return _relayer;
    }

    // ---------------------
    // SETUP
    // ---------------------
    function getEthtoBtcConversion() public returns(uint256) {
        return _conversionRateBTCETH;
    }

    function setEthtoBtcConversion(uint256 rate) public {
        // todo: require maximum fluctuation
        // todo: only from "trusted" oracles
        _conversionRateBTCETH = rate;
    }

    // Vaults
    function authorizeIssuer(address payable toRegister) public payable {
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
        /* TODO: who authroizes this? 
        For now, this method is only available in the constructor */
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
    function registerIssue(uint256 amount, bytes memory btcAddress) public payable {
        require(msg.value >= _minimumCollateralUser, "Collateral too small");
        require(_issuerTokenSupply > amount + _issuerCommitedTokens, "Not enough collateral provided by issuer");

        _issuerCommitedTokens += amount;
        _userCommitedCollateral[msg.sender] = CommitedCollateral(block.number, amount, btcAddress);

        // TODO: need to lock issuers collateral

        // emit event
        emit RegisterIssue(msg.sender, amount, block.number);
    }

    function issueToken(address receiver, uint256 amount, bytes memory data) public {
        require(_userCommitedCollateral[receiver].collateral > 0, "Collateral too small");

        // check if within number of blocks

        bool confirmed;
        if ((_userCommitedCollateral[receiver].blocknumber >= (block.number - _confirmations)) 
        && (_userCommitedCollateral[receiver].blocknumber <= (block.number + _contestationPeriod))) {
            confirmed = true;
        } else {
            confirmed = false;
        }

        // BTCRelay verifyTx callback
        bool tx_valid = _verifyTx(data);

        // TODO: match btc and eth address
        bool address_valid = _verifyAddress(receiver, _userCommitedCollateral[receiver].btcAddress, data);

        if (confirmed && tx_valid && address_valid) {
            // issue tokens
            _totalSupply += amount;
            _balances[receiver] += amount;
            // reset user issue
            _userCommitedCollateral[msg.sender].collateral = 0;
            _userCommitedCollateral[msg.sender].blocknumber = 0;

            emit IssueToken(msg.sender, receiver, amount, data);
            return;
        } else {
            // abort issue
            _issuerCommitedTokens -= amount;
            // slash user collateral
            _userCommitedCollateral[msg.sender].collateral = 0;

            emit AbortIssue(msg.sender, receiver, amount, data);
            return;
        }
    }

    // ---------------------
    // TRANSFER
    // ---------------------
    // see protocols/ERC20.sol

    // ---------------------
    // SWAP
    // ---------------------

    function offerTrade(uint256 tokenAmount, uint256 ethAmount, address payable ethParty) public {
        require(_balances[msg.sender] >= tokenAmount, "Insufficient balance");

        _balances[msg.sender] -= tokenAmount;
        _tradeOfferStore[_tradeOfferId] = TradeOffer(msg.sender, ethParty, tokenAmount, ethAmount, false);

        emit NewTradeOffer(_tradeOfferId, msg.sender, tokenAmount, ethParty, ethAmount);

        _tradeOfferId += 1;
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
    function redeem(address payable redeemer, uint256 amount, bytes memory data) public {

        /* The redeemer must have enough tokens to burn */
        require(_balances[redeemer] >= amount);

        // need to lock tokens

        // for testing
        uint256 time = 1 seconds;

        _redeemRequestId++;
        _redeemRequestMapping[_redeemRequestId] = RedeemRequest(redeemer, amount, (now + time));

        emit RequestRedeem(redeemer, msg.sender, amount, data, _redeemRequestId);
    }

    // TODO: make these two functions into one
    function redeemConfirm(address redeemer, uint256 id, bytes memory data) public {
        require(_redeemRequestMapping[id].redeemTime > now);
        require(_redeemRequestMapping[id].value <= _balances[redeemer]);

        bool result = _verifyTx(data);

        _balances[redeemer] -= _redeemRequestMapping[id].value;
        _totalSupply -= _redeemRequestMapping[id].value;
        // increase token amount of issuer that can be used for issuing
        emit ConfirmRedeem(redeemer, id);
    }

    function reimburse(address payable redeemer, uint256 id, bytes memory data) public {
        require(_redeemRequestMapping[id].redeemTime < now);
        require(msg.sender == _redeemRequestMapping[id].redeemer);

        // bool result = _verifyTx(data);

        _issuerCollateral -= _redeemRequestMapping[id].value;
        _balances[redeemer] -= _redeemRequestMapping[id].value;

        redeemer.transfer(_redeemRequestMapping[id].value);

        emit Reimburse(redeemer, _issuer, _redeemRequestMapping[id].value);
    }

    // ---------------------
    // REPLACE
    // ---------------------
    function requestReplace() public {
        require(msg.sender == _issuer);
        require(!_issuerReplace);

        _issuerReplace = true;
        _issuerReplaceTimelock = now + 1 seconds;

        emit RequestReplace(_issuer, _issuerCollateral, _issuerReplaceTimelock);
    }

    function lockCol() public payable {
        require(_issuerReplace, "Issuer did not request change");
        require(msg.sender != _issuer, "Needs to be replaced by a non-issuer");
        require(msg.value >= _issuerCollateral, "Collateral needs to be high enough");

        _issuerCandidate = msg.sender;

        emit LockReplace(_issuerCandidate, msg.value);
    }

    function replace(bytes memory data) public {
        require(_issuerReplace);
        require(msg.sender == _issuer);
        require(_issuerReplaceTimelock > now);

        bool result = _verifyTx(data);

        _issuer = _issuerCandidate;
        _issuerCandidate = address(0);
        _issuerReplace = false;
        _issuer.transfer(_issuerCollateral);

        emit ExecuteReplace(_issuerCandidate, _issuerCollateral);
    }

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

    function _verifyTx(bytes memory data) private returns(bool verified) {
        // data from line 256 https://github.com/ethereum/btcrelay/blob/develop/test/test_btcrelay.py
        bytes memory rawTx = "0x8c14f0db3df150123e6f3dbbf30f8b955a8249b62ac1d1ff16284aefa3d06d87";
        uint256 txIndex = 0;
        uint256[] memory merkleSibling = new uint256[](2);
        merkleSibling[0] = uint256(sha256("0xfff2525b8931402dd09222c50775608f75787bd2b87e56995a7bdd30f79702c4"));
        merkleSibling[1] = uint256(sha256("0x8e30899078ca1813be036a073bbf80b86cdddde1c96e9e9c99e9e3782df4ae49"));
        uint256 blockHash = uint256(sha256("0x0000000000009b958a82c10804bd667722799cc3b457bc061cd4b7779110cd60"));

        (bool success, bytes memory returnData) = _relayer.call(abi.encodeWithSignature("verifyTx(bytes, uint256, uint256[], uint256)", rawTx, txIndex, merkleSibling, blockHash));

        // TODO: Implement this correctly, now for testing only
        if (data.length == 0) {
            return false;
        } else {
            return true;
        }
    }

    function _verifyAddress(address receiver, bytes memory btcAddress, bytes memory data) private returns(bool verified) {
        return true;
    }

    function _convertEthToBtc(uint256 eth) private view returns(uint256) {
        /* TODO use a contract that uses middleware to get the conversion rate */
        return eth * _conversionRateBTCETH;
    }
}