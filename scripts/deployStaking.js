
const {ethers,network} = require("hardhat");

async function main() {
  if (network.name != "goerli")  {
    console.warn("This needs to be on GOERLI");
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
  
  let CUSTOM_ERC20 = await ethers.getContractFactory("FluteStaking")

  if (stakingAddress == 0) {
      console.log("deploy staking on GOERLI")
      FluteStaking = await CUSTOM_ERC20.deploy('0x933458F3F0154c3141b044eB77D20a409e614028', '0xFb156f075E7F00c80abEBFD4BaB3b9258F5D8B13')
     
      console.log("staking contract : ",FluteStaking.address," tx ",FluteStaking.deployTransaction.hash)
      console.log("deployed staking : ",FluteStaking.deployTransaction.hash, FluteStaking.address)
      recipt = await FluteStaking.deployTransaction.wait(2)
      console.log(recipt.status == 1 ? "success": "failed")
      await run("verify:verify", {
          address: FluteStaking.address,
          constructorArguments: ['0x933458F3F0154c3141b044eB77D20a409e614028', '0xFb156f075E7F00c80abEBFD4BaB3b9258F5D8B13']
      });

  } else {
      staking = await staking.attach(stakingAddress)
  }

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
