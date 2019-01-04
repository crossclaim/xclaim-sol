pragma solidity ^0.5.0;

contract Verify {

    function _verifyTx(bytes memory data) private returns (bool verified) {
        // data from line 256 https://github.com/ethereum/btcrelay/blob/develop/test/test_btcrelay.py
        bytes memory rawTx = "0x8c14f0db3df150123e6f3dbbf30f8b955a8249b62ac1d1ff16284aefa3d06d87";
        uint256 txIndex = 0;
        uint256[] memory merkleSibling = new uint256[](2);
        merkleSibling[0] = uint256(sha256("0xfff2525b8931402dd09222c50775608f75787bd2b87e56995a7bdd30f79702c4"));
        merkleSibling[1] = uint256(sha256("0x8e30899078ca1813be036a073bbf80b86cdddde1c96e9e9c99e9e3782df4ae49"));
        uint256 blockHash = uint256(sha256("0x0000000000009b958a82c10804bd667722799cc3b457bc061cd4b7779110cd60"));

        bool success  = super._relayer.call(abi.encodeWithSignature("verifyTx(bytes, uint256, uint256[], uint256)"), rawTx, txIndex, merkleSibling, blockHash);
        // uint256 result = btcRelay.verifyTx(rawTx, txIndex, merkleSibling, blockHash);

        // TODO: Implement this correctly, now for testing only
        if (data.length == 0) {
            return false;
        } else {
            return true;
        }
    }
}