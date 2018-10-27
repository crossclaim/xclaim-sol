pragma solidity ^0.4.24;

/// @title ERCXXX ReferenceToken Contract
/// @author Dominik Harz
/// @dev This token contract's goal is to give an example implementation
///  of ERCXXX with ERC20 compatibility.
///  This contract does not define any standard, but can be taken as a reference
///  implementation in case of any ambiguity into the standard
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./ERCXXX_Base.sol";
import "../BTCRelay/BTCRelay.sol";



contract ERCXXX_BTCRelay is ERCXXX_Base("BTC-ERC-Relay", "BTH", 1) {
    using SafeMath for uint256;

    // #####################
    // CONTRACT VARIABLES
    // #####################

    BTCRelay btcRelay;

    constructor () public {
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
        btcRelay = BTCRelay(toRegister);
        emit AuthorizeRelayer(toRegister, data);
    }

    // ---------------------
    // ISSUE
    // ---------------------

    function registerIssue(uint256 amount) public payable {
        require(msg.value >= minimumCollateralCommitment);

        uint8 issueType = 0;
        /* If there is not enough tokens, return back the collateral */
        if (issuerTokenSupply < amount + issuerCommitedTokens) { // TODO might need a 3rd variable here
            msg.sender.transfer(msg.value);
            return;
        }
        uint256 timelock = now + 1 seconds;
        issuerCommitedTokens += amount;
        userCommitedCollateral[msg.sender] = CommitedCollateral(timelock, amount);
        
        // TODO: need to lock issuers collateral
        
        // emit event
        emit RegisterIssue(msg.sender, amount, timelock, issueType);
    }

    function issueCol(address receiver, uint256 amount, bytes data) public {
        /* This method can only be called by a BTC relay */
        // address btcrelay;
        // require(msg.sender == btcrelay);
        // Should be the SGX relay, but does not matter for now
        // require(msg.sender == relayer);

         // BTCRelay verifyTx callback
        bool result = verifyTx(data);

        if (result) {
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

    function registerHTLC(uint256 timelock, uint256 amount, bytes32 script, bytes32 signature, bytes data) public {
        userHTLC[msg.sender] = HTLC(timelock, amount, script, signature, data);
        uint8 issueType = 1;

        bool result = verifyTx(data);

        emit RegisterIssue(msg.sender, amount, timelock, issueType);
    }

    function issueHTLC(address receiver, uint256 amount, bytes data) public {
        // TODO: data is not required in the SGX centralised case
        /* This method can only be called by an Issuer */
        // This method is only called by the issuer during the timelock
        // require(msg.sender == relayer); 

        bool result = verifyTx(data);

        if (result) {
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
        // require(msg.sender == relayer);

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

    // TODO: make these two functions into one
    function redeemConfirm(address redeemer, uint256 id, bytes data) public {
        require(redeemRequestMapping[id].redeemTime > now);
        require(redeemRequestMapping[id].value <= balances[redeemer]);

        bool result = verifyTx(data);

        balances[redeemer] -= redeemRequestMapping[id].value;
        totalSupply -= redeemRequestMapping[id].value;
        emit RedeemSuccess(redeemer, id);
    }   

    function reimburse(address redeemer, uint256 id, bytes data) public {
        require(redeemRequestMapping[id].redeemTime < now);
        require(msg.sender == redeemRequestMapping[id].redeemer);

        bool result = verifyTx(data);

        issuerCollateral -= redeemRequestMapping[id].value;
        balances[redeemer] -= redeemRequestMapping[id].value;

        redeemer.transfer(redeemRequestMapping[id].value);
        
        emit Reimburse(redeemer, issuer, redeemRequestMapping[id].value);
    }

    // #####################
    // REPLACE
    // #####################

    function requestReplace() public {
        require(msg.sender == issuer);
        require(!issuerReplace);

        issuerReplace = true;
        issuerReplaceTimelock = now + 1 seconds;

        emit RequestReplace(issuer, issuerCollateral);
    }

    function lockCol() public payable {
        require(issuerReplace);
        require(msg.sender != issuer);
        require(msg.value >= issuerCollateral);

        issuerCandidate = msg.sender;

        emit LockReplace(issuerCandidate, msg.value);
    }

    function replace(bytes data) public {
        // SGX only calls this if BTC tx is valid, BTCRelay requires call to check tx
        require(issuerReplace);
        require(msg.sender == issuer);
        require(issuerReplaceTimelock > now);

        bool result = verifyTx(data);

        issuer = issuerCandidate;
        issuerCandidate = address(0);
        issuerReplace = false;
        issuer.transfer(issuerCollateral);

        emit Replace(issuerCandidate, issuerCollateral);
    }

    function abortReplace() public {
        require(issuerReplace);
        require(msg.sender == issuerCandidate);
        require(issuerReplaceTimelock < now);

        issuerReplace = false;

        issuerCandidate.transfer(issuerCollateral);

        emit AbortReplace(issuerCandidate, issuerCollateral);
    }

    function verifyHTLC() public pure returns (bool) {
        // TODO: store bytes
        // signature
        // locktime
        // script
        return true;
    }

    function verifyTx(bytes data) private returns (bool verified) {
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

    function convertEthToBtc(uint256 eth) private pure returns(uint256) {
        /* TODO use a contract that uses middleware to get the conversion rate */
        uint256 conversionRate = 2;
        return eth * conversionRate;
    }
}