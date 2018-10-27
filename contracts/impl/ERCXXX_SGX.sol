pragma solidity ^0.4.24;

/// @title ERCXXX ReferenceToken Contract
/// @author Dominik Harz, Panayiotis Panayiotou
/// @dev This token contract's goal is to give an example implementation
///  of ERCXXX with ERC20 compatibility.
///  This contract does not define any standard, but can be taken as a reference
///  implementation in case of any ambiguity into the standard
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./ERCXXX_Base.sol";


contract ERCXXX_SGX is ERCXXX_Base("BTC-SGX", "BTH", 1) {
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
        _minimumCollateralIssuer = 0 wei;
    }

    // #####################
    // FUNCTIONS
    // #####################

    // ---------------------
    // SETUP
    // ---------------------

    // ---------------------
    // ISSUE
    // ---------------------

    function issueCol(address receiver, uint256 amount, bytes lock_tx) public {
        // TODO: data is not required in the SGX centralised case
        /* This method can only be called by an Issuer */
        require(msg.sender == _issuer);

        if (lock_tx.length != 0) {
            // issue tokens
            _totalSupply += amount;
            _balances[receiver] += amount;

            emit Issue(msg.sender, receiver, amount, lock_tx);
            return;
        } else {
            // abort issue
            _issuerCommitedTokens -= amount;
            _userCommitedCollateral[msg.sender] = CommitedCollateral(0,0);

            emit AbortIssue(msg.sender, receiver, amount, lock_tx);
            return;
        }
    }

    function issueHTLC(address receiver, uint256 amount, bytes lock_tx) public {
        // TODO: data is not required in the SGX centralised case
        /* This method can only be called by an Issuer */
        // This method is only called by the issuer during the timelock
        require(msg.sender == _issuer); 
        if (lock_tx.length != 0) {
            // issue tokens
            _totalSupply += amount;
            _balances[receiver] += amount;

            emit Issue(msg.sender, receiver, amount, lock_tx);
            return;
        } else {
            // abort issue
            emit AbortIssue(msg.sender, receiver, amount, lock_tx);
            return;
        }
    }

    // ---------------------
    // TRADE
    // ---------------------

    // ---------------------
    // REDEEM
    // ---------------------


    function redeem(address redeemer, uint256 amount, bytes redeem_tx) public {
        // No failed state in centralised SGX
        /* This method can only be called by an Issuer */
        require(msg.sender == _issuer);

        /* The redeemer must have enough tokens to burn */
        require(_balances[redeemer] >= amount);

        _totalSupply -= amount;
        _balances[redeemer] -= amount;
        emit Redeem(redeemer, msg.sender, amount, redeem_tx, 0);
    }

    // ---------------------
    // REPLACE
    // ---------------------

    // Skip for centralised SGX
}
