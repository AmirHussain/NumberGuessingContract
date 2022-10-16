const { time, loadFixture } = require('@nomicfoundation/hardhat-network-helpers');
const { anyValue } = require('@nomicfoundation/hardhat-chai-matchers/withArgs');
const { expect } = require('chai');
const { ethers } = require('hardhat');
const { bigToDecimal, decimalToBig, bigToDecimalUints, decimalToBigUints } = require('./utils/helper');

describe('Lending contract test cases', function () {
  let owner, user1, user2, user3, user4, restUsers;
  let weth, fWeth, dai, fDai, lending;
  let OPTIMAL_UTILIZATION_RATE = decimalToBig('0.70');
  let stableRateSlope1 = decimalToBig('0.02')
  let stableRateSlope2 = decimalToBig('0.03')
  let variableRateSlope1 = decimalToBig('0.01')
  let variableRateSlope2 = decimalToBig('0.02')
  let baseRate = decimalToBig('0.04')
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
    await lending.setPercentage(decimalToBig('70'));

  });



  it('2. checking balances and transfering some tokens', async function () {
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

  it('3. lending test', async function () {
    const wethSymbol = await weth.symbol();
    expect(bigToDecimal(await weth.balanceOf(lending.address))).to.equal('10.0');
    expect(bigToDecimal(await weth.balanceOf(owner.address))).to.equal('99970.0');
    expect(bigToDecimal(await fWeth.balanceOf(lending.address))).to.equal('0.0');

    await weth.approve(lending.address, decimalToBig('100'))
    await lending.lend(wethSymbol, decimalToBig('100'), '2', weth.address, fWeth.address);

    expect(bigToDecimal(await weth.balanceOf(lending.address))).to.equal("110.0");
    expect(bigToDecimal(await weth.balanceOf(owner.address))).to.equal("99870.0");

    let lenderIds = await lending.getLenderId(wethSymbol);
    let lendedAssetDetails = await lending.getLenderAsset(1);
    expect(bigToDecimal(await lending.getLenderShare(wethSymbol))).to.equal('100.0')
  });

  it('4 borrow test with hardcoded aggragator values', async function () {
    const wethSymbol = await weth.symbol()
    expect(bigToDecimal(await weth.balanceOf(owner.address))).to.equal("99870.0");
    expect(bigToDecimal(await dai.balanceOf(owner.address))).to.equal("99000.0");
    let colletaralAmount = await lending.getColateralAmount3(decimalToBig('1')); // colletaral for 10 eth
    expect(bigToDecimal(colletaralAmount)).to.equal('1429.236851642857142857')
    await dai.approve(lending.address, colletaralAmount)
    await lending.borrow(
      wethSymbol,
      decimalToBig("80"),
      weth.address,
      dai.symbol(),
      dai.address,
      colletaralAmount,
      decimalToBig("0.04"), //_stableBorrowRate
      false
    );
    expect(bigToDecimal(await weth.balanceOf(owner.address))).to.equal("99871.0");
    expect(bigToDecimal(await dai.balanceOf(owner.address))).to.equal("97570.763148357142857143");

  });

  // it('5. redeem test || Lender going t redeem profit', async function () {
  //   const wethSymbol = await weth.symbol();
  //   let bal = await fWeth.balanceOf(lending.address);
  //   console.log(bigToDecimal(bal))
  //   await fWeth.approve(lending.address,decimalToBig('20'))
  //   await lending.redeem(
  //     wethSymbol, 
  //     decimalToBig('20'), 
  //     weth.address,
  //     1 ,
  //     {OPTIMAL_UTILIZATION_RATE,
  //     stableRateSlope1,
  //     stableRateSlope2,
  //     variableRateSlope1,
  //     variableRateSlope2,
  //     baseRate});

  // });

  // it('6. loan mock test', async function () {
  //   let loanAmount = await lending.getColateralAmount2(
  //     decimalToBig('1000'),    // loan token 1000 DAI 
  //     decimalToBig('1'),  // today 1 eth price is $1000
  //     decimalToBig('1000'),     // colletaral price per token
  //   );
  //   expect(bigToDecimal(loanAmount)).to.equal('1.428571428571428571'); //eth
  // });



  // it('8. calculate_utilizationRatio', async function () {
  //   const result = await lending._utilizationRatio(weth.address);
  //   expect(bigToDecimal(result)).to.equal('0.01');
  // });

  // it('9 getCurrentStableAndVariableBorrowRate', async function () {
  //   const uratio = await lending._utilizationRatio(weth.address);
  //   const IntrestRateModal = {
  //     OPTIMAL_UTILIZATION_RATE,
  //     stableRateSlope1,
  //     stableRateSlope2,
  //     variableRateSlope1,
  //     variableRateSlope2,
  //     baseRate
  //   }

  //   const result = await lending.getCurrentStableAndVariableBorrowRate(
  //     uratio,
  //     IntrestRateModal);
  //   expect(bigToDecimal(result[0])).to.equal("0.04")
  //   expect(bigToDecimal(result[1])).to.equal("0.040142857142857142")
  // });


  // it('0.0 _borrowRate', async function () {
  //   const uratio = decimalToBig('0.0');
  //   const IntrestRateModal = {
  //     OPTIMAL_UTILIZATION_RATE,
  //     stableRateSlope1,
  //     stableRateSlope2,
  //     variableRateSlope1,
  //     variableRateSlope2,
  //     baseRate
  //   }
  //   const result =
  //     await lending.getCurrentStableAndVariableBorrowRate(uratio, IntrestRateModal);
  //   console.log('_borrowRate', bigToDecimal(result[0]), bigToDecimal(result[1]))
  // });

  // it('0.10 _borrowRate', async function () {
  //   const uratio = decimalToBig('0.10');
  //   const IntrestRateModal = {
  //     OPTIMAL_UTILIZATION_RATE,
  //     stableRateSlope1,
  //     stableRateSlope2,
  //     variableRateSlope1,
  //     variableRateSlope2,
  //     baseRate
  //   }
  //   const result =
  //     await lending.getCurrentStableAndVariableBorrowRate(uratio, IntrestRateModal);
  //   console.log('_borrowRate', bigToDecimal(result[0]), bigToDecimal(result[1]))
  // });

  // it('0.20 _borrowRate', async function () {
  //   const uratio = decimalToBig('0.20');
  //   const IntrestRateModal = {
  //     OPTIMAL_UTILIZATION_RATE,
  //     stableRateSlope1,
  //     stableRateSlope2,
  //     variableRateSlope1,
  //     variableRateSlope2,
  //     baseRate
  //   }
  //   const result =
  //     await lending.getCurrentStableAndVariableBorrowRate(uratio, IntrestRateModal);
  //   console.log('_borrowRate', bigToDecimal(result[0]), bigToDecimal(result[1]))
  // });

  // it('0.30 _borrowRate', async function () {
  //   const uratio = decimalToBig('0.30');
  //   const IntrestRateModal = {
  //     OPTIMAL_UTILIZATION_RATE,
  //     stableRateSlope1,
  //     stableRateSlope2,
  //     variableRateSlope1,
  //     variableRateSlope2,
  //     baseRate
  //   }
  //   const result =
  //     await lending.getCurrentStableAndVariableBorrowRate(uratio, IntrestRateModal);
  //   console.log('_borrowRate', bigToDecimal(result[0]), bigToDecimal(result[1]))
  // });

  // it('0.40 _borrowRate', async function () {
  //   const uratio = decimalToBig('0.40');
  //   const IntrestRateModal = {
  //     OPTIMAL_UTILIZATION_RATE,
  //     stableRateSlope1,
  //     stableRateSlope2,
  //     variableRateSlope1,
  //     variableRateSlope2,
  //     baseRate
  //   }
  //   const result =
  //     await lending.getCurrentStableAndVariableBorrowRate(uratio, IntrestRateModal);
  //   console.log('_borrowRate', bigToDecimal(result[0]), bigToDecimal(result[1]))
  // });

  // it('0.50 _borrowRate', async function () {
  //   const uratio = decimalToBig('0.50');
  //   const IntrestRateModal = {
  //     OPTIMAL_UTILIZATION_RATE,
  //     stableRateSlope1,
  //     stableRateSlope2,
  //     variableRateSlope1,
  //     variableRateSlope2,
  //     baseRate
  //   }
  //   const result =
  //     await lending.getCurrentStableAndVariableBorrowRate(uratio, IntrestRateModal);
  //   console.log('_borrowRate', bigToDecimal(result[0]), bigToDecimal(result[1]))
  // });


  // it('0.60 _borrowRate', async function () {
  //   const uratio = decimalToBig('0.60');
  //   const IntrestRateModal = {
  //     OPTIMAL_UTILIZATION_RATE,
  //     stableRateSlope1,
  //     stableRateSlope2,
  //     variableRateSlope1,
  //     variableRateSlope2,
  //     baseRate
  //   }
  //   const result =
  //     await lending.getCurrentStableAndVariableBorrowRate(uratio, IntrestRateModal);
  //   console.log('_borrowRate', bigToDecimal(result[0]), bigToDecimal(result[1]))
  // });

  // it('0.70 _borrowRate', async function () {
  //   const uratio = decimalToBig('0.70');
  //   const IntrestRateModal = {
  //     OPTIMAL_UTILIZATION_RATE,
  //     stableRateSlope1,
  //     stableRateSlope2,
  //     variableRateSlope1,
  //     variableRateSlope2,
  //     baseRate
  //   }
  //   const result =
  //     await lending.getCurrentStableAndVariableBorrowRate(uratio, IntrestRateModal);
  //   console.log('_borrowRate', bigToDecimal(result[0]), bigToDecimal(result[1]))
  // });

  // it('0.80 _borrowRate', async function () {
  //   const uratio = decimalToBig('0.80');
  //   const IntrestRateModal = {
  //     OPTIMAL_UTILIZATION_RATE,
  //     stableRateSlope1,
  //     stableRateSlope2,
  //     variableRateSlope1,
  //     variableRateSlope2,
  //     baseRate
  //   }
  //   const result =
  //     await lending.getCurrentStableAndVariableBorrowRate(uratio, IntrestRateModal);
  //   console.log('_borrowRate', bigToDecimal(result[0]), bigToDecimal(result[1]))
  // });

  // it('11 calculate borrow fee', async function () {
  //   const borrow = await lending.calculateBorrowFee(
  //     {
  //       OPTIMAL_UTILIZATION_RATE,
  //       stableRateSlope1,
  //       stableRateSlope2,
  //       variableRateSlope1,
  //       variableRateSlope2,
  //       baseRate
  //     },
  //     decimalToBig("1"),
  //     weth.address, false
  //   );
  //   let fee = bigToDecimal(borrow[0]);
  //   let paid = bigToDecimal(borrow[1])
  //   expect(fee).to.equal("0.04")
  //   expect(paid).to.equal("1.04")
  // });

  // // it('12 repay test', async function () {
  // //   const ethSymbol = await weth.symbol();
  // //   let id = await lending.getBorrowerId(ethSymbol);
  // //   let detail = await lending.getBorrowerDetails(id[0]);
  // //   await weth.approve(lending.address, detail["loanAmount"]);
  // //   // console.log('repay details',detail)
  // //   expect(bigToDecimal(await weth.balanceOf(owner.address))).to.equal('99871.0');

  // //   await lending.repay(
  // //     detail['loanToken'],
  // //     detail['loanAmount'],
  // //     weth.address,
  // //     dai.address, id[0],
  // //     {
  // //       baseRate,
  // //       OPTIMAL_UTILIZATION_RATE,
  // //       stableRateSlope1,
  // //       stableRateSlope2,
  // //       variableRateSlope1,
  // //       variableRateSlope2
  // //     });
  // //   console.log('owner eth balance after repay =>', bigToDecimal(await weth.balanceOf(owner.address)));
  // //   console.log('dai  balance after repay =>', bigToDecimal(await dai.balanceOf(owner.address)));
  // // });
  // it('13 lendingProfiteRate', async function () {
  //   const uratio = decimalToBig('0.81')
  //   const IntrestRateModal = {
  //     OPTIMAL_UTILIZATION_RATE,
  //     stableRateSlope1,
  //     stableRateSlope2,
  //     variableRateSlope1,
  //     variableRateSlope2,
  //     baseRate
  //   }
  //   const result =
  //     await lending.lendingProfiteRate(weth.address, uratio, IntrestRateModal);
  //   console.log('lendingProfiteRate', bigToDecimal(result));
  // });

  // it('14 calculateCurrentLendingProfitRate ', async function () {
  //   const supplyRate = await lending.calculateCurrentLendingProfitRate(

  //     weth.address,
  //     {
  //       OPTIMAL_UTILIZATION_RATE,
  //       stableRateSlope1,
  //       stableRateSlope2,
  //       variableRateSlope1,
  //       variableRateSlope2,
  //       baseRate
  //     },
  //     ProtocolShare,
  //   );
  //   console.log('calculateCurrentLendingProfitRate', bigToDecimal(supplyRate))

  // });

  // // it('15 getBorrowRateSlope ', async function () {
  // //   const getBorrowRateSlope=await lending.getBorrowRateSlope(

  // //      {OPTIMAL_UTILIZATION_RATE,
  // //     stableRateSlope1,
  // //     stableRateSlope2,
  // //     variableRateSlope1,
  // //     variableRateSlope2,
  // //     baseRate},
  // //     weth.address,

  // //     );
  // //     console.log('getBorrowRateSlope',getBorrowRateSlope)

  // // });
  // // it('16 lendingProfiteRateSlope ', async function () {
  // //   const supplyRate = await lending.lendingProfiteRateSlope(

  // //     weth.address,
  // //     {
  // //       OPTIMAL_UTILIZATION_RATE,
  // //       stableRateSlope1,
  // //       stableRateSlope2,
  // //       variableRateSlope1,
  // //       variableRateSlope2,
  // //       baseRate
  // //     }
  // //   );
  // //   console.log('lendingProfiteRateSlope', bigToDecimal(supplyRate) )

  // // });
  it('17 getChartData ', async function () {
    const data = await lending.getChartData(
      weth.address,
      {
        OPTIMAL_UTILIZATION_RATE,
        stableRateSlope1,
        stableRateSlope2,
        variableRateSlope1,
        variableRateSlope2,
        baseRate
      },
      decimalToBigUints('0.8',2)
    );

    console.log("getChartData", data)

  });
  it('14 getTokenDetails ', async function () {
    const details = await lending.getTokenMarketDetails(
      weth.address
    );
    console.log(details)

  });

 
  it('17 getCurrentLiquidity ', async function () {
  
    const TokenAggregators = [
      { tokenSymbol: '', aggregator: '0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e', decimals: 18 },
      { tokenSymbol: '', aggregator: '0x0d79df66BE487753B02D015Fb622DED7f0E9798d', decimals: 8 }
  ]
  const aggregators=TokenAggregators.map(token=> {return {aggregator:token.aggregator,tokenAddress:weth.address,decimal:decimalToBigUints(token.decimals.toString(),token.decimals>9?0:0)}})
    const data = await lending.getCurrentLiquidity(
      aggregators
    );
    console.log("getCurrentLiquidity", data)
  });
 
 





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
