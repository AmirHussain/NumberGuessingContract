const { expect } = require("chai");
const { ethers } = require("hardhat");
const {moveBlocks} = require( "../utils/moveBlock");
const {moveTime} = require("../utils/moveTime");
const {decimalToBigNumber,bigNumberToDecimal} = require("../test/helper");


// oneToken = 1000000000000000000  wie
const SECONDS = 10
const SECONDS_IN_HOUR = 3600
const SECONDS_IN_DAY = 86400
const SECONDS_IN_YEAR = 31449600


describe("Staking test", function () {
  let owner, addr1, addr2, addrs, rt,staking
  
  it("beforeAll", async function () {
    if (network.name != "hardhat") {
      console.log("PLEASE USE --network hardhat");
      process.exit(0);
    }

    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
    RewardToken = await ethers.getContractFactory("RewardToken");
    rt = await RewardToken.deploy();
    Staking = await ethers.getContractFactory("Staking");
    staking = await Staking.deploy(rt.address,rt.address);
  });

  it("Checking name symbol & supply", async function () {
    expect(await rt.name()).to.equal("Reward Token");
    expect(await await rt.symbol()).to.equal("RT");
    console.log('balance in decimal =>', bigNumberToDecimal(await rt.balanceOf(owner.address)))
  });

  it("Staking 100000 tokens",async function (){

    let stakingAmount = decimalToBigNumber("100000");
    await (rt).approve(staking.address,stakingAmount);
    await staking.stake(stakingAmount);

    console.log("Balance after staking =>", bigNumberToDecimal(await rt.balanceOf(owner.address)));
    const earnedFromStaking = await staking.earned(owner.address);
    console.log("Total supply",bigNumberToDecimal(await staking.totalSupply()))
    console.log("earnedFromStaking",bigNumberToDecimal(earnedFromStaking));
  })

  it(`Afrer ${SECONDS_IN_DAY} seconds`,async function (){
    await moveTime(SECONDS_IN_DAY);
    await moveBlocks(1);
    const earningIn24Hours = await staking.earned(owner.address);
    console.log("earningIn24Hours", earningIn24Hours);
  })

  it(`Claim reward `,async function (){
    console.log("balance before reward=>", await rt.balanceOf(owner.address));
    await staking.claimReward();
    console.log("balance after reward=>", await rt.balanceOf(owner.address));
  })

  it(`Withdraw `,async function (){
    // await moveTime(SECONDS_IN_DAY);
    // await moveBlocks(1);
    
    console.log("Balance before withdraw", bigNumberToDecimal(await rt.balanceOf(owner.address)));
    console.log("Is staker", await staking.hasStaked(owner.address))
    expect(await staking.hasStaked(owner.address)).to.equal(true);
    // const stakingBalance = await staking.checkStakingAmount(owner.address); 
    // console.log("Staking balance", stakingBalance);
    console.log("=====================================================================")
    console.log("=> staking.totalSupply() before withdraw", bigNumberToDecimal(await staking.totalSupply()));
    
    // let stakingAmount = decimalToBigNumber("100000");
    // console.log("stakingAmount", bigNumberToDecimal(stakingAmount))
    await staking.withdraw(decimalToBigNumber("100000"));
    console.log("=> staking.totalSupply() after withdraw",bigNumberToDecimal(await staking.totalSupply()));
    // console.log("Balance afrer withdraw", bigNumberToDecimal(await rt.balanceOf(owner.address)));
    console.log("Total supply",bigNumberToDecimal(await staking.totalSupply()));
    console.log("=====================================================================")
    

  })
  
  //put above
});
