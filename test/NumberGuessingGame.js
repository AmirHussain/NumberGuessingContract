// NumberGuessingGame.test.js
const { ethers } = require('hardhat');
const { expect } = require('chai');

describe('NumberGuessingGame', () => {
  let NumberGuessingGame;
  let numberGuessingGame;
  let tokenAddress;
  let contractAddress;
  let token;
  let owner;
  let player;
  let ownerAddess;
  let playerAddess;
  const TOKEN_AMOUNT = ethers.utils.parseEther('100');
  const STAKE_AMOUNT = ethers.utils.parseEther('10');

  beforeEach(async () => {
    [owner, player] = await ethers.getSigners();
    ownerAddess = await owner.getAddress();
    playerAddess = await player.getAddress();
    const Token = await ethers.getContractFactory('customERC20');
    token = await Token.deploy('NUOGUESS', 'NGT', { gasLimit: 10548748 });
    tokenAddress = await token.address;

    NumberGuessingGame = await ethers.getContractFactory('NumberGuessingGame');
    numberGuessingGame = await NumberGuessingGame.deploy(tokenAddress,  { gasLimit: 10548748 });
    contractAddress = await numberGuessingGame.address;
    // Transfer some tokens to the player for testing
    await token.transfer(playerAddess, TOKEN_AMOUNT);
  });

  it('should allow the player to deposit tokens', async () => {
    // Approve the transfer before depositing
    await token.connect(owner);
    await token.approve(contractAddress, STAKE_AMOUNT);
    // Deposit tokens
    await numberGuessingGame.connect(owner);
    await numberGuessingGame.deposit(STAKE_AMOUNT);

    // Check player's balance in the contract
    const playerB = await numberGuessingGame.getPlayerData(ownerAddess);

    console.log(playerB, STAKE_AMOUNT);
    expect(playerB.balance).to.equal(STAKE_AMOUNT);
  });

  it('should not allow the player to play with insufficient balance', async () => {
    await numberGuessingGame.connect(player);
    await expect(numberGuessingGame.playGame(0, 42, STAKE_AMOUNT)).to.be.revertedWith('Insufficient balance');
  });

  it('should allow the player to play the game', async () => {
    // Deposit tokens first
    await numberGuessingGame.connect(owner);
    await token.approve(contractAddress, STAKE_AMOUNT);

    await numberGuessingGame.deposit(STAKE_AMOUNT);

    // Play the game
    await numberGuessingGame.connect(owner);
    const transaction = await numberGuessingGame.playGame(0, 3, STAKE_AMOUNT);
    const receipt = await transaction.wait();
    console.log(receipt.status);
    expect(receipt.status).to.equal(1);
    expect(receipt.from).to.equal(ownerAddess);
    // Add more event checks based on your contract's events

    // Check player's balance and consecutive wins
    const playerData = await numberGuessingGame.players(ownerAddess);
    console.log(playerData.balance);
    expect(playerData.balance).to.equal(ethers.utils.parseUnits('400000000000000000',0));
    expect(playerData.consecutiveWins).to.equal(0);
  });

  it('should allow the owner to withdraw remaining balance', async () => {
    // Deposit tokens first
    await token.connect(owner);
    await token.approve(contractAddress, STAKE_AMOUNT);

    await numberGuessingGame.connect(owner);
    await numberGuessingGame.deposit(STAKE_AMOUNT);

    // Owner withdraws the remaining balance
    await numberGuessingGame.connect(owner);
    const transaction = await numberGuessingGame.withdraw();
    const receipt = await transaction.wait();

    // Check events emitted
    expect(receipt.status).to.equal(1);
    // Add more event checks based on your contract's events

    // Check player's balance is reset to 0 after withdrawal
    const playerData = await numberGuessingGame.players(ownerAddess);
    expect(playerData.balance).to.equal(0);
  });
});
