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

interface ERC20 {
    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function mint(address to, uint256 value) external;

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

contract LendingPool is Ownable, Math {
    using SafeMath for uint256;
    //  AggregatorV3Interface public priceCollateral;
    //  AggregatorV3Interface public priceLoan;

    // AggregatorV3Interface internal constant priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
    ISwapRouter public constant uniswapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    
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
        uint256 tokenAmount; //1
        uint256 SuppliedAmount; //1
        uint  startDay; // time when he lended
        uint  endDay; // when lending period ends
        bool isRedeem; // if true is means he has something in pool if false it means he/she redeem
        address pledgeToken;
    }
    // if we have struct as above we can also map it like this
    // mapping(address => lendingMember) public mapLenderInfo;

    // mapping(address => mapping(string => lendingMember)) public mapLenderInfo;
    mapping(uint256 => lendingMember) public mapLenderInfo; // lending id goes to struct
    mapping(address => mapping(string => uint256[])) public lenderIds;
    mapping(address => mapping(string => uint256)) public lenderShares;
    //===========================================================================
    struct borrowMember {
        address borrowerAddress;
        string loanToken;
        uint256 borrowAmount;
        uint256 loanAmount;
        string collateralToken;
        uint256 collateralAmount;
        uint  borrowDay;
        uint  endDay;
        uint256 borrowRate;
        bool isStableBorrow;
        bool hasRepaid;
    }
    mapping(uint256 => borrowMember) public mapBorrowerInfo;
    mapping(address => mapping(string => uint256[])) public borrowerIds;
    mapping(address => mapping(string => uint256)) public borrowerShares;

struct IntrestRateModal {
  uint256 OPTIMAL_UTILIZATION_RATE;
  uint256 stableRateSlope1;
  uint256 stableRateSlope2;
  uint256 variableRateSlope1;
  uint256 variableRateSlope2;
  uint256 baseRate;
}
    constructor() {}

    function lend(
        string memory _tokenSymbol,
        uint256 _amount,
        uint  _days,
        address _token,
        address _ftoken
    ) public payable {
        require(msg.value <= 0, 'Can not send 0 amount');

        // mapLenderInfo[msg.sender][_tokenSymbol].lenderAddress = msg.sender;
        // mapLenderInfo[msg.sender][_tokenSymbol].token = _tokenSymbol;
        // mapLenderInfo[msg.sender][_tokenSymbol].tokenAmount = _amount;
        // mapLenderInfo[msg.sender][_tokenSymbol].startDay = block.timestamp;
        // mapLenderInfo[msg.sender][_tokenSymbol].endDay = block.timestamp + _days * 1 days;
        // mapLenderInfo[msg.sender][_tokenSymbol].isRedeem = false;
        lendingId += 1;
        lenderIds[msg.sender][_tokenSymbol].push(lendingId);
        lenderShares[msg.sender][_tokenSymbol] += _amount;
        totalLendings[_token]+=_amount;
        mapLenderInfo[lendingId].lenderAddress = msg.sender;
        mapLenderInfo[lendingId].token = _tokenSymbol;
        mapLenderInfo[lendingId].SuppliedAmount = _amount;
        mapLenderInfo[lendingId].tokenAmount = _amount;
        mapLenderInfo[lendingId].startDay = block.timestamp;
        mapLenderInfo[lendingId].endDay = block.timestamp + _days * 1 days;
        mapLenderInfo[lendingId].isRedeem = false;
        mapLenderInfo[lendingId].pledgeToken = _ftoken;
        ERC20(_token).transferFrom(msg.sender, address(this), _amount);
        ERC20(_ftoken).mint(msg.sender, _amount);
    }

    // function isLenderExist (address _address) public view return (bool){
    //   return true
    // }
    function getLenderId(string memory _tokenSymbol) public view returns (uint256[] memory) {
        return lenderIds[msg.sender][_tokenSymbol];
    }

    function getLenderAsset(uint256 _id) public view returns (lendingMember memory) {
        return mapLenderInfo[_id];
    }

    function getLenderShare(string memory _tokenSymbol) public view returns (uint256) {
        return lenderShares[msg.sender][_tokenSymbol];
    }

    // function lendedAssetDetails(string memory _tokenSymbol) public view returns () {
    //     // return mapLenderInfo[msg.sender][_tokenSymbol][1];
    //     return mapLenderInfo[msg.sender][_tokenSymbol][50];
    // }

