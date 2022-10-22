const { expect } = require('chai');
const { ethers } = require("hardhat");
const { decimalToBig, decimalToBigUints } = require('./utils/helper');

describe('stakingOffering contract test cases', function () {
    let stakingOffering;
    it('beforeAll', async function () {
        if (network.name != 'hardhat') {
            console.log('PLEASE USE --network hardhat');
            process.exit(0);
        }
        const Token = await ethers.getContractFactory("StakingOfferings");

        stakingOffering = await Token.deploy();

    });

    it('1. add stakingOffering', async function () {
        // address staking_contract_address,
        // sToken memory staking_token,
        // sToken memory reward_token,
        // uint256 staking_start_time,
        // uint256 staking_duration,
        // bool isActive,
        // bool isExpired,
        // uint256 apy
        const sToken ={ token_address:'0x21c639bBC0ce1be64a442dc495867a4F1D2122d0',
         token_image:'my token img',
         token_symbol:'my token symbol ',
         token_name:'my token name'
    }
        await stakingOffering.AddStakingOption
            ('0x21c639bBC0ce1be64a442dc495867a4F1D2122d0', sToken, sToken,
            decimalToBigUints(new Date().toString(),0) ,decimalToBig('90') , true,false,decimalToBig('0.1')
            );
        const stakings = await stakingOffering.GetAllStakingOptions()
        console.log(stakings)

    });



});
