
const {ethers,network} = require("hardhat");

async function main() {
  if (network.name != "obscuro")  {
    console.warn("This needs to be on obscuro");
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

  customERC20Address = 0
  
  let CUSTOM_ERC20 = await ethers.getContractFactory("customERC20")

  if (customERC20Address == 0) {
      console.log("deploy customERC20 on obscuro")
      customERC20 = await CUSTOM_ERC20.deploy('NUOGUESS', 'NGT')
     
      console.log("customERC20 contract : ",customERC20.address," tx ",customERC20.deployTransaction.hash)
      console.log("deployed customERC20 : ",customERC20.deployTransaction.hash, customERC20.address)
      recipt = await customERC20.deployTransaction.wait(2)
      console.log(recipt.status == 1 ? "success": "failed")
      await run("verify:verify", {
          address: customERC20.address,
          constructorArguments: ['NUOGUESS', 'NGT']
      });

  } else {
      customERC20 = await customERC20.attach(customERC20Address)
  }

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