    function redeem(
        string memory _tokenSymbol,
        uint256 _amount,
        address _token,
        uint256 _lendeingId,
        IntrestRateModal memory IRS,
        uint256 ProtocolShare
    ) external payable {
        // require(block.timestamp >= mapLenderInfo[_lendeingId].endDay, "Can not redeem before end day");
        require(keccak256(abi.encodePacked(mapLenderInfo[_lendeingId].token)) == keccak256(abi.encodePacked(_tokenSymbol)), 'Use correct token');
        mapLenderInfo[_lendeingId].isRedeem = true;
        mapLenderInfo[_lendeingId].tokenAmount -= _amount;
        lenderShares[msg.sender][_tokenSymbol] -= _amount;
        totalLendings[_token]-=_amount;
        uint256 profit= getLendingProfitAmount(_amount,_token,IRS,ProtocolShare);
        reserve[_token]-= profit;
        ERC20(_token).transfer(msg.sender, _amount.add(profit));
        ERC20(mapLenderInfo[_lendeingId].pledgeToken).transferFrom(msg.sender, address(this), _amount);
    }

    function borrow(
        string memory _loanTokenSymbol,
        uint256 _loanAmount,
        address _loanToken,
        string  memory _collateralTokenSymbol,
        address _collateralToken,
        uint256 _collateralAmount,
        uint256 _stableBorrowRate,
        bool _isStableBorrow
    ) external payable {
        // require(block.timestamp >= mapLenderInfo[_borrowerId].endDay, "Can not redeem before end day");
        // require(keccak256(abi.encodePacked(mapLenderInfo[_borrowerId].token)) == keccak256(abi.encodePacked(_tokenSymbol)),'Use correct token');
        // IERC20 tokenObj = IERC20(_token);
        borrowerId +=1;
        borrowerIds[msg.sender][_loanTokenSymbol].push(lendingId);
        if(reserve[_loanToken]>=0){

        }else{
            reserve[_loanToken]=0;
        }
        totalDebt[_loanToken]+=_loanAmount;
        if(_isStableBorrow){
            totalStableDebt[_loanToken]+=_loanAmount;
        }else{
            totalVariableDebt[_loanToken]+=_loanAmount;
        }
        mapBorrowerInfo[borrowerId].isStableBorrow = _isStableBorrow;
        mapBorrowerInfo[borrowerId].borrowerAddress = msg.sender;
        mapBorrowerInfo[borrowerId].loanToken = _loanTokenSymbol;
        mapBorrowerInfo[borrowerId].borrowRate = _stableBorrowRate;
        mapBorrowerInfo[borrowerId].collateralToken = _collateralTokenSymbol;
        mapBorrowerInfo[borrowerId].borrowAmount += _loanAmount;
        mapBorrowerInfo[borrowerId].loanAmount += _loanAmount;
        mapBorrowerInfo[borrowerId].collateralAmount += _collateralAmount;
        mapBorrowerInfo[borrowerId].borrowDay = block.timestamp;
        mapBorrowerInfo[borrowerId].hasRepaid = false;
        borrowerShares[msg.sender][_loanTokenSymbol] += _loanAmount;
        ERC20(_collateralToken).transferFrom(msg.sender, address(this), _collateralAmount);
        ERC20(_loanToken).transfer(msg.sender, _loanAmount);
    }


    function repay(
        string memory _loanTokenSymbol,
        uint256 _loanAmount,
        address _loanToken,
        address _collateral,
        uint _borrowerId,
        IntrestRateModal memory IRS
    ) external payable {
        require(mapBorrowerInfo[_borrowerId].borrowerAddress == msg.sender, "Wrong owner");
        if(mapBorrowerInfo[_borrowerId].loanAmount ==_loanAmount){
           mapBorrowerInfo[_borrowerId].hasRepaid = true;
        }
        uint256 repayCollateralAmount= mapBorrowerInfo[_borrowerId].collateralAmount;
        if(mapBorrowerInfo[_borrowerId].isStableBorrow){
            IRS.baseRate=mapBorrowerInfo[_borrowerId].borrowRate;
        }
        (uint256 fee, uint256 paid) = calculateBorrowFee(
           IRS,
            _loanAmount,
            _loanToken
            );
        require(mapBorrowerInfo[_borrowerId].loanAmount >= paid, "Your custom message here");
        borrowerShares[msg.sender][_loanTokenSymbol] -= paid;
        mapBorrowerInfo[_borrowerId].loanAmount -= paid;
        reserve[_loanToken]+= fee;
        ERC20(_collateral).transfer(msg.sender,repayCollateralAmount);
        ERC20(_loanToken).transferFrom(msg.sender, address(this), paid);
    }


