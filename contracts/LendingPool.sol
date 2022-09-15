// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import '@openzeppelin/contracts/access/Ownable.sol';
import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
// import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
// import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import './interfaces/ISwapRouter.sol';
import './Math.sol';

interface ERC20 {
    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

contract LendingPool is Ownable {
    mapping(address => uint256) public lendingPoolTokenList;
    mapping(address => uint256) public lendersList;
    mapping(address => uint256) public borrowwerList;
    uint256 internal constant max_stake_days = 300;

    AggregatorV3Interface internal constant priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
    ISwapRouter public constant uniswapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    //===========================================================================
    struct lendingMember {
        address lenderAddress; // address of the user that lended
        string token; //eth,Matic ,bnb
        uint256 tokenAmount; //1
        uint256 lendingProfit; // profit on 0.1 eth in specific period of time
        uint256 timestamp; // time when he lended
        uint256 endDay; // when lending period ends
        bool isRedeem; // if true is means he has something in pool if false it means he/she redeem
    }
    // if we have struct as above we can also map it like this
    // mapping(address => lendingMember) public mapLenderInfo;
    // mapping(address => lendingMember) public mapLenderInfo;

    mapping(address => mapping(string => lendingMember)) public mapLenderInfo;

    //===========================================================================

    constructor() {}

    // later on put midifier on it
    function lendAsset(
        string memory _token,
        uint256 _amount,
        uint256 _days
    ) external payable {
        require(msg.value != 0, 'Can not send 0 amount');

        mapLenderInfo[msg.sender][_token].lenderAddress = msg.sender;
        mapLenderInfo[msg.sender][_token].tokenAmount = _amount;
        mapLenderInfo[msg.sender][_token].timestamp = block.timestamp;
        mapLenderInfo[msg.sender][_token].endDay = block.timestamp + _days * 1 days;
        mapLenderInfo[msg.sender][_token].isRedeem = false;
        // weth.transferFrom(msg.sender, address(this), _amount);
        // fWeth.mint(msg.sender,_amount);
    }

    function lend(
        string memory _tokenSymbol,
        uint256 _amount,
        uint256 _days,
        address _token
    ) public payable {
        require(msg.value <= 0, 'Can not send 0 amount');

        mapLenderInfo[msg.sender][_tokenSymbol].lenderAddress = msg.sender;
        mapLenderInfo[msg.sender][_tokenSymbol].token = _tokenSymbol;
        mapLenderInfo[msg.sender][_tokenSymbol].tokenAmount = _amount;
        mapLenderInfo[msg.sender][_tokenSymbol].timestamp = block.timestamp;
        mapLenderInfo[msg.sender][_tokenSymbol].endDay = block.timestamp + _days * 1 days;
        mapLenderInfo[msg.sender][_tokenSymbol].isRedeem = false;
        ERC20(_token).transferFrom(msg.sender,address(this), _amount);
        // fWeth.mint(msg.sender,_amount);
    }

    function lendedAssetDetails(string memory _tokenSymbol) public view returns (lendingMember memory) {
        return mapLenderInfo[msg.sender][_tokenSymbol];
    }

    function redeem(
        string memory _tokenSymbol,
        uint256 _amount,
        address _token
    ) external payable {
        // require(block.timestamp >= mapLenderInfo[msg.sender][_tokenSymbol].endDay, "Can not redeem before end day");
        require(
            keccak256(abi.encodePacked(mapLenderInfo[msg.sender][_tokenSymbol].token)) == keccak256(abi.encodePacked(_tokenSymbol)),
            'Use correct token'
        );
        mapLenderInfo[msg.sender][_tokenSymbol].isRedeem = true;
        mapLenderInfo[msg.sender][_tokenSymbol].tokenAmount -= _amount;
        ERC20(_token).transfer(msg.sender, _amount);
    }

    function poolTokensBal(address _address) public view returns (uint256) {
        return ERC20(_address).balanceOf(address(this));
    }
}
