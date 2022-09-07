// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LendingPool {
    // defining the basic terms of load
    address payable public lender;
    address payable public borrower;
    address public diaAddress;
    address public owner;
    mapping(address => uint256) public lendingPoolTokenList;
    mapping(address => uint256) public lendersList;
    mapping(address => uint256) public borrowwerList;

    //===========================================================================
    struct lenderPoolData {
        address userAddress; // address of the user that lended
        uint256 tokenSymbol; //eth
        uint256 tokenAmount; //0.1
        uint256 timestamp;   // time when he lended
        uint256 lendingProfit; // profit on 0.1 eth in specific period of time
        bool isRedeem;  // if true is means he has something in pool if false it means he/she redeem
        
    }
    // if we have struct as above we can also map it like this 
    mapping(address => lenderPoolData) public lenderPoolDataMaper; 
    //===========================================================================


    struct Terms {
        uint256 loanDaiAmount;
        uint256 feeDaiAmount;
        uint256 ethColletoralAmount;
        uint256 repayByTimestamp;
    }
    Terms public terms;

    enum LoanState {Created,Funded, Taken}
    LoanState public state;

    modifier onlyInState(LoanState expectedState){
        require(state == expectedState, "Not allowed in this state");
        _;
    }


    constructor(Terms memory _terms, address _diaAddress){
        terms = _terms;
        diaAddress = _diaAddress;
        lender = payable(msg.sender);
        state = LoanState.Created;
        owner = msg.sender;
    }

    // later on put midifier on it
    function fundLoan() public {
        state = LoanState.Funded;
        // DAI(diaAddress).transferFrom(msg.sender, address(this), terms.loanDaiAmount);
    }

    function takeLoanAndAcceptLoanTerms() public payable {
        require(msg.value == terms.ethColletoralAmount,"Invalid collateral amount");
        borrower = payable(msg.sender);
        state = LoanState.Taken;
        // DAI(diaAddress).transfer(borrower,terms.loanDaiAmount);
    }

    // add modifier here
    function repay () public {
        require(msg.sender == borrower, "Only borrower can repay");
        // DAI(diaAddress).transferFrom(borrower,lender,terms.loanDaiAmount + terms.feeDaiAmount);
        selfdestruct(borrower);
    }

    function liquidate() public {
        require(msg.sender == lender,"Only lender can lequidate the loan");
        require(block.timestamp >= terms.repayByTimestamp);
        selfdestruct(lender);
    }
}
