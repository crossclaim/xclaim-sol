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

    constructor (address _relay) public {
        // issuer
        _issuerCollateral = 0;
        // relay
        authorizeRelayer(_relay);
        // collateral
        _minimumCollateralIssuer = 1 wei;
    }

    // ---------------------
    // SETUP
    // ---------------------

    // Relayers
    function authorizeRelayer(address toRegister) public {
        /* TODO: who authroizes this? */
        // Does the relayer need to provide collateral?
        require(_relayer == address(0));
        require(msg.sender != _relayer);

        _relayer = toRegister;
        btcRelay = BTCRelay(toRegister);
        emit AuthorizedRelayer(toRegister);
    }

    function revokeRelayer(address toUnlist) public {
        // TODO: who can do that?
        _relayer = address(0);
        btcRelay = BTCRelay(address(0));
        emit RevokedRelayer(_relayer);
    }

    // ---------------------
    // ISSUE
    // ---------------------

    function issueCol(address receiver, uint256 amount, bytes data) public {
        /* Can be called by anyone */
        // BTCRelay verifyTx callback
        bool result = _verifyTx(data);

        if (result) {
            // issue tokens
            _totalSupply += amount;
            _balances[receiver] += amount;

            emit Issue(msg.sender, receiver, amount, data);
            return;
        } else {
            // abort issue
            _issuerCommitedTokens -= amount;
            _userCommitedCollateral[msg.sender] = CommitedCollateral(0,0);

            emit AbortIssue(msg.sender, receiver, amount, data);
            return;
        }
    }

    function issueHTLC(address receiver, uint256 amount, bytes data) public {
        // TODO: data is not required in the SGX centralised case
        /* This method can only be called by an Issuer */
        // This method is only called by the issuer during the timelock
        // require(msg.sender == relayer); 

        bool result = _verifyTx(data);

        if (result) {
            // issue tokens
            _totalSupply += amount;
            _balances[receiver] += amount;

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
        require(_balances[redeemer] >= amount);

        // need to lock tokens

        // for testing
        uint256 time = 1 seconds;

        _redeemRequestId++;
        _redeemRequestList.push(_redeemRequestId);
        _redeemRequestMapping[_redeemRequestId] = RedeemRequest(redeemer, amount, (now + time));

        emit Redeem(redeemer, msg.sender, amount, data, _redeemRequestId);
    }

    // TODO: make these two functions into one
    function redeemConfirm(address redeemer, uint256 id, bytes data) public {
        require(_redeemRequestMapping[id].redeemTime > now);
        require(_redeemRequestMapping[id].value <= _balances[redeemer]);

        bool result = _verifyTx(data);

        _balances[redeemer] -= _redeemRequestMapping[id].value;
        _totalSupply -= _redeemRequestMapping[id].value;
        // increase token amount of issuer that can be used for issuing
        emit RedeemSuccess(redeemer, id);
    }

    function reimburse(address redeemer, uint256 id, bytes data) public {
        require(_redeemRequestMapping[id].redeemTime < now);
        require(msg.sender == _redeemRequestMapping[id].redeemer);

        // bool result = _verifyTx(data);

        _issuerCollateral -= _redeemRequestMapping[id].value;
        _balances[redeemer] -= _redeemRequestMapping[id].value;

        redeemer.transfer(_redeemRequestMapping[id].value);
        
        emit Reimburse(redeemer, _issuer, _redeemRequestMapping[id].value);
    }

    // ---------------------
    // REPLACE
    // ---------------------

    function replace(bytes data) public {
        // SGX only calls this if BTC tx is valid, BTCRelay requires call to check tx
        require(_issuerReplace);
        require(msg.sender == _issuer);
        require(_issuerReplaceTimelock > now);

        bool result = _verifyTx(data);

        _issuer = _issuerCandidate;
        _issuerCandidate = address(0);
        _issuerReplace = false;
        _issuer.transfer(_issuerCollateral);

        emit Replace(_issuerCandidate, _issuerCollateral);
    }

    // ---------------------
    // HELPERS
    // ---------------------

    function _verifyHTLC() private returns (bool) {
        // TODO: store bytes
        // signature
        // locktime
        // script
        bytes memory rawTx = "0x8c14f0db3df150123e6f3dbbf30f8b955a8249b62ac1d1ff16284aefa3d06d87";
        uint256 txIndex = 0;
        uint256[] memory merkleSibling = new uint256[](2);
        merkleSibling[0] = uint256(sha256("0xfff2525b8931402dd09222c50775608f75787bd2b87e56995a7bdd30f79702c4"));
        merkleSibling[1] = uint256(sha256("0x8e30899078ca1813be036a073bbf80b86cdddde1c96e9e9c99e9e3782df4ae49"));
        uint256 blockHash = uint256(sha256("0x0000000000009b958a82c10804bd667722799cc3b457bc061cd4b7779110cd60"));

        uint256 result = btcRelay.verifyTx(rawTx, txIndex, merkleSibling, blockHash);

        return true;
    }

    function _verifyTx(bytes data) private returns (bool verified) {
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
}