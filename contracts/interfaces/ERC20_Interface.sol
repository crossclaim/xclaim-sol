// erc20.sol -- API for the ERC20 token standard

// See <https://github.com/ethereum/EIPs/issues/20>.

pragma solidity ^0.5.0;

contract ERC20_Interface {

    // #####################
    // CONTRACT VARIABLES
    // #####################

    function totalSupply() public view returns (uint);
    function balanceOf(address owner) public view returns (uint);
    function allowance(address owner, address spender) public view returns (uint);

    // #####################
    // FUNCTIONS
    // #####################

    function approve(address spender, uint value) public returns (bool);
    function transfer(address to, uint value) public returns (bool);
    function transferFrom(address from, address to, uint value) public returns (bool);
    
    // #####################
    // EVENTS
    // #####################
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
}