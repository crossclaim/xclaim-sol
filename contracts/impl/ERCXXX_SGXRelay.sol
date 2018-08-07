pragma solidity ^0.4.24;

/// @title ERCXXX ReferenceToken Contract
/// @author Dominik Harz, Panayiotis Panayiotou
/// @dev This token contract's goal is to give an example implementation
///  of ERCXXX with ERC20 compatibility.
///  This contract does not define any standard, but can be taken as a reference
///  implementation in case of any ambiguity into the standard
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../ERCXXX_SGXRelay_Interface.sol";
import "./ERCXXX_SGX.sol";



contract ERCXXX_SGXRelay is ERCXXX_SGX("BTC-ERC-Relay", "BTH", 1), ERCXXX_SGXRelay_Interface {
    using SafeMath for uint256;

    // #####################
    // CONTRACT VARIABLES
    // #####################

    uint256 public issuerCollateral;
    address issuerCandidate;
    bool issuerReplace;
    uint256 issuerReplaceTimelock;

    struct RedeemRequest {
        address redeemer;
        uint value;
        uint redeemTime;
    }

    uint256 redeemRequestId;
    uint256[] public redeemRequestList;
    mapping(uint => RedeemRequest) public redeemRequestMapping;

    mapping(address => bool) public relayer;

    // #####################
    // CONSTRUCTOR
    // #####################
    constructor() public {
        // Collateral required since we don't trust the issuer
        minimumCollateral = 1 ether;
    }

    function authorizeIssuer(address toRegister) public payable {
        require(msg.value >= minimumCollateral);
        /* Allows only 1 Issuer */
        require(issuer == address(0));
        issuer = toRegister;
        /* Total amount of tokens that you can issue */
        issuerTokenSupply = convertEthToBtc(msg.value);
        issuerCollateral = msg.value;
        issuerReplace = false;
        emit AuthorizedIssuer(toRegister, msg.value);
    }

    function pendingRedeemRequests() public view returns(uint256[]) {
        return redeemRequestList;
    }

    function authorizeRelayer(address toRegister, bytes data) public {
        /* TODO: who authroizes this? */
        // Do we need the data argument?
        // Does the relayer need to provide collateral?
        require(!relayer[toRegister]);
        require(!relayer[msg.sender]);

        relayer[toRegister] = true;
        emit AuthorizeRelayer(toRegister, data);
    }

    function revokeRelayer(address toUnlist, bytes data) public {
        require(relayer[toUnlist]);
        require(relayer[msg.sender]);

        relayer[toUnlist] = false;
        emit RevokeRelayer(msg.sender, data);
    }

    // #####################
    // ISSUE
    // #####################

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
        require(relayer[msg.sender]);
        
        // BTCRelay verifyTx callback
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

    function registerHTLC(uint256 timelock, uint256 amount, bytes32 script, bytes32 signature, bytes data) public {
        userHTLC[msg.sender] = HTLC(timelock, amount, script, signature, data);
        uint8 issueType = 1;

        emit RegisterIssue(msg.sender, amount, timelock, issueType);
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

    // #####################
    // TRADE
    // #####################

    // #####################
    // REDEEM
    // #####################


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

    function verifyHTLC() public {
        // TODO: store bytes
        // signature
        // locktime
        // script
    }

    function convertEthToBtc(uint256 eth) private pure returns(uint256) {
        /* TODO use a contract that uses middleware to get the conversion rate */
        uint256 conversionRate = 2;
        return eth * conversionRate;
    }
}