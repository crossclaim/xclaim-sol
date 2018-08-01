pragma solidity ^0.4.24;

/// keep this for later implementations with multiple issuers

import "openzeppelin-solidity/contracts/math/SafeMath.sol";


contract ERCXXX_SGX_multi {
    address[] public issuersList;
    mapping(address => bool) public issuers;

    function issuerList() public view returns(address[]) {
        return issuersList;
    }

    function authorizeIssuer(address toRegister) public payable {
        // TODO: Do we need the data argument?
        // require(msg.value >= minimumCollateral);
        issuers[toRegister] = true;
        issuersList.push(toRegister);
        // emit AuthorizedIssuer(toRegister, msg.value);
    }

    function revokeIssuer(address toUnlist) private {
        /* This method can only be called by the current Issuer */
        // require(issuers[msg.sender]);
        // require(msg.sender == toUnlist);
        require(issuersList.length > 0);

        issuers[toUnlist] = false;
        // Remove toUnlist without order
        for (uint256 i = 0; i < issuersList.length; i++) {
            if (issuersList[i] == toUnlist) {
                uint256 lastIndex = issuersList.length - 1;

                if (i == lastIndex) {
                    delete issuersList[i];
                } else {
                    issuersList[i] = issuersList[lastIndex];
                    delete issuersList[lastIndex];
                }

                issuersList.length--;
            }
        }

        // emit RevokedIssuer(toUnlist);
    }
}