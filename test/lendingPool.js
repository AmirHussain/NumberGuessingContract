const { time, loadFixture } = require('@nomicfoundation/hardhat-network-helpers');
const { anyValue } = require('@nomicfoundation/hardhat-chai-matchers/withArgs');
const { expect } = require('chai');
const { ethers } = require('hardhat');
const { bigToDecimal, decimalToBig } = require('./utils/helper');

describe('Lending contract test cases', function () {
  let owner, user1, user2, user3, user4, restUsers;
  let weth, fWeth, dai, fDai, lending;

  it('beforeAll', async function () {
    if (network.name != 'hardhat') {
      console.log('PLEASE USE --network hardhat');
      process.exit(0);
    }
    console.log('start');
    [owner, user1, user2, user3, user4, ...restUsers] = await ethers.getSigners();
    console.log('OWNER ', owner.address);
    console.log('USER1 ', user1.address);
    console.log('USER2 ', user2.address);
  });

  it('1. deploying tokens and lending', async function () {
    ERC20 = await ethers.getContractFactory('customERC20');
    weth = await ERC20.deploy('Wrapped Ether', 'WETH');
    fWeth = await ERC20.deploy('Pledged Wrapped Ether', 'fWETH');
    dai = await ERC20.deploy('Dai Stable Coin', 'DAI');
    fDai = await ERC20.deploy('Pledged Dai Stable Coin', 'fDAI');
    console.log(weth.address);

    LENDING = await ethers.getContractFactory('LendingPool');
    // lending = await LENDING.deploy(weth.address, fWeth.address, dai.address, fDai.address);
    lending = await LENDING.deploy();
    console.log('Lending address => ', lending.address);
    await weth.setAuthorisedMinter(lending.address, true);
    await fWeth.setAuthorisedMinter(lending.address, true);
    await dai.setAuthorisedMinter(lending.address, true);
    await fDai.setAuthorisedMinter(lending.address, true);
    expect(await weth.isAuthorisedMinter(lending.address)).to.equal(true)
    expect(await fWeth.isAuthorisedMinter(lending.address)).to.equal(true)
    expect(await dai.isAuthorisedMinter(lending.address)).to.equal(true)
    expect(await fDai.isAuthorisedMinter(lending.address)).to.equal(true)
  });
  
  
  
  it('2 checking balances and transfering some tokens', async function () {
    expect(bigToDecimal(await weth.balanceOf(owner.address))).to.equal('100000.0')
    await weth.transfer(user1.address, decimalToBig('10.0'));
    await weth.transfer(user2.address, decimalToBig('10'));
    await weth.transfer(lending.address, decimalToBig('10'));
    await dai.transfer(lending.address, decimalToBig('1000'));

    expect(bigToDecimal(await weth.balanceOf(user1.address))).to.equal("10.0")
    expect(bigToDecimal(await weth.balanceOf(user2.address))).to.equal("10.0")
    expect(bigToDecimal(await weth.balanceOf(lending.address))).to.equal("10.0")
    expect(bigToDecimal(await dai.balanceOf(lending.address))).to.equal("1000.0")
    expect(bigToDecimal(await weth.balanceOf(owner.address))).to.equal("99970.0")
  });

  it('3. user1 lend 50 weth lendFunction test', async function () {
    const symbol = await weth.symbol();
    console.log('lending balance before lend =>', bigToDecimal(await weth.balanceOf(lending.address)));
    console.log('owner  balance before lend =>', bigToDecimal(await weth.balanceOf(owner.address)));
    console.log('lending balance in fweth before lend =>', bigToDecimal(await fWeth.balanceOf(lending.address)));
    
    await weth.approve(lending.address,decimalToBig('50'))
    await lending.lend(symbol, decimalToBig('50'), '2', weth.address,fWeth.address);
    
    console.log('lending balance in fweth before after lend =>', bigToDecimal(await weth.balanceOf(lending.address)));
    console.log('lending balance after lend =>', bigToDecimal(await weth.balanceOf(lending.address)));
    console.log('owner  balance after lend =>', bigToDecimal(await weth.balanceOf(owner.address)));

    let lenderIds = await lending.getLenderId(symbol);
    let lendedAssetDetails = await lending.getLenderAsset(1);
    let lenderShare = await lending.getLenderShare(symbol);
    console.log(bigToDecimal(lenderShare));
  });


  // it('4 redeem test', async function () {
  //   const symbol = await weth.symbol();
  //   await fWeth.approve(lending.address,decimalToBig('20'))
  //   await lending.redeem(symbol, decimalToBig('20'), weth.address,1);

  //   let lenderIds = await lending.getLenderId(symbol);
  //   let lendedAssetDetails = await lending.getLenderAsset(1);
  //   let lenderShare = await lending.getLenderShare(symbol);
  //   console.log(bigToDecimal(lenderShare));
  //   // console.log(lendedAssetDetails);
  // });
  // it('5 loan mock test', async function () {
  //     await lending.setPercentage(decimalToBig('70'));
  //  let loadAmount = await lending.getLoanAmount2(
  //   '1000',    // collletaral name and amount dia 
  //   '1',  // colletaral price 1
  //   '1000',     // load token eth with price 1000
  //    );
  //   console.log("loadAmount => ", bigToDecimal(loadAmount));
  //   // console.log(lendedAssetDetails);
  // });


  // it('6 borrow test', async function () {
  //   const symbol = await weth.symbol();
  //   console.log('owner eth balance before borrow =>', bigToDecimal(await weth.balanceOf(owner.address)));
  //   console.log('dai  balance before borrow =>', bigToDecimal(await dai.balanceOf(owner.address)));
  //   await weth.approve(lending.address,10)
  //   await lending.borrow(symbol,10, weth.address,dai.address);
  //   console.log('owner  balance before borrow =>', bigToDecimal(await weth.balanceOf(owner.address)));
  //   console.log('dai  balance before borrow =>', bigToDecimal(await dai.balanceOf(owner.address)));
    
  // });
  
  // it('7 repay test', async function () {
  //   const symbol = await weth.symbol();
  //   console.log('owner eth balance before borrow =>', bigToDecimal(await weth.balanceOf(lending.address)));
  //   console.log('dai  balance before borrow =>', bigToDecimal(await dai.balanceOf(lending.address)));
  //   await dai.approve(lending.address,7000)
  //   await lending.repay(symbol,10, weth.address, dai.address, 7000,0);
  //   console.log('owner eth balance before borrow =>', bigToDecimal(await weth.balanceOf(lending.address)));
  //   console.log('dai  balance before borrow =>', bigToDecimal(await dai.balanceOf(lending.address)));
  // });



  //   async function deployOneYearLockFixture() {
  //     const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60;
  //     const ONE_MONTH_IN_SECS = 30 * 24 * 60 * 60;
  //     const ONE_DAY_IN_SECS = 1 * 24 * 60 * 60;
  //     const ONE_GWEI = 1_000_000_000;

  //     const lockedAmount = ONE_GWEI;
  //     const unlockTime = (await time.latest()) + ONE_YEAR_IN_SECS;

  //     // Contracts are deployed using the first signer/account by default
  //     const [owner, otherAccount] = await ethers.getSigners();

  //     const Lock = await ethers.getContractFactory('Lock');
  //     const lock = await Lock.deploy(unlockTime, { value: lockedAmount });

  //     return { lock, unlockTime, lockedAmount, owner, otherAccount };
  //   }

  //   describe('Deployment', function () {
  //     it('Should set the right unlockTime', async function () {
  //       const { lock, unlockTime } = await loadFixture(deployOneYearLockFixture);

  //       expect(await lock.unlockTime()).to.equal(unlockTime);
  //     });

  //     it('Should set the right owner', async function () {
  //       const { lock, owner } = await loadFixture(deployOneYearLockFixture);

  //       expect(await lock.owner()).to.equal(owner.address);
  //     });

  //     it('Should receive and store the funds to lock', async function () {
  //       const { lock, lockedAmount } = await loadFixture(deployOneYearLockFixture);

  //       expect(await ethers.provider.getBalance(lock.address)).to.equal(lockedAmount);
  //     });

  //     it('Should fail if the unlockTime is not in the future', async function () {
  //       // We don't use the fixture here because we want a different deployment
  //       const latestTime = await time.latest();
  //       const Lock = await ethers.getContractFactory('Lock');
  //       await expect(Lock.deploy(latestTime, { value: 1 })).to.be.revertedWith('Unlock time should be in the future');
  //     });
  //   });

  //   describe('Withdrawals', function () {
  //     describe('Validations', function () {
  //       it('Should revert with the right error if called too soon', async function () {
  //         const { lock } = await loadFixture(deployOneYearLockFixture);

  //         await expect(lock.withdraw()).to.be.revertedWith("You can't withdraw yet");
  //       });

  //       it('Should revert with the right error if called from another account', async function () {
  //         const { lock, unlockTime, otherAccount } = await loadFixture(deployOneYearLockFixture);

  //         // We can increase the time in Hardhat Network
  //         await time.increaseTo(unlockTime);

  //         // We use lock.connect() to send a transaction from another account
  //         await expect(lock.connect(otherAccount).withdraw()).to.be.revertedWith("You aren't the owner");
  //       });

  //       it("Shouldn't fail if the unlockTime has arrived and the owner calls it", async function () {
  //         const { lock, unlockTime } = await loadFixture(deployOneYearLockFixture);

  //         // Transactions are sent using the first signer by default
  //         await time.increaseTo(unlockTime);

  //         await expect(lock.withdraw()).not.to.be.reverted;
  //       });
  //     });

  //     describe('Events', function () {
  //       it('Should emit an event on withdrawals', async function () {
  //         const { lock, unlockTime, lockedAmount } = await loadFixture(deployOneYearLockFixture);

  //         await time.increaseTo(unlockTime);

  //         await expect(lock.withdraw()).to.emit(lock, 'Withdrawal').withArgs(lockedAmount, anyValue); // We accept any value as `when` arg
  //       });
  //     });

  //     describe('Transfers', function () {
  //       it('Should transfer the funds to the owner', async function () {
  //         const { lock, unlockTime, lockedAmount, owner } = await loadFixture(deployOneYearLockFixture);

  //         await time.increaseTo(unlockTime);

  //         await expect(lock.withdraw()).to.changeEtherBalances([owner, lock], [lockedAmount, -lockedAmount]);
  //       });
  //     });
  //   });
});
