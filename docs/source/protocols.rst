.. index:: ! protocol

.. _protocols:

XClaim Protocols
================

XClaim consists of four different protocols: Issue, Swap, Redeem, and Replace.

Issue
-----


Swap
----

    /**
    * Offer a trade of tokens for ether.
    * @param tokenAmount - amount of tokens to be exchanged
    * @param ethAmount - amount of Ether to be exchanged
    * @param ethParty - user to exchange tokens for ether with
    *
    * ASSERT:
    * -) Sender actually owns the specified tokens.
    */
    function offerTrade(uint256 tokenAmount, uint256 ethAmount, address ethParty) public;

Redeem
------

    /**
    * Initiates the redeeming of backed-tokens in the native cryptocurrency. Redeemed tokens are 'burned' in the process.
    * @ redeemer - redeemer address
    * id of the token struct to be redeemed (and hence burned)
    * @ data - data, contains the 'redeem' transaction to be signed by the issuer
    *
    * ASSERT:
    * -) redeemer actually owns the given amount of tokens (including transaction fees in the native blockchain)
    *
    * TODO: optional: add checks - is the first 'lock' TX still unspent and does this tx actually spend from the first 'lock' tx correctly. Will require call to relay.
    */
    function redeem(address redeemer, uint256 amount, bytes data) public;