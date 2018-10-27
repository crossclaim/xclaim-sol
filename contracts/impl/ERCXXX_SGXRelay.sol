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
        emit AuthorizeRelayer(toRegister, data);
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
            totalSupply += amount;
            balances[receiver] += amount;

            emit Issue(msg.sender, receiver, amount, data);
            return;
        } else {
            // abort issue
            issuerCommitedTokens -= amount;
            userCommitedCollateral[msg.sender] = CommitedCollateral(0,0);

            emit AbortIssue(msg.sender, receiver, amount, data);
            return;
        }
    }

    function issueHTLC(address receiver, uint256 amount, bytes data) public {
        // TODO: data is not required in the SGX centralised case
        /* This method can only be called by an Issuer */
        // This method is only called by the issuer during the timelock
        require(relayer[msg.sender]); 
        if (data.length != 0) {
            // issue tokens
            totalSupply += amount;
            balances[receiver] += amount;

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
        require(relayer[msg.sender]);

        /* The redeemer must have enough tokens to burn */
        require(balances[redeemer] >= amount);

        // for testing
        uint256 time = 1 seconds;

        redeemRequestId++;
        redeemRequestList.push(redeemRequestId);
        redeemRequestMapping[redeemRequestId] = RedeemRequest(redeemer, amount, (now + time));

        // balances[redeemer] -= amount;
        // Update this to include ID
        emit Redeem(redeemer, msg.sender, amount, data, redeemRequestId);
    }

    function redeemConfirm(address redeemer, uint256 id) public {
        require(redeemRequestMapping[id].redeemTime > now);
        require(redeemRequestMapping[id].value <= balances[redeemer]);

        balances[redeemer] -= redeemRequestMapping[id].value;
        totalSupply -= redeemRequestMapping[id].value;
        emit RedeemSuccess(redeemer, id);
    }   

    function reimburse(address redeemer, uint256 id) public {
        require(redeemRequestMapping[id].redeemTime < now);
        require(msg.sender == redeemRequestMapping[id].redeemer);

        issuerCollateral -= redeemRequestMapping[id].value;
        balances[redeemer] -= redeemRequestMapping[id].value;

        redeemer.transfer(redeemRequestMapping[id].value);
        
        emit Reimburse(redeemer, issuer, redeemRequestMapping[id].value);
    }

    // #####################
    // REPLACE
    // #####################

    function replace(bytes data) public {
        // SGX only calls this if BTC tx is valid, BTCRelay requires call to check tx
        require(issuerReplace);
        require(msg.sender == issuer);
        require(issuerReplaceTimelock > now);

        issuer = issuerCandidate;
        issuerCandidate = address(0);
        issuerReplace = false;
        issuer.transfer(issuerCollateral);

        emit Replace(issuerCandidate, issuerCollateral);
    }
}