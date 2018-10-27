// erc20.sol -- API for the ERC20 token standard

// See <https://github.com/ethereum/EIPs/issues/20>.
// Adopted from https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.4.24;


import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../ERC20_Interface.sol";

contract ERC20 is ERC20_Interface {
    using SafeMath for uint256;

    // #####################
    // CONTRACT VARIABLES
    // #####################

    mapping (address => uint256) public _balances;
    mapping (address => mapping (address => uint256)) public _allowed;
    uint256 public _totalSupply;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    function allowance(address owner, address spender) public view returns (uint) {
        return _allowed[owner][spender];
    }

    // #####################
    // FUNCTIONS
    // #####################

    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(value <= _allowed[from][msg.sender]);

        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        return true;
    }


    function _transfer(address from, address to, uint256 value) internal {
        require(value <= _balances[from]);
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }
}