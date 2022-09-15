require('dotenv').config();
require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  defaultNetwork: "hardhat",
  networks:{
    hardhat: {},
    goerli: {
      url: `https://goerli.infura.io/v3/${process.env.MAINNET_INFURA_ID}`,
      accounts: [process.env.TEST_KEY]
    },
  },
  etherscan: {
    apiKey: {
      goerli: process.env.ETHERSCAN_API_KEY, // ETH
    }
  },

  solidity: "0.8.9",
};
