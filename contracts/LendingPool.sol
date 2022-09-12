// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';
import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';

import './interfaces/ISwapRouter.sol';
// import './interfaces/IERC20.sol';
import './Math.sol';





contract LendingPool is Ownable {
    // defining the basic terms of load
    address payable public lender;
    address payable public borrower;
    address public diaAddress;
    uint256 public totalBorrowed;
    uint256 public totalReserve;
    uint256 public interestRate = 0;
    uint256 public fixedAnnumBorrowRate = 0;
    mapping(address => uint256) public lendingPoolTokenList;
    mapping(address => uint256) public lendersList;
    mapping(address => uint256) public borrowwerList;
    uint256 internal constant max_stake_days = 300;


    IERC20 public weth;
    IERC20 public fWeth;
    IERC20 public fDai;
    IERC20 public dai;

    
    AggregatorV3Interface internal constant priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
    ISwapRouter public constant uniswapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    //===========================================================================
    struct lendingMember {
        address lenderAddress; // address of the user that lended
        uint256 token; //eth,Matic ,bnb
        uint256 tokenAmount; //1
        uint256 lendingProfit;  // profit on 0.1 eth in specific period of time
        uint256 timestamp; // time when he lended
        uint256 endDay; // when lending period ends
        bool isRedeem; // if true is means he has something in pool if false it means he/she redeem
    }
    // if we have struct as above we can also map it like this
    // mapping(address => lendingMember) public mapLenderInfo;
    // mapping(address => lendingMember) public mapLenderInfo;

    mapping(address => mapping(uint256 => lendingMember)) public mapLenderInfo;
    //===========================================================================

    struct Terms {
        uint256 loanDaiAmount;
        uint256 feeDaiAmount;
        uint256 ethColletoralAmount;
        uint256 repayByTimestamp;
    }
    Terms public terms;

    enum LoanState {
        Created,
        Funded,
        Taken
    }
    LoanState public state;

    modifier onlyInState(LoanState expectedState) {
        require(state == expectedState, 'Not allowed in this state');
        _;
    }

    constructor(IERC20 _weth, IERC20 _fWeth, IERC20 _dai,  IERC20 _fDai ) {
        weth=_weth;
        fWeth = _fWeth;
        dai= _dai;
        fDai = _fDai;
    }

    // later on put midifier on it
    function lendAsset(uint _token,uint _amount, uint _days) external payable {
        require(msg.value != 0, 'Can not send 0 amount');

        mapLenderInfo[msg.sender][_token].lenderAddress = msg.sender;
        mapLenderInfo[msg.sender][_token].tokenAmount = _amount;
        mapLenderInfo[msg.sender][_token].timestamp = block.timestamp; 
        mapLenderInfo[msg.sender][_token].endDay = block.timestamp + _days * 1 days;
        mapLenderInfo[msg.sender][_token].isRedeem = false;
        weth.transferFrom(msg.sender, address(this), _amount);
        // fWeth.mint(msg.sender,_amount);
        
    }

    function redeemLendedAssed(uint _token) external payable {
        require(block.timestamp >= mapLenderInfo[msg.sender][_token].endDay, "Can not redeem before end day");
        mapLenderInfo[msg.sender][_token].isRedeem = true;

    }

    

   

   

    // add modifier here
    function repay() public {
        require(msg.sender == borrower, 'Only borrower can repay');
        // DAI(diaAddress).transferFrom(borrower,lender,terms.loanDaiAmount + terms.feeDaiAmount);
        selfdestruct(borrower);
    }

    function liquidate() public {
        require(msg.sender == lender, 'Only lender can lequidate the loan');
        require(block.timestamp >= terms.repayByTimestamp);
        selfdestruct(lender);
    }
}
