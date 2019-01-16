pragma solidity ^ 0.5.0;

import "./components/Treasury.sol";

contract XCLAIM is Treasury {

    string public _name;
    string public _symbol;
    uint256 public _granularity;

    constructor (
        string memory myname, 
        string memory mysymbol, 
        uint256 mygranularity,
        address relayer) 
        public {
        _name = myname;
        _symbol = mysymbol;
        _granularity = mygranularity;
        super.registerRelay(relayer);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function granularity() public view returns (uint256) {
        return _granularity;
    }

}