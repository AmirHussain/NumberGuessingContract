
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
  
  let CUSTOM_ERC20 = await ethers.getContractFactory("customERC20")

  if (lendingAddress == 0) {
      console.log("deploy lending on SEPOLIA")
      customERC20 = await CUSTOM_ERC20.deploy('Flute Finance Token', 'FFT')
     
      console.log("lending contract : ",customERC20.address," tx ",customERC20.deployTransaction.hash)
      console.log("deployed lending : ",customERC20.deployTransaction.hash, customERC20.address)
      recipt = await customERC20.deployTransaction.wait(2)
      console.log(recipt.status == 1 ? "success": "failed")
      await run("verify:verify", {
          address: customERC20.address,
          constructorArguments: ['Flute Finance Token', 'FFT']
      });

  } else {
      lending = await LENDING.attach(lendingAddress)
  }

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
