pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract Swap {
    using SafeMath for uint256;

    struct TradeOffer {
        address tokenParty;
        address ethParty;
        uint256 tokenAmount;
        uint256 ethAmount;
        bool completed;
    }
    mapping(uint256 => TradeOffer) public _tradeOfferStore;
    uint256 public _tradeOfferId; //todo: do we need this?

    // ---------------------
    // SWAP
    // ---------------------

    function offerTrade(uint256 tokenAmount, uint256 ethAmount, address ethParty) public {
        require(_balances[msg.sender] >= tokenAmount, "Insufficient balance");

        _balances[msg.sender] -= tokenAmount;
        _tradeOfferStore[_tradeOfferId] = TradeOffer(msg.sender, ethParty, tokenAmount, ethAmount, false);
        
        emit NewTradeOffer(_tradeOfferId, msg.sender, tokenAmount, ethParty, ethAmount);

        _tradeOfferId += 1;
    }

    function acceptTrade(uint256 offerId) payable public {
        /* Verify offer exists and the provided ether is enough */
        require(_tradeOfferStore[offerId].completed == false, "Trade completed");
        require(msg.value >= _tradeOfferStore[offerId].ethAmount, "Insufficient amount");

        /* Complete the offer */
        _tradeOfferStore[offerId].completed = true;
        _balances[msg.sender] = _balances[msg.sender] + _tradeOfferStore[offerId].tokenAmount;
        
        _tradeOfferStore[offerId].tokenParty.transfer(msg.value);

        emit Trade(offerId, _tradeOfferStore[offerId].tokenParty, _tradeOfferStore[offerId].tokenAmount, msg.sender, msg.value);
    }
}