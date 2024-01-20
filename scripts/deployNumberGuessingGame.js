
const { ethers, network } = require("hardhat");

async function main() {
  if (network.name != "obscuro") {
    console.warn("This needs to be on obscuro");
    process.exit(1)
  }
  const [owner] = await ethers.getSigners();
  console.log(network.name);
  console.log("owner", await owner.getAddress());
  await deployStuff();
}

async function deployStuff() {
  const [deployer] = await ethers.getSigners();
  console.log("deployer : ", deployer.address)

  NumberGuessingGameAddress = 0

  let NumberGuessingGame = await ethers.getContractFactory("NumberGuessingGame")

  if (NumberGuessingGameAddress == 0) {
    console.log("deploy NumberGuessingGame on obscuro")
    NumberGuessingGame = await NumberGuessingGame.deploy('0x02e1D4BA29c46dC8153548C4bC37a6594F8eaEc1')

    console.log("NumberGuessingGame contract : ", NumberGuessingGame.address, " tx ", NumberGuessingGame.deployTransaction.hash)
    console.log("deployed NumberGuessingGame : ", NumberGuessingGame.deployTransaction.hash, NumberGuessingGame.address)
    recipt = await NumberGuessingGame.deployTransaction.wait(2)
    console.log(recipt.status == 1 ? "success" : "failed")
    await run("verify:verify", {
      address: NumberGuessingGame.address,
      constructorArguments: ['0x02e1D4BA29c46dC8153548C4bC37a6594F8eaEc1']
    });

  } else {
    NumberGuessingGame = await NumberGuessingGame.attach(NumberGuessingGameAddress)
  }

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