    function poolTokensBal(address _address) public view returns (uint256) {
        return ERC20(_address).balanceOf(address(this));
    }

    function setPercentage(uint256 _percentage) external {
        borrowPercentage = _percentage;
    }

    function checkPercentage(uint256 _amount) public view returns (uint256) {
        // uint per = (_amount * borrowPercentage) /10000;
        return _amount.mul(borrowPercentage).div(1e18);
    }

    function getBorrowerId(string memory _collateralTokenSymbol) public view returns (uint256[] memory) {
        return borrowerIds[msg.sender][_collateralTokenSymbol];
    }

    function getBorrowerDetails(uint256 _id) public view returns (borrowMember memory) {
        return mapBorrowerInfo[_id];
    }

    function getBorrowerShare(string memory _collateralTokenSymbol) public view returns (uint256) {
        return borrowerShares[msg.sender][_collateralTokenSymbol];
    }


    function getColateralAmount(
        address loanTokenAggregator,
        address collateralTokenAggregator,
        uint256 loanAmount
    ) public view returns (uint256) {
        // 1dai=1usd
        AggregatorV3Interface CollateralPrice = AggregatorV3Interface(collateralTokenAggregator);
        (, int256 price, , , ) = CollateralPrice.latestRoundData();
        AggregatorV3Interface LoanPrice = AggregatorV3Interface(loanTokenAggregator);
        ( , int256 loanPrice,,,) = LoanPrice.latestRoundData();

        uint256 loanPriceInUSD=loanAmount.mul(uint256(loanPrice));
        uint256 collateralAmountInUSD = loanPriceInUSD.mul(100*10**18).div(borrowPercentage);
        uint256 collateralAmount = uint256(collateralAmountInUSD).div(uint(price));
        return collateralAmount;
    }


    function getColateralAmount2(
        uint256 loanAmount, // 1000 DAI
        uint256 loanPrice,  // 1 * 1000 = 1000
        uint256 colletaralPrice // 1DAI =  1USD
    ) public view returns (uint256) {
        
        // eg: loanAmount = 1 eth & loanPrice $1000/eth
        uint256 totalLoanInUSD = loanAmount.mul(loanPrice);
        uint256 percentage = totalLoanInUSD.mul(100*10**18).div(borrowPercentage);
        uint256 colletaralAmount = uint256(percentage).div(colletaralPrice);
        return colletaralAmount;
    }
    
    function getColateralAmount3(
        // address loanTokenAggregator,
        // address collateralTokenAggregator,
        uint256 loanAmount
    ) public view returns (uint256) {
        // need eth for Dai
        // uint256 price = 99965123; //dai
        uint256 price = 100000000; //dai
        uint256 loanPrice = 100046579615; //price per eth
        
        uint256 loanPriceInUSD=loanAmount.mul(loanPrice);
        uint256 collateralAmountInUSD = loanPriceInUSD.mul(100*10**18).div(borrowPercentage);
        uint256 collateralAmount = collateralAmountInUSD.div(price);
        return collateralAmount;
    }

    function getAggregatorPrice(address _tokenAddress) public view returns (uint256) {
        AggregatorV3Interface LoanPrice = AggregatorV3Interface(_tokenAddress);
        (   ,
            /*uint80 roundID*/
            int256 loanPrice,
            ,
            ,
        ) = /*uint startedAt*/
            /*uint timeStamp*/
            /*uint80 answeredInRound*/
            LoanPrice.latestRoundData();

        return uint256(loanPrice);
    }

     function calculateBorrowFee(
        IntrestRateModal memory irs,
        uint256 _amount,
        address token)
        public
        view
        returns (uint256, uint256)
    {
        uint256 uRatio= _utilizationRatio(token);
        (uint256 currentStableBorrowRate,uint256 currentVariableBorrowRate) = getCurrentStableAndVariableBorrowRate(uRatio,irs);
        uint256 borrowRate = getOverallBorrowRate(token,currentStableBorrowRate,currentVariableBorrowRate);
        uint256 fee = mulExp(_amount, borrowRate);
        uint256 paid = _amount.sub(fee);
        return (fee, paid);
    }

//   function getBorrowRateSlope(
//         IntrestRateModal memory irs,
//         address token)
//         public view returns (uint256[] memory) {    
//       uint256[] memory borrowSlope;
//       for(uint256 i=0;i<100;i++){
//          (uint256 currentStableBorrowRate,uint256 currentVariableBorrowRate) =
//          getCurrentStableAndVariableBorrowRate(
//          i.mul(1*10**16),
//         irs);
//         uint256 borrowRate = getOverallBorrowRate(token,currentStableBorrowRate,currentVariableBorrowRate);
//        borrowSlope[i]=borrowRate;
//     }
//      return borrowSlope;
//         }

