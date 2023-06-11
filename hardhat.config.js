require('dotenv').config();
require('@nomicfoundation/hardhat-toolbox');

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  defaultNetwork: 'hardhat',
  gas: 'auto',
  gasPrice: 'auto',

  networks: {
    hardhat: {
      gas: 'auto',
      gasPrice: 'auto',
      // chainId:31337,
      // forking:{url:'url'}
      settings: {
        optimizer: {
          enabled: true,
          runs: 200,
          details: { yul: false }
        }
      }
    },
    sepolia: {
      url: `https://sepolia.infura.io/v3/${process.env.MAINNET_INFURA_ID}`,
      accounts: [process.env.TEST_KEY]
    }
  },
  etherscan: {
    apiKey: {
      sepolia: process.env.ETHERSCAN_API_KEY // ETH
    }
  },

  solidity: '0.8.9'
};
