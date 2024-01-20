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
      accounts: [process.env.ACCOUNT_SECRET]
    },
    obscuro:{
      url:'https://testnet.ten.xyz/v1/?token=55e3fa57526b9c2aeb70bac2d6ff38dc68b62292',
      accounts:[process.env.ACCOUNT_SECRET]
    }
  },
  etherscan: {
    apiKey: {
      obscuro: process.env.ETHERSCAN_API_KEY // ETH
    },
    customChains: [
      {
        network: "obscuro",
        chainId: 443,
        urls: {
          apiURL: "https://testnet.tenscan.io/",
          browserURL: "https://testnet.tenscan.io"
        }
      }
    ]
  },

  solidity: '0.8.9'
};
