
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

  governanceAddress = 0
  
  let governance = await ethers.getContractFactory("Governance")

  if (governanceAddress == 0) {
      console.log("deploy governance on SEPOLIA")
      governance = await governance.deploy()
     
      console.log("governance contract : ",governance.address," tx ",governance.deployTransaction.hash)
      governanceAddress = governance.address
      console.log("deployed governance : ",governance.deployTransaction.hash, governanceAddress)
      recipt = await governance.deployTransaction.wait(8)
      console.log(recipt.status == 1 ? "success": "failed")
      await run("verify:verify", {
          address: governanceAddress,
          constructorArguments: []
      });

  } else {
      governance = await governance.attach(governanceAddress)
  }

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
