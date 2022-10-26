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
    using SafeMath for uint256;
    address[] TokenAddresses;

    struct Token {
        address tokenAddress;
        string  name;
        string  symbol;
        string  icon;
        string  abiJSON;
        address pedgeToken;
        bool    isPedgeToken;
        bool    isDeleted;
    }

    struct TokenAggregators {
        address aggregatorAddress;
        address tokenAddress;
        uint256 decimals;
        address targetToken;
        bool isApplicable;
    }

    struct TokenBorrowLimitations {
        address tokenAddress;
        uint256 CollateralFator;
        uint256 LiquidationThreshold;
        uint256 LiquidationPenalty;
        uint256 ProtocolShare;
        uint256 InitialBorrowRate;
        uint256 MAX_UTILIZATION_RATE;
        bool AllowStableJob;
    }

    struct TokenIntrestRateModel {
        uint256 OPTIMAL_UTILIZATION_RATE;
        uint256 StableRateSlope1;
        uint256 StableRateSlope2;
        uint256 VariableRateSlope1;
        uint256 VariableRateSlope2;
        uint256 BaseRate;
    }

    struct TokenAdaptiveLimitations {
        string Utilization;
        string Withdraw;
        string Borrow;
        bool Replinish;
        bool Redeem;
        bool IsApplicable;
    }

    mapping(address => Token) public tokens;
    mapping(address => TokenAggregators) public aggregators;
    mapping(address => TokenBorrowLimitations) public borrowLimitations;
    mapping(address => TokenIntrestRateModel) public intrestRateModel;
    mapping(address => TokenAdaptiveLimitations[]) public adaptiveLimitations;
    uint256 public TotalTokens = 0;

    constructor() {}

    function AddTokenAdaptiveLimitations(
        address _tokenAddress,
        string memory Utilization,
        string memory Withdraw,
        string memory Borrow,
        bool Replinish,
        bool Redeem
    ) public returns (bool) {
        TokenAdaptiveLimitations memory TAL;
        TAL.Utilization = Utilization;
        TAL.Withdraw = Withdraw;
        TAL.Borrow = Borrow;
        TAL.Replinish = Replinish;
        TAL.Redeem = Redeem;
        TAL.IsApplicable = true;
        adaptiveLimitations[_tokenAddress].push(TAL);
        return true;
    }

    function UpdateTokenAdaptiveLimitations(
        address _tokenAddress,
        uint256 _rowIndex,
        string memory Utilization,
        string memory Withdraw,
        string memory Borrow,
        bool Replinish,
        bool Redeem
    ) public returns (bool) {
        TokenAdaptiveLimitations memory TAL;
        TAL.Utilization = Utilization;
        TAL.Withdraw = Withdraw;
        TAL.Borrow = Borrow;
        TAL.Replinish = Replinish;
        TAL.Redeem = Redeem;
        adaptiveLimitations[_tokenAddress][_rowIndex] = TAL;
        return true;
    }

    function RemoveTokenAdaptiveLimitations(address _tokenAddress, uint256 _rowIndex) public returns (bool) {
        adaptiveLimitations[_tokenAddress][_rowIndex].IsApplicable = false;
        return true;
    }

    function getTokenAdaptiveLimitations(address _tokenAddress) public view returns (TokenAdaptiveLimitations[] memory) {
        return adaptiveLimitations[_tokenAddress];
    }

    function AddOrUpdateTokenIntrestRateModel(
        address _tokenAddress,
        uint256 OPTIMAL_UTILIZATION_RATE,
        uint256 StableRateSlope1,
        uint256 StableRateSlope2,
        uint256 VariableRateSlope1,
        uint256 VariableRateSlope2,
        uint256 BaseRate
    ) public returns (bool) {
        TokenIntrestRateModel memory irm;
        irm.OPTIMAL_UTILIZATION_RATE = OPTIMAL_UTILIZATION_RATE;
        irm.StableRateSlope1 = StableRateSlope1;
        irm.StableRateSlope2 = StableRateSlope2;
        irm.VariableRateSlope1 = VariableRateSlope1;
        irm.VariableRateSlope2 = VariableRateSlope2;
        irm.BaseRate = BaseRate;
        intrestRateModel[_tokenAddress] = irm;
        return true;
    }

    function AddOrUpdateTokenBorrowLimiations(
        address _tokenAddress,
        uint256 CollateralFator,
        uint256 LiquidationThreshold,
        uint256 LiquidationPenalty,
        uint256 ProtocolShare,
        uint256 InitialBorrowRate,
        uint256 MAX_UTILIZATION_RATE,
        bool AllowStableJob
    ) public returns (bool) {
        TokenBorrowLimitations memory bL;
        bL.CollateralFator = CollateralFator;
        bL.LiquidationThreshold = LiquidationThreshold;
        bL.LiquidationPenalty = LiquidationPenalty;
        bL.ProtocolShare = ProtocolShare;
        bL.InitialBorrowRate = InitialBorrowRate;
        bL.MAX_UTILIZATION_RATE = MAX_UTILIZATION_RATE;
        bL.AllowStableJob = AllowStableJob;
        bL.tokenAddress = _tokenAddress;
        borrowLimitations[_tokenAddress] = bL;
        return true;
    }

    function AddAggregators(
        address _tokenAddress,
        address _aggregatorAddress,
        uint256 _decimals,
        address _targetToken,
        bool _isApplicable
    ) public returns (bool) {
        TokenAggregators memory aggregator;
        aggregator.aggregatorAddress = _aggregatorAddress;
        aggregator.decimals = _decimals;
        aggregator.tokenAddress = _tokenAddress;
        aggregator.targetToken = _targetToken;
        aggregator.isApplicable = _isApplicable;
        aggregators[_tokenAddress] = aggregator;
        return true;
    }

    function UpdateAggregators(
        address _tokenAddress,
        address _aggregatorAddress,
        uint256 _decimals,
        bool _isApplicable
    ) public returns (bool) {
        aggregators[_tokenAddress].aggregatorAddress = _aggregatorAddress;
        aggregators[_tokenAddress].decimals = _decimals;
        aggregators[_tokenAddress].isApplicable = _isApplicable;
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
    ) public returns (bool) {
        if (_new) {
            TotalTokens += 1;
            TokenAddresses.push(_tokenAddress);
        }

        tokens[_tokenAddress].tokenAddress = _tokenAddress;
        tokens[_tokenAddress].symbol = _symbol;
        tokens[_tokenAddress].name = _name;
        tokens[_tokenAddress].icon = _icon;
        tokens[_tokenAddress].abiJSON = _abiJSON;
        tokens[_tokenAddress].pedgeToken = _pedgeToken;
        tokens[_tokenAddress].isPedgeToken = _isPedgeToken;
        tokens[_tokenAddress].isDeleted = _isDeleted;
        return true;
    }

    function deleteToken(address tokenAddress, bool _isDeleted) public returns (bool) {
        TotalTokens -= 1;
        tokens[tokenAddress].isDeleted = _isDeleted;
        return true;
    }

    function getAllToken() public view returns (Token[] memory) {
        Token[] memory memoryArray = new Token[](TotalTokens);
        for (uint256 i = 0; i < TotalTokens; i++) {
            memoryArray[i] = tokens[TokenAddresses[i]];
        }
        return memoryArray;
    }

    function getAllAggregators() public view returns (TokenAggregators[] memory) {
        TokenAggregators[] memory memoryArray = new TokenAggregators[](TotalTokens);
        for (uint256 i = 0; i < TotalTokens; i++) {
            memoryArray[i] = aggregators[TokenAddresses[i]];
        }
        return memoryArray;
    }

    function getAllTokenBorrowLimitations() public view returns (TokenBorrowLimitations[] memory) {
        TokenBorrowLimitations[] memory memoryArray = new TokenBorrowLimitations[](TotalTokens);
        for (uint256 i = 0; i < TotalTokens; i++) {
            memoryArray[i] = borrowLimitations[TokenAddresses[i]];
        }
        return memoryArray;
    }

    function getAllTokenIntrestRateModel() public view returns (TokenIntrestRateModel[] memory) {
        TokenIntrestRateModel[] memory memoryArray = new TokenIntrestRateModel[](TotalTokens);
        for (uint256 i = 0; i < TotalTokens; i++) {
            memoryArray[i] = intrestRateModel[TokenAddresses[i]];
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

    function getTokenIntrestRateModel(address _tokenAddress) public view returns (TokenIntrestRateModel memory) {
        return intrestRateModel[_tokenAddress];
    }
}
