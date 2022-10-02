const { expect } = require('chai');
const { ethers } = require("hardhat");

describe('Governance contract test cases', function () {
    let governance;
    it('beforeAll', async function () {
        if (network.name != 'hardhat') {
            console.log('PLEASE USE --network hardhat');
            process.exit(0);
        }
        const Token = await ethers.getContractFactory("Governance");

        governance = await Token.deploy();

    });

    it('1. add governance', async function () {
        await governance.AddOrUpdateToken('0x21c639bBC0ce1be64a442dc495867a4F1D2122d0', 'WETH', 'Wrapped Ether',
            '', 'abi', '0x21c639bBC0ce1be64a442dc495867a4F1D2122d0', false, false, true);
        const tokenAddresses = await governance.getAllTokenAddresses()
        const token = await governance.getToken(tokenAddresses[0])
        expect(tokenAddresses.length > 0).to.equal(true)
        expect(token.isDeleted).to.equal(false)

    });



});
