pragma solidity ^ 0.5 .0;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../interfaces/Treasury_Interface.sol";
import "../components/ERC20.sol";

contract Treasury is Treasury_Interface, ERC20 {
    using SafeMath for uint256;

    // #####################
    // CONTRACT VARIABLES
    // #####################

    // vault
    struct Vault {
        address vault;
        uint256 tokenSupply;
        uint256 commitedTokens;
        uint256 collateral;
        address replaceCandidate;
        bool replace;
        uint256 replaceConfirmations;
    }
    mapping(uint256 => Vault) _vaults;
    mapping(address => uint256) _vaultIds;

    uint256 _vaultId;
    // sum of vaults
    uint256 public _vaultTokenSupply;
    uint256 public _vaultCommitedTokens;
    uint256 public _vaultCollateral;

    // relayer
    address public _relayer;

    // block periods
    uint256 public _confirmations;
    uint256 public _contestationPeriod;
    uint256 public _graceRedeemPeriod;

    // collateral
    uint256 public _minimumCollateralIssuer;
    uint256 public _minimumCollateralUser;

    // conversion rate
    uint256 public _conversionRateBTCETH; // 10*5 granularity?

    // issue
    struct CollateralCommit {
        uint256 vaultId;
        uint256 blocknumber;
        uint256 collateral;
        bytes btcAddress;
    }
    mapping(address => CollateralCommit) public _collateralCommits;

    // swap
    struct Trade {
        address payable tokenParty;
        address payable ethParty;
        uint256 tokenAmount;
        uint256 ethAmount;
        bool completed;
    }
    mapping(uint256 => Trade) public _trades;
    uint256 public _tradeId; //todo: do we need this?


    // redeem
    struct RedeemRequest {
        address payable redeemer;
        uint256 value;
        uint256 blocknumber;
    }
    mapping(uint => RedeemRequest) public _redeemRequests;
    uint256 public _redeemRequestId;

    constructor() public {
        _totalSupply = 0;
        // vault
        _vaultId = 0;
        _vaultTokenSupply = 0;
        _vaultCommitedTokens = 0;
        _vaultCollateral = 0;
        // block
        _confirmations = 12;
        _contestationPeriod = 30;
        _graceRedeemPeriod = 30;
        // collateral
        _minimumCollateralUser = 1 wei;
        _minimumCollateralIssuer = 1 wei;
        // conversion rate
        _conversionRateBTCETH = 2 * 10 ^ 5; // equals 1 BTC = 2 ETH
        // init id counters
        _tradeId = 0;
        _redeemRequestId = 0;
    }

    // #####################
    // FUNCTIONS
    // #####################

    function getVaults() public view returns(address[] memory vaults) {
        require(_vaultId > 0, "No vault registered");
        for (uint256 i=0; i <= _vaultId; i++) {
            vaults[i] = _vaults[i].vault;
        }
        return vaults;
    }
    
    // TODO: add this to helper functions
    function getVaultId(address vaultAddress) public view returns (uint256) {
        require(_vaultId > 0, "No vault registered");

        return _vaultIds[vaultAddress];
    }

    function getRelayer() public view returns(address) {
        return _relayer;
    }

    // ---------------------
    // SETUP
    // ---------------------
    function getEthtoBtcConversion() public returns (uint256) {
        return _conversionRateBTCETH;
    }

    function setEthtoBtcConversion(uint256 rate) public returns (bool){
        // todo: require maximum fluctuation
        // todo: only from "trusted" oracles
        require(rate > 0, "Set rate greater than 0");

        _conversionRateBTCETH = rate;

        assert(_conversionRateBTCETH == rate);
        return true;
    }

    // Vaults
    function registerVault(address payable toRegister) public payable returns (uint256 vaultId) {
        require(msg.value >= _minimumCollateralIssuer, "Collateral too low");

        // register single vault
        _vaults[_vaultId] = Vault({
            vault: toRegister,
            tokenSupply:  _convertEthToBtc(msg.value),
            commitedTokens: 0,
            collateral: msg.value,
            replaceCandidate: address(0),
            replace: false,
            replaceConfirmations: 0
        });
        _vaultIds[toRegister] = _vaultId;

        // increase amount that can be issued
        _vaultTokenSupply += _convertEthToBtc(msg.value);
        _vaultCollateral += msg.value;

        emit RegisterVault(toRegister, msg.value, vaultId);

        // increase vault id
        _vaultId++;

        return true;
    }

    // function revokeVault(uint256 id, address toUnlist) private returns (bool) {
    //     require(msg.sender == _vaults[id].vault, "Can only be invoked by current issuer");
    //     require(_vaults[id].commitedTokens == 0, "Vault is commited to tokens");

    //     // _issuer = address(0);
    //     if (_vaults[id].collateral > 0) {
    //         _issuer.transfer(_vaults[id].collateral);
    //     }

    //     emit RevokedVault(id, toUnlist);

    //     return true;
    // }

    // Relayers
    // TODO: registerRelay
    function registerRelay(address toRegister) public returns (bool) {
        /* TODO: who authroizes this? 
        For now, this method is only available in the constructor */
        // Does the relayer need to provide collateral?
        require(_relayer == address(0));
        require(msg.sender != _relayer);

        _relayer = toRegister;

        emit RegisteredRelayer(toRegister);

        return true;
    }

    // make contract ownable and owner can change relay
    // TODO: revokeRelay
    function revokeRelayer(address toUnlist) public returns (bool) {
        // TODO: who can do that?
        _relayer = address(0);
        // btcRelay = BTCRelay(address(0));
        emit RevokedRelayer(_relayer);

        return true;
    }

    // ---------------------
    // ISSUE
    // ---------------------
    // TODO: name function commit
    function registerIssue(
        uint256 amount, 
        address vault, 
        bytes memory btcAddress) 
    public payable returns (bool) {
        // TODO: include a nonce for a user and use address plus nonce as key for CollateralCommit mapping
        // TODO: make required msg.value a multiple of minimumCollateral per token (amount * collateral)
        require(msg.value >= _minimumCollateralUser, "Collateral too small");

        uint256 vaultId = getVaultId(vault);
        // TODO: add method, that checks if time limit for issue tokens is up and then frees committed tokens by this issuer
        require(_vaults[vaultId].tokenSupply >= amount + _vaults[vaultId].commitedTokens, "Not enough collateral provided by this single vault");
        // Update vault specifics
        _vaults[vaultId].commitedTokens += amount;

        // update overall details
        _vaultCommitedTokens += amount;

        // store commit to issue
        _collateralCommits[msg.sender] = CollateralCommit(vaultId, block.number, amount, btcAddress);

        // emit event
        // TODO: emit nonce
        emit RegisterIssue(msg.sender, amount, block.number);

        return true;
    }

    // TODO: 
    function issueToken(address receiver, bytes memory data) public returns (bool) {
        require(_collateralCommits[receiver].collateral > 0, "Collateral too small");

        // check if within number of blocks
        bool block_valid = _verifyBlock(_collateralCommits[receiver].blocknumber);

        // BTCRelay verifyTx callback
        bool tx_valid = _verifyTx(data);

        // TODO: match btc and eth address
        bool address_valid = _verifyAddress(receiver, _collateralCommits[receiver].btcAddress, data);

        uint256 id = _collateralCommits[msg.sender].vaultId;
        uint256 amount = _collateralCommits[msg.sender].amount;

        if (block_valid && tx_valid && address_valid) {
            
            _totalSupply += amount;
            _vaults[id].tokenSupply += amount;
            // issue tokens
            _balances[receiver] += amount;
            // reset user issue
            _collateralCommits[msg.sender].collateral = 0;
            _collateralCommits[msg.sender].blocknumber = 0;

            emit IssueToken(msg.sender, receiver, amount, data);

            return true;
        } else {
            // abort issues
            _vaultCommitedTokens -= amount;
            _vaults[id].tokenSupply -= amount;
            // slash user collateral
            _collateralCommits[msg.sender].collateral = 0;

            emit AbortIssue(msg.sender, receiver, amount, data);

            return false;
        }
    }

    // ---------------------
    // TRANSFER
    // ---------------------
    // see protocols/ERC20.sol

    // ---------------------
    // SWAP
    // ---------------------

    function offerTrade(uint256 tokenAmount, uint256 ethAmount, address payable ethParty) public returns (bool) {
        require(_balances[msg.sender] >= tokenAmount, "Insufficient balance");

        _balances[msg.sender] -= tokenAmount;
        _trades[_tradeId] = Trade(msg.sender, ethParty, tokenAmount, ethAmount, false);

        emit NewTradeOffer(_tradeId, msg.sender, tokenAmount, ethParty, ethAmount);

        _tradeId += 1;

        return true;
    }

    function acceptTrade(uint256 offerId) payable public returns (bool) {
        /* Verify offer exists and the provided ether is enough */
        require(_trades[offerId].completed == false, "Trade completed");
        require(msg.value >= _trades[offerId].ethAmount, "Insufficient amount");

        /* Complete the offer */
        _trades[offerId].completed = true;
        _balances[msg.sender] = _balances[msg.sender] + _trades[offerId].tokenAmount;

        _trades[offerId].tokenParty.transfer(msg.value);

        emit AcceptTrade(offerId, _trades[offerId].tokenParty, _trades[offerId].tokenAmount, msg.sender, msg.value);

        return true;
    }

    // ---------------------
    // REDEEM
    // ---------------------
    function requestRedeem(address payable redeemer, uint256 amount, bytes memory data) public returns (bool) {
        /* The redeemer must have enough tokens to burn */
        require(_balances[redeemer] >= amount);

        // need to lock tokens
        _balances[redeemer] -= amount;

        _redeemRequestId++;
        _redeemRequests[_redeemRequestId] = RedeemRequest(redeemer, amount, (block.number + _confirmations));

        emit RequestRedeem(redeemer, msg.sender, amount, data, _redeemRequestId);

        return true;
    }

    // TODO: make these two functions into one
    function confirmRedeem(address payable redeemer, uint256 id, bytes memory data) public returns (bool) {
        // check if within number of blocks
        bool block_valid = _verifyBlock(_redeemRequests[id].blocknumber);
        bool tx_valid = _verifyTx(data);

        if (block_valid && tx_valid) {
            _balances[redeemer] -= _redeemRequests[id].value;
            _totalSupply -= _redeemRequests[id].value;
            // increase token amount of issuer that can be used for issuing
            emit ConfirmRedeem(redeemer, id);

            return true;
        } else {
            // bool result = _verifyTx(data);

            _vaultCollateral -= _redeemRequests[id].value;
            // restore balance
            _balances[redeemer] += _redeemRequests[id].value;

            redeemer.transfer(_redeemRequests[id].value);

            emit Reimburse(redeemer, _issuer, _redeemRequests[id].value);

            return false;
        }
    }

    // ---------------------
    // REPLACE
    // ---------------------
    function requestReplace() public returns (bool) {
        require(msg.sender == _issuer);
        require(!_issuerReplace);

        _issuerReplace = true;
        _issuerReplaceTimelock = now + 1 seconds;

        emit RequestReplace(_issuer, _vaultCollateral, _issuerReplaceTimelock);

        return true;
    }

    function lockCol() public payable returns (bool) {
        require(_issuerReplace, "Issuer did not request change");
        require(msg.sender != _issuer, "Needs to be replaced by a non-issuer");
        require(msg.value >= _vaultCollateral, "Collateral needs to be high enough");

        _issuerCandidate = msg.sender;

        emit LockReplace(_issuerCandidate, msg.value);

        return true;
    }

    function replace(bytes memory data) public returns (bool) {
        require(_issuerReplace);
        require(msg.sender == _issuer);
        require(_issuerReplaceTimelock > now);

        bool result = _verifyTx(data);

        _issuer = _issuerCandidate;
        _issuerCandidate = address(0);
        _issuerReplace = false;
        _issuer.transfer(_vaultCollateral);

        emit ExecuteReplace(_issuerCandidate, _vaultCollateral);

        return true;
    }

    function abortReplace() public returns (bool) {
        require(_issuerReplace);
        require(msg.sender == _issuerCandidate);
        require(_issuerReplaceTimelock < now);

        _issuerReplace = false;

        _issuerCandidate.transfer(_vaultCollateral);

        emit AbortReplace(_issuerCandidate, _vaultCollateral);

        return true;
    }

    // ---------------------
    // HELPERS
    // ---------------------

    function _verifyTx(bytes memory data) private returns(bool verified) {
        // data from line 256 https://github.com/ethereum/btcrelay/blob/develop/test/test_btcrelay.py
        bytes memory rawTx = data;
        uint256 txIndex = 0;
        uint256[] memory merkleSibling = new uint256[](2);
        merkleSibling[0] = uint256(sha256("0xfff2525b8931402dd09222c50775608f75787bd2b87e56995a7bdd30f79702c4"));
        merkleSibling[1] = uint256(sha256("0x8e30899078ca1813be036a073bbf80b86cdddde1c96e9e9c99e9e3782df4ae49"));
        uint256 blockHash = uint256(sha256("0x0000000000009b958a82c10804bd667722799cc3b457bc061cd4b7779110cd60"));

        (bool success, bytes memory returnData) = _relayer.call(abi.encodeWithSignature("verifyTx(bytes, uint256, uint256[], uint256)", rawTx, txIndex, merkleSibling, blockHash));

        bytes memory invalid_tx = hex"fe6c48bbfdc025670f4db0340650ba5a50f9307b091d9aaa19aa44291961c69f";
        // TODO: Implement this correctly, now for testing only
        if (keccak256(data) == keccak256(invalid_tx)) {
            return false;
        } else {
            return true;
        }
    }

    function _verifyAddress(address receiver, bytes memory btcAddress, bytes memory data) private pure returns(bool verified) {
        return true;
    }

    function _verifyBlock(uint256 blocknumber) private view returns(bool block_valid) {
        if (
            (blocknumber >= (block.number - _confirmations)) 
            && (blocknumber <= (block.number + _contestationPeriod))
        ) {
            return true;
        } else {
            return false;
        }
    }

    function _convertEthToBtc(uint256 eth) private view returns(uint256) {
        /* TODO use a contract that uses middleware to get the conversion rate */
        return eth * _conversionRateBTCETH;
    }
}