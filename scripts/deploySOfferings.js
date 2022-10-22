
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

  stakingOfferingsAddress = 0
  
  let stakingOfferings = await ethers.getContractFactory("StakingOfferings")

  if (stakingOfferingsAddress == 0) {
      console.log("deploy stakingOfferings on GOERLI")
      stakingOfferings = await stakingOfferings.deploy()
     
      console.log("stakingOfferings contract : ",stakingOfferings.address," tx ",stakingOfferings.deployTransaction.hash)
      stakingOfferingsAddress = stakingOfferings.address
      console.log("deployed stakingOfferings : ",stakingOfferings.deployTransaction.hash, stakingOfferingsAddress)
      recipt = await stakingOfferings.deployTransaction.wait(8)
      console.log(recipt.status == 1 ? "success": "failed")
      await run("verify:verify", {
          address: stakingOfferingsAddress,
          constructorArguments: []
      });

  } else {
      stakingOfferings = await stakingOfferings.attach(stakingOfferingsAddress)
  }

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
