
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

  governanceVotingAddress = 0
  
  let governanceVoting = await ethers.getContractFactory("GovernanceVoting")

  if (governanceVotingAddress == 0) {
      console.log("deploy governanceVoting voting on GOERLI")
      governanceVoting = await governanceVoting.deploy()
     
      console.log("governanceVoting contract : ",governanceVoting.address," tx ",governanceVoting.deployTransaction.hash)
      governanceVotingAddress = governanceVoting.address
      console.log("deployed governanceVoting : ",governanceVoting.deployTransaction.hash, governanceVotingAddress)
      recipt = await governanceVoting.deployTransaction.wait(8)
      console.log(recipt.status == 1 ? "success": "failed")
      await run("verify:verify", {
          address: governanceVotingAddress,
          constructorArguments: []
      });

  } else {
      governanceVoting = await governanceVoting.attach(governanceVotingAddress)
  }

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
