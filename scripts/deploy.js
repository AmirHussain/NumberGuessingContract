
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

  lendingAddress = 0
  
  let LENDING = await ethers.getContractFactory("LendingPool")

  if (lendingAddress == 0) {
      console.log("deploy lending on SEPOLIA")
      lending = await LENDING.deploy()
     
      console.log("lending contract : ",lending.address," tx ",lending.deployTransaction.hash)
      lendingAddress = lending.address
      console.log("deployed lending : ",lending.deployTransaction.hash, lendingAddress)
      recipt = await lending.deployTransaction.wait(8)
      console.log(recipt.status == 1 ? "success": "failed")
      await run("verify:verify", {
          address: lendingAddress,
          constructorArguments: []
      });

  } else {
      lending = await LENDING.attach(lendingAddress)
  }

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
