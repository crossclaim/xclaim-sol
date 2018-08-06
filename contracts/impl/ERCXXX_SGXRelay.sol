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
        minimumCollateral = 1;
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
        emit AuthorizeRelayer(msg.sender, data);
    }

    function revokeRelayer(address toUnlist, bytes data) public {
        require(relayer[toUnlist]);
        require(relayer[msg.sender]);

        relayer[toUnlist] = false;
        emit RevokeRelayer(msg.sender, data);
    }

    function issue(address receiver, uint256 amount, bytes data) public {
        /* This method can only be called by a BTC relay */

        // Should be the SGX relay, but does not matter for now
        address btcrelay;
        require(msg.sender == btcrelay);

        balances[receiver] += amount;
        emit Issue(msg.sender, receiver, amount, data);
    }

    function redeem(address redeemer, uint256 amount, bytes data) public {
        /* This method can only be called by a relayer */
        require(relayer[msg.sender]);

        /* The redeemer must have enough tokens to burn */
        require(balances[redeemer] >= amount);

        uint256 time = 1 days;

        redeemRequestId++;
        redeemRequestList.push(redeemRequestId);
        redeemRequestMapping[redeemRequestId] = RedeemRequest(redeemer, amount, (now + time));

        // balances[redeemer] -= amount;
        // Update this to include ID
        emit Redeem(redeemer, msg.sender, amount, data);
    }

    function redeemRequest(address redeemer, uint256 id) public {
        require(redeemRequestMapping[id].redeemTime < now);
        require(redeemRequestMapping[id].value <= balances[redeemer]);

        balances[redeemer] -= redeemRequestMapping[id].value;
        emit RedeemSuccess(redeemer, id);
    }
}
