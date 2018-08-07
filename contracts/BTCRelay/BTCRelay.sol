pragma solidity ^0.4.24;

/// @title BTCRelay
/// @author Dominik Harz
/// @dev BTCRelay implementation with only the verifyTx part for testing purposes
///  
import "openzeppelin-solidity/contracts/math/SafeMath.sol";


contract BTCRelay {
    using SafeMath for uint;

    /**
    * Returns the hash of tx (raw bytes) if the tx is in the block given by 'txBlockHash'
    * and the block is in Bitcoin's main chain (ie not a fork).
    * Returns 0 if the tx is exactly 64 bytes long (to guard against a Merkle tree
    * Collision) or fails verification.
    * the merkle proof is represented by 'txIndex', 'sibling', where:
    *  - txIndex is the index of the tx within the block
    *  - merkleSibling are the merkle siblings of tx 
    **/
    function verifyTx(bytes rawTx, uint256 txIndex, uint256[] merkleSibling, uint256 blockHash) public returns (uint256 txHash) {
        // double hash and XOR
        txHash = uint(~ (sha256(abi.encodePacked(sha256(abi.encodePacked(rawTx))))));

        if (rawTx.length == 64) {
            emit VerifyTransaction(txHash, 0);
            return 0;
        }

        bool result = verifyHash(txHash, txIndex, merkleSibling, blockHash);

        if (result) {
            emit VerifyTransaction(txHash, 1);
            return txHash;
        }

        emit VerifyTransaction(txHash, 0);
        return 0;
    }

    // TODO: implement this
    // Dirty hacky stuff
    function verifyHash(uint256 txHash, uint256 txIndex, uint256[] merkleSibling, uint256 blockHash) private returns (bool) {        
        if (hasSixConfirms(blockHash) == false) {
            return false;
        }

        if (isInMainChain(blockHash) == false) {
            return false;
        }
        
        uint256 merkle = computeMerkle(txHash, txIndex, merkleSibling);
        uint256 realMerkleRoot = getMerkleRoot(blockHash);

        if (merkle == realMerkleRoot) {
            return true;
        }

        // return false;
        return true;
    }

    // TODO: implement this
    // Dirty hacky stuff
    function hasSixConfirms(uint256 blockHash) private returns (bool) {
        for (uint256 i = 0; i<6; i++) {
            // check block hashes
            if (blockHash == 0) {
                return (false); 
            }
        }
        return (true);
    }

    // TODO: implement this
    // Dirty hacky stuff
    function isInMainChain(uint256 blockHash) private returns (bool){
        if (blockHash == 0) {
            return true;
        }
        return true;        
    }

    function computeMerkle(uint256 txHash, uint256 txIndex, uint256[] merkleSibling) private returns (uint256 resultHash) {
        uint256 left;
        uint256 right;
        uint256 sideOfSibling;
        uint256 index = txIndex;
        uint256 proofHex;

        resultHash = txHash;

        for (uint i; i<merkleSibling.length; i++) {
            proofHex = merkleSibling[i];

            sideOfSibling = index % 2;

            if (sideOfSibling == 1) {
                left = proofHex;
                right = resultHash;
            } else if (sideOfSibling == 0) {
                left = resultHash;
                right = proofHex;
            }

            resultHash = concatHash(left, right);

            index /= 2;
        }

        return (resultHash);
    }

    // TODO: implement this
    // Dirty hacky stuff
    function getMerkleRoot(uint256 blockHash) private returns (uint256) {
        if (blockHash == 0) {
            return 0;
        }
        return 0;
    }

    function concatHash(uint256 tx1, uint256 tx2) private returns (uint256) {
        bytes32 tx1_b = bytes32(tx1);
        bytes32 tx2_b = bytes32(tx2);
        
        // Note "~" flips the bits
        tx1_b = ~ tx1_b;
        tx2_b = ~ tx2_b;

        uint256 hashtx = uint256(~ sha256(abi.encodePacked(sha256(abi.encodePacked(tx1_b, tx2_b)))));
        return hashtx;
    }

    event VerifyTransaction(uint256 indexed txHash, uint256 indexed returnCode);
}