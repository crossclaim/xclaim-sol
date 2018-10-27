pragma solidity ^0.4.24;

/// @title ERCXXX ReferenceToken Contract
/// @author Dominik Harz, Panayiotis Panayiotou
/// @dev This token contract's goal is to give an example implementation
///  of ERCXXX with ERC20 compatibility.
///  This contract does not define any standard, but can be taken as a reference
///  implementation in case of any ambiguity into the standard
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./ERCXXX_Base.sol";



contract ERCXXX_SGXRelay is ERCXXX_Base("BTC-SGX-Relay", "BTH", 1) {
    using SafeMath for uint256;

    // #####################
    // CONTRACT VARIABLES
    // #####################

    // #####################
    // CONSTRUCTOR
    // #####################
    constructor() public {
        // issuer
        _issuerCollateral = 0;
        // collateral
        _minimumCollateralIssuer = 1 wei;
    }

    // ---------------------
    // SETUP
    // ---------------------

    // Relayers
    function authorizeRelayer(address toRegister) public {
        /* TODO: who authroizes this? */
        // Do we need the data argument?
        // Does the relayer need to provide collateral?
        require(_relayer == address(0));
        require(msg.sender != _relayer);

        _relayer = toRegister;
        emit AuthorizedRelayer(toRegister);
    }

    // ---------------------
    // ISSUE
    // ---------------------

    function issueCol(address receiver, uint256 amount, bytes data) public {
        /* This method can only be called by a BTC relay */
        // address btcrelay;
        // require(msg.sender == btcrelay);
        // Should be the SGX relay, but does not matter for now
        require(msg.sender == _relayer);
        
        // SGX needs to verif this
        if (data.length != 0) {
            // issue tokens
            _totalSupply += amount;
            _balances[receiver] += amount;

            emit Issue(msg.sender, receiver, amount, data);
            return;
        } else {
            // abort issue
            _issuerCommitedTokens -= amount;
            _userCommitedCollateral[msg.sender] = CommitedCollateral(0,0);

            emit AbortIssue(msg.sender, receiver, amount, data);
            return;
        }
    }

    function issueHTLC(address receiver, uint256 amount, bytes data) public {
        // TODO: data is not required in the SGX centralised case
        /* This method can only be called by an Issuer */
        // This method is only called by the issuer during the timelock
        require(msg.sender == _relayer); 
        if (data.length != 0) {
            // issue tokens
            _totalSupply += amount;
            _balances[receiver] += amount;

            emit Issue(msg.sender, receiver, amount, data);
            return;
        } else {
            // abort issue

            emit AbortIssue(msg.sender, receiver, amount, data);
            return;
        }

    }

    // ---------------------
    // TRADE
    // ---------------------

    // ---------------------
    // REDEEM
    // ---------------------


    function redeem(address redeemer, uint256 amount, bytes data) public {
        /* This method can only be called by a relayer */
        require(msg.sender == _relayer);

        /* The redeemer must have enough tokens to burn */
        require(_balances[redeemer] >= amount);

        // for testing
        uint256 time = 1 seconds;

        _redeemRequestId++;
        _redeemRequestList.push(_redeemRequestId);
        _redeemRequestMapping[_redeemRequestId] = RedeemRequest(redeemer, amount, (now + time));

        // balances[redeemer] -= amount;
        // Update this to include ID
        emit Redeem(redeemer, msg.sender, amount, data, _redeemRequestId);
    }

    function redeemConfirm(address redeemer, uint256 id) public {
        require(_redeemRequestMapping[id].redeemTime > now);
        require(_redeemRequestMapping[id].value <= _balances[redeemer]);

        _balances[redeemer] -= _redeemRequestMapping[id].value;
        _totalSupply -= _redeemRequestMapping[id].value;
        emit RedeemSuccess(redeemer, id);
    }   

    function reimburse(address redeemer, uint256 id) public {
        require(_redeemRequestMapping[id].redeemTime < now);
        require(msg.sender == _redeemRequestMapping[id].redeemer);

        _issuerCollateral -= _redeemRequestMapping[id].value;
        _balances[redeemer] -= _redeemRequestMapping[id].value;

        redeemer.transfer(_redeemRequestMapping[id].value);
        
        emit Reimburse(redeemer, _issuer, _redeemRequestMapping[id].value);
    }

    // #####################
    // REPLACE
    // #####################

    function replace(bytes data) public {
        // SGX only calls this if BTC tx is valid, BTCRelay requires call to check tx
        require(_issuerReplace);
        require(msg.sender == _issuer);
        require(_issuerReplaceTimelock > now);

        _issuer = _issuerCandidate;
        _issuerCandidate = address(0);
        _issuerReplace = false;
        _issuer.transfer(_issuerCollateral);

        emit Replace(_issuerCandidate, _issuerCollateral);
    }
}