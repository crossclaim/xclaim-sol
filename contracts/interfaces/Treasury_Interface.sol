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

pragma solidity ^0.5.0;

/**
* Base Treasury Interface
*/
contract Treasury_Interface {

    // #####################
    // CONTRACT VARIABLES
    // #####################

    function getVaults() public view returns(address[] memory);

    function getRelay() public view returns (address);

    function getVaultCollateral(address vault) public view returns (uint256);

    function getReplacePeriod() public view returns (uint256);

    // #####################
    // FUNCTIONS
    // #####################

    // ---------------------
    // PRICE ORACLE
    // ---------------------
    function getConversionRate() public returns (uint256);
    
    function setConversionRate(uint256 rate) public returns (bool);

    // ---------------------
    // VAULT
    // ---------------------

    function registerVault(address payable toRegister) public payable returns (bool);
    
    // ---------------------
    // RELAY
    // ---------------------

    function registerRelay(address toRegister) public returns (bool);

    function revokeRelayer(address toUnlist) public returns (bool);

    event RegisterVault(address indexed vault, uint collateral, uint id);

    event RegisteredRelayer(address indexed relayer);

    event RevokedRelayer(address indexed relayer);

    // ---------------------
    // ISSUE
    // ---------------------

    function registerIssue(address receiver, uint256 amount, address payable vault, bytes memory btcAddress) public payable returns (bool); 

    function confirmIssue(address receiver, bytes memory data) public returns (bool);

    function abortIssue(address receiver) public returns (bool);

    event RegisterIssue(address indexed sender, uint256 value, uint256 timelock);

    event IssueToken(address indexed issuer, address indexed receiver, uint value, bytes data);

    event AbortIssue(address indexed issuer, address indexed receiver, uint value);

    // ---------------------
    // SWAP
    // ---------------------
    function offerSwap(uint256 tokenAmount, uint256 ethAmount, address payable ethParty) public returns (bool);

    function acceptSwap(uint256 offerId) payable public returns (bool);
    
    event NewTradeOffer(uint256 id, address indexed tokenParty, uint256 tokenAmount, address indexed ethParty, uint256 ethAmount);

    event AcceptTrade(uint256 transferOfferId, address indexed tokenParty, uint256 tokenAmount, address indexed ethParty, uint256 ethAmount);

    // ---------------------
    // REDEEM

    // ---------------------

    function requestRedeem(address payable vault, address payable redeemer, uint256 amount, bytes memory btcOutput) public returns (bool);

    function confirmRedeem(uint256 id, bytes memory data) public returns (bool);

    function reimburseRedeem(address payable redeemer, uint256 id) public returns (bool);

    event RequestRedeem(address indexed redeemer, address indexed issuer, uint value, bytes data, uint id);

    event ConfirmRedeem(address indexed redeemer, uint256 id);

    event Reimburse(address indexed redeemer, address indexed issuer, uint value);

    // ---------------------
    // REPLACE
    // ---------------------
    function requestReplace() public returns (bool);

    function lockReplace(address vault) public payable returns (bool);

    function confirmReplace(address payable vault, bytes memory data) public returns (bool);

    function abortReplace(address vault) public returns (bool);

    event RequestReplace(address indexed issuer, uint256 amount, uint256 timelock);

    event LockReplace(address indexed candidate, uint256 amount);

    event ConfirmReplace(address indexed new_issuer, uint256 amount);

    event AbortReplace(address indexed candidate, uint256 amount);
}