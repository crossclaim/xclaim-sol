// Copyright (C) 2019 Alexei Zamyatin and Dominik Harz
// 
// This file is part of XCLAIM.
// 
// XCLAIM is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// XCLAIM is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with XCLAIM.  If not, see <http://www.gnu.org/licenses/>.

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
        address relay) 
        public {
        _name = myname;
        _symbol = mysymbol;
        _granularity = mygranularity;
        registerRelay(relay);
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