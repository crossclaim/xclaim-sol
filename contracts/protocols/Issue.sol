pragma solidity ^0.5.0;

import "../utils/Verify.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract Issue is Verify {
    using SafeMath for uint256;

    struct CommitedCollateral {
        uint256 commitTimeLimit;
        uint256 collateral;
    }
    mapping(address => CommitedCollateral) public _userCommitedCollateral;

    // user needs to provide btc address
    // op_return needs to include ETH address
    function registerIssue(uint256 amount, bytes memory btcAddress) public payable {
        require(msg.value >= super._minimumCollateralUser, "Collateral too small");
        /* If there is not enough tokens, return back the collateral */
        if (super._issuerTokenSupply < amount + super._issuerCommitedTokens) { // TODO might need a 3rd variable here
            msg.sender.transfer(msg.value);
            return;
        }

        uint256 timelock = now + 1 seconds;
        super._issuerCommitedTokens += amount;
        _userCommitedCollateral[msg.sender] = CommitedCollateral(timelock, amount);
        
        // TODO: need to lock issuers collateral
        
        // emit event
        emit RegisterIssue(msg.sender, amount, timelock);
    }

    event RegisterIssue(address indexed sender, uint256 value, uint256 timelock);

    function issueCol(address receiver, uint256 amount, bytes memory data) public {
        /* Can be called by anyone */
        // BTCRelay verifyTx callback
        bool result = Verify._verifyTx(data);

        if (result) {
            // issue tokens
            super._totalSupply += amount;
            super._balances[receiver] += amount;

            emit IssueToken(msg.sender, receiver, amount, data);
            return;
        } else {
            // abort issue
            super._issuerCommitedTokens -= amount;
            _userCommitedCollateral[msg.sender] = CommitedCollateral(0,0);

            emit AbortIssue(msg.sender, receiver, amount, data);
            return;
        }
    }

    event IssueToken(address indexed issuer, address indexed receiver, uint value, bytes data);

    event AbortIssue(address indexed issuer, address indexed receiver, uint value, bytes data);
}