
const {ethers,network} = require("hardhat");

async function main() {
  if (network.name != "sepolia")  {
    console.warn("This needs to be on SEPOLIA");
    process.exit(1)
}
const [owner] = await ethers.getSigners();
console.log(network.name);
console.log("owner",await owner.getAddress());
await deployStuff();
}

async function deployStuff() {
  const [deployer] = await ethers.getSigners();
  console.log("deployer : ",deployer.address)

  stakingAddress = 0
  
  let CUSTOM_ERC20 = await ethers.getContractFactory("VernoStaking")

  if (stakingAddress == 0) {
      console.log("deploy staking on SEPOLIA")
      FluteStaking = await CUSTOM_ERC20.deploy('')
     
      console.log("staking contract : ",FluteStaking.address," tx ",FluteStaking.deployTransaction.hash)
      console.log("deployed staking : ",FluteStaking.deployTransaction.hash, FluteStaking.address)
      recipt = await FluteStaking.deployTransaction.wait(2)
      console.log(recipt.status == 1 ? "success": "failed")
      await run("verify:verify", {
          address: FluteStaking.address,
          constructorArguments: []
      });

  } else {
      staking = await staking.attach(stakingAddress)
  }

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
