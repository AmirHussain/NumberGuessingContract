const { ethers } = require("hardhat");

const bigToDecimal=(num)=> ethers.utils.formatEther(num);
const decimalToBig=(num)=> ethers.utils.parseEther(num);
const bigToDecimalUints=(num,units)=> ethers.utils.formatEther(num,units);
const decimalToBigUints=(num,units)=> ethers.utils.parseUnits(num,units);

module.exports = {
bigToDecimal,decimalToBig,bigToDecimalUints,decimalToBigUints
}