    function _utilizationRatio(address token) public view returns (uint256) {
        return getExp(totalDebt[token], totalLendings[token]);
    }

    function getCurrentStableAndVariableBorrowRate(
        uint256 utilizationRate,
        IntrestRateModal memory irs) public pure returns (uint256,uint256){
    if (utilizationRate >irs.OPTIMAL_UTILIZATION_RATE) {
      uint256 excessUtilizationRateRatio =
        utilizationRate.sub(irs.OPTIMAL_UTILIZATION_RATE);
     uint256 currentStableBorrowRate = irs.baseRate.add(irs.stableRateSlope1).add(
        irs.stableRateSlope2.mul(excessUtilizationRateRatio)
      );
      uint256 currentVariableBorrowRate = irs.baseRate.add(irs.variableRateSlope1).add(
        irs.variableRateSlope2.mul(excessUtilizationRateRatio)
      );
      return (currentStableBorrowRate,currentVariableBorrowRate);
    } else {
      uint256 currentStableBorrowRate = irs.baseRate.add(
        irs.stableRateSlope1.mul(utilizationRate.div(irs.OPTIMAL_UTILIZATION_RATE))
      );
      uint256 currentVariableBorrowRate = irs.baseRate.add(
        utilizationRate.mul(irs.variableRateSlope1).div(irs.OPTIMAL_UTILIZATION_RATE)
      );
      return (currentStableBorrowRate,currentVariableBorrowRate);
    }

    }

  function getOverallBorrowRate(
    address token,
    uint256 currentVariableBorrowRate,
    uint256 currentAverageStableBorrowRate
  ) public view returns (uint256) {
    uint256 _totalDebt = totalStableDebt[token].add(totalVariableDebt[token]);
    if (_totalDebt == 0) return 0;
    uint256 weightedVariableRate = totalVariableDebt[token].mul(currentVariableBorrowRate);
    uint256 weightedStableRate = totalStableDebt[token].mul(currentAverageStableBorrowRate);
    uint256 overallBorrowRate =
      weightedVariableRate.add(weightedStableRate).div(_totalDebt);
    return overallBorrowRate;
  }

    function lendingProfiteRate(
        address token,
        uint256 uRatio,
        IntrestRateModal memory IRS,
        uint256 ProtocolShare ) public view returns (uint256) {    
        (uint256 currentStableBorrowRate,uint256 currentVariableBorrowRate) =
         getCurrentStableAndVariableBorrowRate(
        uRatio,IRS);
        uint256 bRate = getOverallBorrowRate(token,currentStableBorrowRate,currentVariableBorrowRate);
        uint256 companyshare= bRate.mul(ProtocolShare).div(1*10**18);
        return mulExp(uRatio, bRate.sub(companyshare));
    }

    // function lendingProfiteRateSlope(
    //     address token,
    //     IntrestRateModal memory IRS,
    //     uint256 ProtocolShare ) public view returns (uint256[] memory) {    
    //   uint256[] memory profitSlope;
    //   for(uint256 i=0;i<100;i++){
    //     (uint256 currentStableBorrowRate,uint256 currentVariableBorrowRate) =
    //      getCurrentStableAndVariableBorrowRate(
    //     i,IRS);
    //     uint256 bRate = getOverallBorrowRate(token,currentStableBorrowRate,currentVariableBorrowRate);
    //     uint256 companyshare= bRate.mul(ProtocolShare).div(1*10**18);
    //     profitSlope[i]=mulExp(i, bRate.sub(companyshare));
    //   }
    //     return profitSlope;
    // }
    

    function calculateCurrentLendingProfitRate(
        address token,
        IntrestRateModal memory IRS,
        uint256 ProtocolShare
        )
        public
        view
        returns (uint256)
        {
        uint256 uRatio= _utilizationRatio(token);
           
         uint256 bRate = lendingProfiteRate(
            token,
            uRatio,
            IRS,
            ProtocolShare);
        return mulExp(uRatio, bRate); 
    }

    function getLendingProfitAmount(
        uint256 _amount,
         address token,
        IntrestRateModal memory IRS,
        uint256 ProtocolShare
    ) internal view returns (uint256){
        uint256 lendingProfitRate = calculateCurrentLendingProfitRate(token,IRS,ProtocolShare);
        uint256 profit = mulExp(_amount, lendingProfitRate);
        return (profit);
    }
}