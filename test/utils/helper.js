const { ethers } = require("hardhat");

const bigToDecimal=(num)=> ethers.utils.formatEther(num);
const decimalToBig=(num)=> ethers.utils.parseEther(num);

module.exports = {
bigToDecimal,decimalToBig
}