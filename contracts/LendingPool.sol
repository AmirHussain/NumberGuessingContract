// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import '@openzeppelin/contracts/access/Ownable.sol';
import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
// import './interfaces/ISwapRouter.sol';
import './Math.sol';
import 'hardhat/console.sol';

interface ERC20 {
    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function mint(address to, uint256 value) external;

    function burn(address to, uint256 value) external;

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

contract LendingPool is Ownable, Math {
    using SafeMath for uint256;

    mapping(address => uint256) public totalLendings;
    mapping(address => uint256) public reserve;
    mapping(address => uint256) public totalDebt;
    mapping(address => uint256) public totalVariableDebt;
    mapping(address => uint256) public totalStableDebt;
    mapping(address => uint256) public lendingPoolTokenList;
    mapping(address => uint256) public lendersList;
    mapping(address => uint256) public borrowwerList;
    uint256 public lendingId = 0;
    uint256 public borrowerId = 0;
    uint256 public borrowPercentage;
    uint256 public loan;

    //===========================================================================
    struct lendingMember {
        address lenderAddress; // address of the user that lended
        string token; //eth,Matic ,bnb
        uint256 SuppliedAmount; //1
        uint256 startDay; // time when he lended
        uint256 endDay; // when lending period ends
        bool isRedeem; // if true is means he has something in pool if false it means he/she redeem
        address pledgeToken;
        uint256 pledgeTokenAmount;
        uint256 _days;
        uint256 lockId;
    }

    struct Token {
        string symbol;
        address tokenAddress; // address of the user that lended
        uint256 unitPriceInUSD;
    }
    uint256[] liquidatedBorrowIds;
    // mapping(address => mapping(string => lendingMember)) public mapLenderInfo;
    mapping(uint256 => lendingMember) public mapLenderInfo; // lending id goes to struct
    mapping(address => mapping(string => uint256[])) public lenderIds;
    mapping(address => mapping(string => uint256)) public lenderShares;
    //===========================================================================
    struct borrowMember {
        address borrowerAddress;
        string loanToken;
        uint256 loanAmount;
        address collateralTokenAddress;
        string collateralToken;
        uint256 collateralAmount;
        uint256 borrowDay;
        uint256 endDay;
        uint256 borrowRate;
        bool isStableBorrow;
        bool hasRepaid;
        uint256 lendingId;
    }
    mapping(uint256 => borrowMember) public mapBorrowerInfo;
    mapping(address => mapping(string => uint256[])) public borrowerIds;
    mapping(address => mapping(string => uint256)) public borrowerShares;

    struct IntrestRateModal {
        uint256 OPTIMAL_UTILIZATION_RATE;
        uint256 StableRateSlope1;
        uint256 StableRateSlope2;
        uint256 VariableRateSlope1;
        uint256 VariableRateSlope2;
        uint256 BaseRate;
    }

    struct Aggregators {
        address aggregator;
        address tokenAddress;
        uint256 decimal;
    }

    address private lendingOwner;

    constructor() {
        lendingOwner = msg.sender;
    }

    function getOwner() public view returns (address) {
        return lendingOwner;
    }

    function getBalance() public view returns (uint256) {
        return lendingOwner.balance;
    }

    function lend(
        Token memory lendingToken,
        Token memory pedgeToken,
        uint256 _amount,
        uint256 _days
    ) public payable {
        require(msg.value <= 0, 'Can not send 0 amount');
        uint256 fftToMint = ((lendingToken.unitPriceInUSD * _amount) / pedgeToken.unitPriceInUSD);
        lendingId += 1;
        lenderIds[msg.sender][lendingToken.symbol].push(lendingId);
        lenderShares[msg.sender][lendingToken.symbol] += _amount;
        totalLendings[lendingToken.tokenAddress] += _amount;
        mapLenderInfo[lendingId].lenderAddress = msg.sender;
        mapLenderInfo[lendingId].token = lendingToken.symbol;
        mapLenderInfo[lendingId].SuppliedAmount = _amount;
        mapLenderInfo[lendingId].startDay = block.timestamp;
        mapLenderInfo[lendingId].endDay = block.timestamp + _days * 1 days;
        mapLenderInfo[lendingId].isRedeem = false;
        mapLenderInfo[lendingId]._days = _days;
        mapLenderInfo[lendingId].pledgeToken = pedgeToken.tokenAddress;
        mapLenderInfo[lendingId].pledgeTokenAmount = fftToMint;
        ERC20(lendingToken.tokenAddress).transferFrom(msg.sender, address(this), _amount);
        ERC20(pedgeToken.tokenAddress).mint(msg.sender, fftToMint);
    }

    function getLenderId(string memory _tokenSymbol) public view returns (uint256[] memory) {
        return lenderIds[msg.sender][_tokenSymbol];
    }

    function getLenderAsset(uint256 _id) public view returns (lendingMember memory) {
        return mapLenderInfo[_id];
    }

    function getLenderShare(string memory _tokenSymbol) public view returns (uint256) {
        return lenderShares[msg.sender][_tokenSymbol];
    }

    function redeem(
        string memory _tokenSymbol,
        address _token,
        uint256 _lendeingId,
        uint256 _appliedIntrest
    ) external payable {
        require(block.timestamp >= mapLenderInfo[_lendeingId].endDay, 'Can not redeem before end day');
        require(keccak256(abi.encodePacked(mapLenderInfo[_lendeingId].token)) == keccak256(abi.encodePacked(_tokenSymbol)), 'Use correct token');
        mapLenderInfo[_lendeingId].isRedeem = true;
        lenderShares[msg.sender][_tokenSymbol] -= mapLenderInfo[_lendeingId].SuppliedAmount;
        totalLendings[_token] -= mapLenderInfo[_lendeingId].SuppliedAmount;
        uint256 profit = getLendingProfitAmount(mapLenderInfo[_lendeingId].SuppliedAmount, _appliedIntrest);
        if (reserve[_token] >= profit) {
            reserve[_token] -= profit;
        }
        uint256 fftAmount = mapLenderInfo[_lendeingId].pledgeTokenAmount;
        // console.log('amout profit', mapLenderInfo[_lendeingId].SuppliedAmount, profit);
        ERC20(_token).transfer(msg.sender, mapLenderInfo[_lendeingId].SuppliedAmount.add(profit));
        // console.log(fftAmount, ERC20(mapLenderInfo[_lendeingId].pledgeToken).balanceOf(msg.sender));

        ERC20(mapLenderInfo[_lendeingId].pledgeToken).burn(msg.sender, fftAmount);
    }

    function borrow(
        Token memory loanToken,
        Token memory collateralToken,
        uint256 _loanAmount,
        uint256 _collateralAmount,
        uint256 _stableBorrowRate,
        bool _isStableBorrow
    ) external payable {
        borrowerId += 1;
        borrowerIds[msg.sender][loanToken.symbol].push(borrowerId);
        if (reserve[loanToken.tokenAddress] >= 0) {} else {
            reserve[loanToken.tokenAddress] = 0;
        }
        totalDebt[loanToken.tokenAddress] += _loanAmount;
        if (_isStableBorrow) {
            totalStableDebt[loanToken.tokenAddress] += _loanAmount;
        } else {
            totalVariableDebt[loanToken.tokenAddress] += _loanAmount;
        }
        console.log(msg.sender, loanToken.symbol);

        mapBorrowerInfo[borrowerId].isStableBorrow = _isStableBorrow;
        mapBorrowerInfo[borrowerId].borrowerAddress = msg.sender;
        mapBorrowerInfo[borrowerId].loanToken = loanToken.symbol;
        mapBorrowerInfo[borrowerId].borrowRate = _stableBorrowRate;
        mapBorrowerInfo[borrowerId].collateralToken = collateralToken.symbol;
        mapBorrowerInfo[borrowerId].collateralTokenAddress = collateralToken.tokenAddress;
        mapBorrowerInfo[borrowerId].loanAmount = _loanAmount;
        mapBorrowerInfo[borrowerId].collateralAmount = _collateralAmount;
        mapBorrowerInfo[borrowerId].borrowDay = block.timestamp;
        mapBorrowerInfo[borrowerId].hasRepaid = false;
        borrowerShares[msg.sender][loanToken.symbol] += _loanAmount;
        lendingId += 1;
        lenderIds[address(this)][collateralToken.symbol].push(lendingId);
        lenderShares[address(this)][collateralToken.symbol] += _collateralAmount;
        totalLendings[collateralToken.tokenAddress] += _collateralAmount;
        mapLenderInfo[lendingId].lenderAddress = address(this);
        mapLenderInfo[lendingId].token = collateralToken.symbol;
        mapLenderInfo[lendingId].SuppliedAmount = _collateralAmount;
        mapLenderInfo[lendingId].isRedeem = false;
        mapBorrowerInfo[borrowerId].lendingId = lendingId;
        console.log('transfering _collateralAmount from user to constract', _collateralAmount);

        ERC20(collateralToken.tokenAddress).transferFrom(msg.sender, address(this), _collateralAmount);
        ERC20(loanToken.tokenAddress).transfer(msg.sender, _loanAmount);
    }

    function repay(
        string memory _loanTokenSymbol,
        address _loanToken,
        address _collateral,
        uint256 _borrowerId,
        uint256 _lendingIntrest,
        uint256 _borrowIntrest
    ) external payable {
        require(mapBorrowerInfo[_borrowerId].borrowerAddress == msg.sender, 'Wrong owner');
        mapBorrowerInfo[_borrowerId].hasRepaid = true;
        uint256 repayCollateralAmount = mapBorrowerInfo[_borrowerId].collateralAmount;
        (uint256 fee, uint256 paid) = calculateBorrowFee(mapBorrowerInfo[_borrowerId].loanAmount, _borrowIntrest);
        borrowerShares[msg.sender][_loanTokenSymbol] -= mapBorrowerInfo[_borrowerId].loanAmount;
        reserve[_loanToken] += fee;
        uint256 profit = getLendingProfitAmount(repayCollateralAmount, _lendingIntrest);
        if (reserve[mapBorrowerInfo[_borrowerId].collateralTokenAddress] >= profit) {
            reserve[mapBorrowerInfo[_borrowerId].collateralTokenAddress] -= profit;
        }
        mapLenderInfo[mapBorrowerInfo[_borrowerId].lendingId].isRedeem = false;

        ERC20(_collateral).transfer(msg.sender, (repayCollateralAmount + profit));
        ERC20(_loanToken).transferFrom(msg.sender, address(this), paid);
    }

    function getBorrowerId(string memory _collateralTokenSymbol) public view returns (uint256[] memory) {
        console.log(msg.sender, _collateralTokenSymbol);
        return borrowerIds[msg.sender][_collateralTokenSymbol];
    }

    function getBorrowerDetails(uint256 _id) public view returns (borrowMember memory) {
        return mapBorrowerInfo[_id];
    }

    function getBorrowerShare(string memory _collateralTokenSymbol) public view returns (uint256) {
        return borrowerShares[msg.sender][_collateralTokenSymbol];
    }

    function getAggregatorPrice(address _tokenAddress) public view returns (uint256) {
        AggregatorV3Interface LoanPrice = AggregatorV3Interface(_tokenAddress);
        (
            ,
            /*uint80 roundID*/
            int256 loanPrice, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = LoanPrice.latestRoundData();

        return uint256(loanPrice);
    }

    function calculateBorrowFee(uint256 _amount, uint256 _borrowIntrest) public pure returns (uint256, uint256) {
        uint256 fee = mulExp(_amount, _borrowIntrest);
        uint256 paid = _amount.add(fee);
        return (fee, paid);
    }

    function _utilizationRatio(address token) public view returns (uint256) {
        return getExp(totalDebt[token], totalLendings[token]);
    }

    function getCurrentStableAndVariableBorrowRate(uint256 utilizationRate, IntrestRateModal memory irs) public pure returns (uint256, uint256) {
        if (utilizationRate >= irs.OPTIMAL_UTILIZATION_RATE) {
            uint256 excessUtilizationRateRatio = utilizationRate.sub(irs.OPTIMAL_UTILIZATION_RATE);
            uint256 unit1 = 1 * 10**18;
            uint256 currentStableBorrowRate = irs.BaseRate.add(irs.StableRateSlope1).add(
                (excessUtilizationRateRatio.mul(1 * 10**18).div(unit1.sub(irs.OPTIMAL_UTILIZATION_RATE)).mul(irs.StableRateSlope2).div(1 * 10**18))
            );
            uint256 currentVariableBorrowRate = irs.BaseRate.add(irs.VariableRateSlope1).add(
                (excessUtilizationRateRatio.mul(1 * 10**18).div(unit1.sub(irs.OPTIMAL_UTILIZATION_RATE)).mul(irs.VariableRateSlope2).div(1 * 10**18))
            );
            return (currentStableBorrowRate, currentVariableBorrowRate);
        } else {
            uint256 currentStableBorrowRate = irs.BaseRate.add(
                ((utilizationRate.mul(1 * 10**18).div(irs.OPTIMAL_UTILIZATION_RATE)).mul(irs.StableRateSlope1)).div(1 * 10**18)
            );
            uint256 currentVariableBorrowRate = irs.BaseRate.add(
                ((utilizationRate.mul(1 * 10**18).div(irs.OPTIMAL_UTILIZATION_RATE)).mul(irs.VariableRateSlope1)).div(1 * 10**18)
            );
            return (currentStableBorrowRate, currentVariableBorrowRate);
        }
    }

    function getOverallBorrowRate(
        address token,
        uint256 currentVariableBorrowRate,
        uint256 currentAverageStableBorrowRate
    ) public view returns (uint256) {
        uint256 _totalDebt = totalStableDebt[token].add(totalVariableDebt[token]);
        if (_totalDebt == 0) return 0;
        uint256 weightedVariableRate = totalVariableDebt[token].mul(currentVariableBorrowRate).div(1 * 10**18);
        uint256 weightedStableRate = totalStableDebt[token].mul(currentAverageStableBorrowRate).div(1 * 10**18);
        uint256 overallBorrowRate = (weightedVariableRate.add(weightedStableRate).mul(1 * 10**18)).div(_totalDebt);
        return overallBorrowRate;
    }

    function lendingProfiteRate(
        address token,
        uint256 uRatio,
        IntrestRateModal memory IRS
    ) public view returns (uint256) {
        (uint256 currentStableBorrowRate, uint256 currentVariableBorrowRate) = getCurrentStableAndVariableBorrowRate(uRatio, IRS);
        uint256 bRate = getOverallBorrowRate(token, currentStableBorrowRate, currentVariableBorrowRate);
        return mulExp(uRatio, bRate);
    }

    function calculateCurrentLendingProfitRate(address token, IntrestRateModal memory IRS) public view returns (uint256) {
        uint256 uRatio = _utilizationRatio(token);
        uint256 bRate = lendingProfiteRate(token, uRatio, IRS);
        return mulExp(uRatio, bRate);
    }

    function getLendingProfitAmount(uint256 _amount, uint256 appliedIntrest) internal pure returns (uint256) {
        uint256 profit = mulExp(_amount, appliedIntrest);
        return (profit);
    }

    function getChartData(
        address tokenAddress,
        IntrestRateModal memory IRS,
        uint256 liquidationThreshhold
    ) external view returns (uint256[] memory, uint256[] memory) {
        uint256 end = liquidationThreshhold;
        uint256[] memory arr = new uint256[](end);
        uint256[] memory borrowArray = new uint256[](end);
        uint256[] memory supplyArry = new uint256[](end);
        for (uint256 index = 0; index < arr.length; index++) {
            arr[index] = index;
            uint256 uratio = (index.mul(1 * 10**18) / 100);
            uint256 supplyRate = lendingProfiteRate(tokenAddress, uratio, IRS);
            (uint256 currentStableBorrowRate, uint256 currentVariableBorrowRate) = getCurrentStableAndVariableBorrowRate(uratio, IRS);
            uint256 borrowRate = getOverallBorrowRate(tokenAddress, currentStableBorrowRate, currentVariableBorrowRate);
            supplyArry[index] = supplyRate;
            borrowArray[index] = borrowRate;
        }
        return (supplyArry, borrowArray);
    }

    function getTokenMarketDetails(address token)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (totalLendings[token], reserve[token], totalDebt[token], totalVariableDebt[token], totalStableDebt[token]);
    }

    function getCurrentLiquidity(Aggregators[] memory tokens)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 totalLiquidityUSDS = 0;
        uint256 totalDebtUSDS = 0;
        uint256 totalStableBorrowUSDS = 0;
        uint256 totalVariableBorrowUSDS = 0;

        for (uint256 index = 0; index < tokens.length; index++) {
            uint256 usdInUnits = getAggregatorPrice(tokens[index].aggregator);
            address tokenaddress = tokens[index].tokenAddress;
            uint256 usds = usdInUnits;
            totalLiquidityUSDS += usds.mul(totalLendings[tokenaddress].div(1 * 10**18)).div(1 * 10**(tokens[index].decimal));
            totalDebtUSDS += usds.mul(totalDebt[tokenaddress].div(1 * 10**18)).div(1 * 10**(tokens[index].decimal));
            totalStableBorrowUSDS += usds.mul(totalStableDebt[tokenaddress].div(1 * 10**18)).div(1 * 10**(tokens[index].decimal));
            totalVariableBorrowUSDS += usds.mul(totalVariableDebt[tokenaddress].div(1 * 10**18)).div(1 * 10**(tokens[index].decimal));
        }
        return (totalLiquidityUSDS, totalDebtUSDS, totalStableBorrowUSDS, totalVariableBorrowUSDS);
    }

    function liquidate(
        uint256 _borrowerId,
        address borrowerAddress,
        string memory loanToken
    ) external returns (bool) {
        require(mapBorrowerInfo[_borrowerId].hasRepaid == false && mapBorrowerInfo[_borrowerId].hasRepaid == false, 'Already repaid pr liquidate');
        mapBorrowerInfo[_borrowerId].hasRepaid = true;
        liquidatedBorrowIds.push(_borrowerId);
        borrowerShares[borrowerAddress][loanToken] -= mapBorrowerInfo[_borrowerId].loanAmount;
        return true;
    }
}
