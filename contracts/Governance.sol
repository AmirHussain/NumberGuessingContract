// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import '@openzeppelin/contracts/access/Ownable.sol';
import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

// import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
// import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import './interfaces/ISwapRouter.sol';
import './Math.sol';
import 'hardhat/console.sol';

contract Governance is Ownable {
    address[] TokenAddresses;

    struct Token {
        address tokenAddress;
        string name;
        string symbol;
        string icon;
        string abiJSON;
        address pedgeToken;
        bool isPedgeToken;
        bool isDeleted;
    }

    struct TokenAggregators {
        address aggregatorAddress;
        int decimals;
        address targetToken;
        bool isApplicable;
    }

    struct TokenBorrowLimitations {
        uint CollateralFator;
        uint LiquidationThreshold;
        uint LiquidationPenalty;
        uint ProtocolShare;
    }

    struct TokenAdaptiveLimitations {
        string Utilization;
        string Withdraw;
        string Borrow;
        bool Replinish;
        bool Redeem;
    }

    mapping(address => Token) public tokens;
    mapping(address => TokenAggregators[]) public aggregators;
    mapping(address => TokenBorrowLimitations) public borrowLimitations;
    mapping(address => TokenAdaptiveLimitations[]) public adaptiveLimitations;
    uint public TotalTokens = 0;

    constructor() {}

 function AddOrUpdateTokenBorrowLimiations(
        address _tokenAddress,
         uint CollateralFator,
        uint LiquidationThreshold,
        uint LiquidationPenalty,
        uint ProtocolShare
    ) public returns (bool){
        borrowLimitations[_tokenAddress].CollateralFator = CollateralFator;
        borrowLimitations[_tokenAddress].LiquidationThreshold = LiquidationThreshold;
        borrowLimitations[_tokenAddress].LiquidationPenalty = LiquidationPenalty;
        borrowLimitations[_tokenAddress].ProtocolShare = ProtocolShare;
        return true;
    }

    function AddAggregators(
        address _tokenAddress,
        address _aggregatorAddress,
        int _decimals,
        address _targetToken,
        bool _isApplicable
    ) public returns (bool) {
        TokenAggregators memory aggregator;
        aggregator.aggregatorAddress = _aggregatorAddress;
        aggregator.decimals = _decimals;
        aggregator.targetToken = _targetToken;
        aggregator.isApplicable = _isApplicable;
        aggregators[_tokenAddress].push(aggregator);
        return true;
    }

    function UpdateAggregators(
        address _tokenAddress,
        address _aggregatorAddress,
        bool _isApplicable
    ) public returns (bool){
        for (uint i = 0; i < aggregators[_tokenAddress].length; i++) {
            if( aggregators[_tokenAddress][i].aggregatorAddress==_aggregatorAddress){
               aggregators[_tokenAddress][i].isApplicable=_isApplicable;
            }
        }

        return true;
    }

    function AddOrUpdateToken(
        address _tokenAddress,
        string memory _symbol,
        string memory _name,
        string memory _icon,
        string memory _abiJSON,
        address _pedgeToken,
        bool _isPedgeToken,
        bool _isDeleted,
        bool _new
    ) public returns (bool){
        if (_new) {
            TotalTokens += 1;
            TokenAddresses.push(_tokenAddress);
        }
        tokens[_tokenAddress].symbol = _symbol;
        tokens[_tokenAddress].name = _name;
        tokens[_tokenAddress].icon = _icon;
        tokens[_tokenAddress].abiJSON = _abiJSON;
        tokens[_tokenAddress].pedgeToken = _pedgeToken;
        tokens[_tokenAddress].isPedgeToken = _isPedgeToken;
        tokens[_tokenAddress].isDeleted = _isDeleted;
        return true;
    }

    function deleteToken(address tokenAddress, bool _isDeleted) public returns (bool){
        TotalTokens -= 1;
        tokens[tokenAddress].isDeleted = _isDeleted;
        return true;
    }

    function getAllToken() public view returns (Token[] memory) {
        Token[] memory memoryArray = new Token[](TotalTokens);
        for (uint i = 0; i < TotalTokens; i++) {
            memoryArray[i] = tokens[TokenAddresses[i]];
        }
        return memoryArray;
    }

    function getAllTokenAddresses() public view returns (address[] memory) {
        return TokenAddresses;
    }

    function getToken(address _tokenAddress) public view returns (Token memory) {
        return tokens[_tokenAddress];
    }
    
    function getTokenBorrowLimiatations(address _tokenAddress) public view returns (TokenBorrowLimitations memory) {
        return borrowLimitations[_tokenAddress];
    }
}
