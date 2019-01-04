pragma solidity ^0.5.0;

import "../utils/Verify.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract Replace {
    using SafeMath for uint256;
    // ---------------------
    // REPLACE
    // ---------------------

    function requestReplace() public {
        require(msg.sender == _issuer);
        require(!_issuerReplace);

        _issuerReplace = true;
        _issuerReplaceTimelock = now + 1 seconds;

        emit RequestReplace(_issuer, _issuerCollateral, _issuerReplaceTimelock);
    }

    function lockCol() public payable {
        require(_issuerReplace, "Issuer did not request change");
        require(msg.sender != _issuer, "Needs to be replaced by a non-issuer");
        require(msg.value >= _issuerCollateral, "Collateral needs to be high enough");

        _issuerCandidate = msg.sender;

        emit LockReplace(_issuerCandidate, msg.value);
    }

    function replace(bytes data) public {
        // SGX only calls this if BTC tx is valid, BTCRelay requires call to check tx
        require(_issuerReplace);
        require(msg.sender == _issuer);
        require(_issuerReplaceTimelock > now);

        bool result = Verify._verifyTx(data);

        _issuer = _issuerCandidate;
        _issuerCandidate = address(0);
        _issuerReplace = false;
        _issuer.transfer(_issuerCollateral);

        emit Replace(_issuerCandidate, _issuerCollateral);
    }

    function abortReplace() public {
        require(_issuerReplace);
        require(msg.sender == _issuerCandidate);
        require(_issuerReplaceTimelock < now);

        _issuerReplace = false;

        _issuerCandidate.transfer(_issuerCollateral);

        emit AbortReplace(_issuerCandidate, _issuerCollateral);
    }
}