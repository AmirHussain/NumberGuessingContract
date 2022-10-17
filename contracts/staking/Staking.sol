//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";
contract Staking {
    // only allow one erc20 token
     IERC20 public stakingToken;
     IERC20 public rewardToken;     // in case reward token is different
     
     uint256 public totalSupply;
     uint256 public rewardPerToken;
     uint256 public lastUpdated;
     uint256 public constant REWARD_RATE = 100 * 1e18; //100 token per second in wei uint 1e18
     address public owner;

     mapping(address => uint256) public balances; // addres map to how much they staked
     mapping(address => uint256) public rewards; 
     mapping(address => uint256) public paidRewardToUsers; 
     mapping(address => bool) public isStaker;

    event Deposit(address indexed staker, uint256 amount);
    event WithDraw(address indexed staker, uint256 amount);


     modifier updateReward(address account){
        // claim reward with decreas total supply.
        //how much currend reward per token
        rewardPerToken = getRewardPerToken();
        lastUpdated =  block.timestamp;
        rewards[account] = earned(account);
        paidRewardToUsers[account] = rewardPerToken;
        _;
     }
     modifier moreThenZero(uint256 tokens){
        require(tokens>0,"Can not stake 0 tokens");
        _;
     }
     modifier onlyOwner (){
         require(msg.sender == owner,"Only owner can call this function");
      _;
     }
    
    constructor(address _stakingToken,address _rewardToken){
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
        owner = msg.sender;
    }

    function earned(address account) public view returns(uint256){
        uint256 currentBalance = balances[account];
        uint256 amountPaid =  paidRewardToUsers[account];
        uint256 currentRewardPerToken =  getRewardPerToken();
        uint256 pastRewards =  rewards[account];
        uint256 earnedT = ((currentBalance *(currentRewardPerToken - amountPaid))/1e18) + pastRewards;
        return earnedT;
    }

    function stake(uint256 _amount) external updateReward(msg.sender) moreThenZero(_amount) {
        balances[msg.sender] = balances[msg.sender] + _amount;
        totalSupply = totalSupply + _amount;
        if(!hasStaked(msg.sender)){
            isStaker[msg.sender] = true;
        }
        // emit an event
        bool success =  stakingToken.transferFrom(msg.sender, address(this), _amount);
        require(success,"Faild");

    }
    function addStaker(address _address) public onlyOwner returns (bool) {
        if (!hasStaked(_address)) {
            isStaker[_address] = true;
        }
        return isStaker[_address];
    }
    function hasStaked(address _address) public view returns (bool) {
        return isStaker[_address];
    }
    function removeStaker(address _address) public onlyOwner returns  (bool) {
        if (hasStaked(_address)) {
            isStaker[_address] = false;
            return true;
        }
        return false;
    }

    function checkStakingAmount (address _address) public view returns(uint256){
        return balances[_address];
    } 

    function withdraw (uint256 amount) external updateReward(msg.sender) moreThenZero(amount) {
       balances[msg.sender] = balances[msg.sender] - amount;
       totalSupply = totalSupply - amount;
       console.log("console.sol =>",stakingToken.balanceOf(address(this)));
       bool success = stakingToken.transfer(msg.sender, amount); 
       require(success,"Faild on withdraw");
       require(isStaker[msg.sender],"Disabled user");
    }

    function claimReward () external updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        bool success = stakingToken.transfer(msg.sender, reward);
        require(success,"Reward claim failed");

         
        
    }

    
    function getRewardPerToken() public view returns(uint256){
        if(totalSupply==0){
            return rewardPerToken;
        }
        return rewardPerToken + (((block.timestamp - lastUpdated) * REWARD_RATE)/totalSupply);

    }
    
}