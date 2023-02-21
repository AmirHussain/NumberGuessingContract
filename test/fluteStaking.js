const { expect } = require("chai");
const { ethers } = require("hardhat");
const { moveBlocks } = require("./utils/moveBlock");
const { moveTime } = require("./utils/moveTime");
const { decimalToBig, bigToDecimal } = require("./utils/helper");


// oneToken = 1000000000000000000  wie
const SECONDS = 10
const SECONDS_IN_HOUR = 3600
const SECONDS_IN_DAY = 86400
const SECONDS_IN_YEAR = 31449600
const ONE_YEAR = 31449600


describe("Staking test", function () {
  let owner, addr1, addr2, addrs, ftn, rtn, staking

  it("beforeAll", async function () {
    if (network.name != "hardhat") {
      console.log("PLEASE USE --network hardhat");
      process.exit(0);
    }

    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
    ERC20 = await ethers.getContractFactory("customERC20");
    ftn = await ERC20.deploy('Flute Token', 'FTN');
    rtn = await ERC20.deploy('Reward Token', 'RTN');

    FluteStaking = await ethers.getContractFactory("FluteStaking");
    staking = await FluteStaking.deploy(ftn.address, rtn.address);
  });

  it("Checking name symbol & supply", async function () {
    expect(await ftn.name()).to.equal("Flute Token");
    expect(await rtn.name()).to.equal("Reward Token");
    expect(await await rtn.symbol()).to.equal("RTN");
  });

  it("Checking reward when nothing staked", async function () {
    console.log(await staking.rewardPerToken());
    console.log(await staking.lastTimeRewardApplicable());
    console.log(await staking.getBlockTimeStamp());
    await staking.setRewardsDuration("20") //after 20 blocks
  })


  it("Staking to the contract", async function () {
    let amount = decimalToBig("100")
    await rtn.transfer(staking.address,decimalToBig("100000"))
    await staking.setRewardsDuration(SECONDS_IN_DAY);

    await ftn.approve(staking.address,amount)
    await staking.stake(amount) //after 20 blocks
    await staking.notifyRewardAmount(decimalToBig("1"));
    await moveTime(SECONDS_IN_DAY + SECONDS_IN_DAY);
    await moveBlocks(100);


    console.log("Reward per token ", await staking.rewardPerToken());
    let earned = bigToDecimal(await staking.earned(owner.address));
    console.log("earned", earned)
    console.log("Timestamp",await staking.getBlockTimeStamp());
    console.log("lastTimeRewardApplicable",await staking.lastTimeRewardApplicable());



  })

  it("Minting some tokens", async function () {
    console.log("Balance of owner =>", bigToDecimal(await ftn.balanceOf(owner.address)));

    // await ftn.mint(decimalToBig("1000"));
  })












  // it("Staking 100000 tokens",async function (){

  //   let stakingAmount = decimalToBigNumber("100000");
  //   await (rt).approve(staking.address,stakingAmount);
  //   await staking.stake(stakingAmount);

  //   console.log("Balance after staking =>", bigNumberToDecimal(await rt.balanceOf(owner.address)));
  //   const earnedFromStaking = await staking.earned(owner.address);
  //   console.log("Total supply",bigNumberToDecimal(await staking.totalSupply()))
  //   console.log("earnedFromStaking",bigNumberToDecimal(earnedFromStaking));
  // })

  // it(`Afrer ${SECONDS_IN_DAY} seconds`,async function (){
  //   await moveTime(SECONDS_IN_DAY);
  //   await moveBlocks(1);
  //   const earningIn24Hours = await staking.earned(owner.address);
  //   console.log("earningIn24Hours", earningIn24Hours);
  // })

  // it(`Claim reward `,async function (){
  //   console.log("balance before reward=>", await rt.balanceOf(owner.address));
  //   await staking.claimReward();
  //   console.log("balance after reward=>", await rt.balanceOf(owner.address));
  // })

  // it(`Withdraw `,async function (){
  //   // await moveTime(SECONDS_IN_DAY);
  //   // await moveBlocks(1);

  //   console.log("Balance before withdraw", bigNumberToDecimal(await rt.balanceOf(owner.address)));
  //   console.log("Is staker", await staking.hasStaked(owner.address))
  //   expect(await staking.hasStaked(owner.address)).to.equal(true);
  //   // const stakingBalance = await staking.checkStakingAmount(owner.address); 
  //   // console.log("Staking balance", stakingBalance);
  //   console.log("=====================================================================")
  //   console.log("=> staking.totalSupply() before withdraw", bigNumberToDecimal(await staking.totalSupply()));

  //   // let stakingAmount = decimalToBigNumber("100000");
  //   // console.log("stakingAmount", bigNumberToDecimal(stakingAmount))
  //   await staking.withdraw(decimalToBigNumber("100000"));
  //   console.log("=> staking.totalSupply() after withdraw",bigNumberToDecimal(await staking.totalSupply()));
  //   // console.log("Balance afrer withdraw", bigNumberToDecimal(await rt.balanceOf(owner.address)));
  //   console.log("Total supply",bigNumberToDecimal(await staking.totalSupply()));
  //   console.log("=====================================================================")


  // })

  //put above
});
