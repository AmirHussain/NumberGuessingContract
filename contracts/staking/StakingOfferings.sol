// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
// import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import 'hardhat/console.sol';

contract StakingOfferings {
   
    struct sToken {
        address token_address;
        string token_image;
        string token_symbol;
        string token_name;
    }

    struct StakingOption {
        address staking_contract_address;
        sToken staking_token;
        sToken reward_token;
        uint256 staking_start_time;
        uint256 staking_duration;
        bool isActive;
        bool isExpired;
        uint256 apy;
    }

    StakingOption[] public stakingOptions;
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, 'not authorized');
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function AddStakingOption(
        address staking_contract_address,
        sToken memory staking_token,
        sToken memory reward_token,
        uint256 staking_start_time,
        uint256 staking_duration,
        bool isActive,
        bool isExpired,
        uint256 apy
    ) public returns (bool) {
        StakingOption memory SO;
        SO.staking_token = staking_token;
        SO.reward_token = reward_token;
        SO.staking_contract_address = staking_contract_address;
        SO.staking_start_time = staking_start_time;
        SO.staking_duration = staking_duration;
        SO.isActive = isActive;
        SO.isExpired = isExpired;
        SO.apy = apy;
        stakingOptions.push(SO);
        return true;
    }

    function GetAllStakingOptions() public view returns (StakingOption[] memory) {
        return stakingOptions;
    }

    function GetStakingOption(uint256 _rowIndex) public view returns (StakingOption memory) {
        return stakingOptions[_rowIndex];
    }

    function InactiveStakingOption(uint256 _rowIndex) public onlyOwner returns (bool) {
        stakingOptions[_rowIndex].isActive = false;
        return true;
    }

    function ExprireStakingOption(uint256 _rowIndex) public onlyOwner returns (bool) {
        stakingOptions[_rowIndex].isExpired = true;
        return true;
    }

}
