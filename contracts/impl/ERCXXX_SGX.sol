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

    function registerIssue(uint256 amount) public payable {
        require(msg.value >= minimumCollateralCommitment);
        /* If there is not enough tokens, return back the collateral */
        // Not required in case of centralised SGX issuer
        // if (issuerTokenSupply < amount + issuerCommitedTokens) { // TODO might need a 3rd variable here
        //     msg.sender.transfer(msg.value);
        //     return;
        // }
        uint8 issueType = 0;

        uint256 timelock = now + 1 seconds;
        issuerCommitedTokens += amount;
        userCommitedCollateral[msg.sender] = CommitedCollateral(timelock, amount);
        // emit event
        emit RegisterIssue(msg.sender, amount, timelock, issueType);
    }

    function issueCol(address receiver, uint256 amount, bytes lock_tx) public {
        // TODO: data is not required in the SGX centralised case
        /* This method can only be called by an Issuer */
        require(msg.sender == issuer);

        if (lock_tx.length != 0) {
            // issue tokens
            totalSupply += amount;
            balances[receiver] += amount;

            emit Issue(msg.sender, receiver, amount, lock_tx);
            return;
        } else {
            // abort issue
            issuerCommitedTokens -= amount;
            userCommitedCollateral[msg.sender] = CommitedCollateral(0,0);

            emit AbortIssue(msg.sender, receiver, amount, lock_tx);
            return;
        }
    }

    function registerHTLC(uint256 timelock, uint256 amount, bytes32 script, bytes32 signature, bytes data) public {
        userHTLC[msg.sender] = HTLC(timelock, amount, script, signature, data);
        uint8 issueType = 1;

        emit RegisterIssue(msg.sender, amount, timelock, issueType);
    }

    function issueHTLC(address receiver, uint256 amount, bytes lock_tx) public {
        // TODO: data is not required in the SGX centralised case
        /* This method can only be called by an Issuer */
        // This method is only called by the issuer during the timelock
        require(msg.sender == issuer); 
        if (lock_tx.length != 0) {
            // issue tokens
            totalSupply += amount;
            balances[receiver] += amount;

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
        require(msg.sender == issuer);

        /* The redeemer must have enough tokens to burn */
        require(balances[redeemer] >= amount);

        totalSupply -= amount;
        balances[redeemer] -= amount;
        emit Redeem(redeemer, msg.sender, amount, redeem_tx);
    }

    // ---------------------
    // REPLACE
    // ---------------------

    // Skip for centralised SGX

    // ---------------------
    // Helpers
    // ---------------------

    function convertEthToBtc(uint256 eth) private pure returns(uint256) {
        /* TODO use a contract that uses middleware to get the conversion rate */
        uint256 conversionRate = 2;
        return eth * conversionRate;
    }
}
