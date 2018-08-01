pragma solidity ^0.4.24;

/// @title ERCXXX ReferenceToken Contract
/// @author Dominik Harz
/// @dev This token contract's goal is to give an example implementation
///  of ERCXXX with ERC223 compatibility.
///  This contract does not define any standard, but can be taken as a reference
///  implementation in case of any ambiguity into the standard
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../ERCXXX_Base_Interface.sol";


contract ERCXXX_SGX is ERCXXX_Base_Interface {
    using SafeMath for uint256;

    // #####################
    // CONTRACT VARIABLES
    // #####################


    string public name;
    string public symbol;
    uint256 public granularity;
    uint256 public totalSupply;

    uint256 public contestationPeriod;
    uint256 public graceRedeemPeriod;
    /* TODO: work out a value for minimum collateral */
    uint256 public minimumCollateral = 0;

    mapping(address => uint) public balances;

    address[] public issuersList;
    mapping(address => bool) public issuers;

    struct RedeemRequest{
        address redeemer;
        uint value;
        uint redeemTime;
    }

    uint256[] public redeemRequestList;
    mapping(uint => RedeemRequest) public redeemRequestMapping;

    // All events are defined in the interface contract - no need to double it here
    /* Event emitted when a transfer is done */
    // event Transfer(address indexed from, address indexed to, uint256 amount);

    // #####################
    // CONSTRUCTOR
    // #####################
    constructor(string _name, string _symbol, uint256 _granularity) public {
        require(_granularity >= 1);

        name = _name;
        symbol = _symbol;
        granularity = _granularity;
        totalSupply = 0;
        // TODO: value
        contestationPeriod = 1;
        // TODO: value
        graceRedeemPeriod = 1;
    }

    // #####################
    // MODIFIERS
    // #####################

    // #####################
    // HELPER FUNCTIONS
    // #####################

    function name() public view returns (string) {
        return name;
    }

    function symbol() public view returns (string) {
        return symbol;
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint) {
        return balances[_owner];
    }

    function granularity() public view returns (uint256) {
        return granularity;
    }

    // #####################
    // FUNCTIONS
    // #####################

    function pendingRedeemRequests() public view returns(uint256[]) {
        return redeemRequestList;
    }

    function issuerList() public view returns(address[]) {
        return issuersList;
    }

    function authorizeIssuer(address toRegister) public payable {
        // TODO: Do we need the data argument?
        require(msg.value >= minimumCollateral);
        issuers[toRegister] = true;
        issuersList.push(toRegister);
        emit AuthorizedIssuer(toRegister, msg.value);
    }

    function revokeIssuer(address toUnlist) private {
        /* This method can only be called by the current Issuer */
        // require(issuers[msg.sender]);
        // require(msg.sender == toUnlist);
        require(issuersList.length > 0);

        issuers[toUnlist] = false;
        // Remove toUnlist without order
        for (uint256 i = 0; i < issuersList.length; i++) {
            if (issuersList[i] == toUnlist) {
                uint256 lastIndex = issuersList.length - 1;

                if (i == lastIndex) {
                    delete issuersList[i];
                } else {
                    issuersList[i] = issuersList[lastIndex];
                    delete issuersList[lastIndex];
                }

                issuersList.length--;
            }
        }

        emit RevokedIssuer(toUnlist);
    }

    function issue(address receiver, uint256 amount, bytes data) public {
        /* This method can only be called by an Issuer */
        require(issuers[msg.sender]);

        balances[receiver] += amount;
        emit Issue(msg.sender, receiver, amount, data);
    }

    function transferFrom(address sender, address receiver, uint256 amount) public {
        require(balances[sender] >= amount);

        balances[sender] = balances[sender] - amount;
        balances[receiver] = balances[receiver] + amount;
        emit Transfer(sender, receiver, amount);
    }

    function redeem(address redeemer, uint256 amount, bytes data) public {
        /* This method can only be called by an Issuer */
        require(issuers[msg.sender]);

        /* The redeemer must have enough tokens to burn */
        require(balances[redeemer] >= amount);

        balances[redeemer] -= amount;
        emit Redeem(redeemer, msg.sender, amount, data);
    }
}
