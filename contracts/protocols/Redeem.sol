pragma solidity ^0.5.0;

import "../utils/Verify.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract Redeem is Verify {
    using SafeMath for uint256;

    struct RedeemRequest {
        address redeemer;
        uint value;
        uint redeemTime;
    }
    mapping(uint => RedeemRequest) public _redeemRequestMapping;
    uint256[] public _redeemRequestList;
    uint256 public _redeemRequestId;

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

        bool result = Verify._verifyTx(data);

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
}