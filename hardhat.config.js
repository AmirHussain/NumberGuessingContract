require("@nomicfoundation/hardhat-toolbox");

const alchemy_api_key='uPmjCLS1ipphHFXTKDctQN8GYoQ1wCSR'
/** @type import('hardhat/config').HardhatUserConfig */
const GOERLI_PRIVATE_KEY = "e206df84d255451dae5ae8dd8efb3674";
module.exports = {
  solidity: "0.8.9",
  networks: {
    localhost: {
      url: "http://127.0.0.1:8545",
      account:['0xFE029208b267daBF5077bB3E3E7B1cc9916e9943']
    },
    hardhat:{
      chainId: 1337
    },
    goerli:{
        url: `https://eth-goerli.g.alchemy.com/v2/uPmjCLS1ipphHFXTKDctQN8GYoQ1wCSR`,
        chainId: 5

    }
  }
};
