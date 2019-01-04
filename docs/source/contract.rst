XClaim contract
===============

Properties
----------

Granularity:
Get the smallest part of the token that’s not divisible.
The following rules MUST be applied with respect to the granularity:
The granularity value MUST NOT be changed.
The granularity value MUST be greater or equal to 1.
Any minting, send or burning of tokens MUST be a multiple of the granularity value.
Any operation that would result in a balance that’s not a multiple of the granularity value, MUST be considered invalid and the transaction MUST throw.
NOTE: Most of the tokens SHOULD be fully partitionable, i.e. this function SHOULD return 1 unless there is a good reason for not allowing any partition of the token.


Setup
-----

    /**
    * Registers / unlists a new issuer
    * @param toRegister - address to be registered/unlisted
    * data - [OPTIONAL] data, contains issuers address in the backed cryptocurrency and
    *         any other necessary info for validating the issuer
    *
    * ASSERT: sufficient collateral provided
    *
    * CAUTION: may have to be set to private in SGX version, if no modification to issuers is wanted
    */
    function authorizeIssuer(address toRegister) public payable;