// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
// import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import 'hardhat/console.sol';

contract VarStakingOfferings {
    struct sToken {
        address token_address;
        string token_image;
        string token_symbol;
        string token_name;
    }

    struct StakingOption {
        address staking_contract_address;
        sToken staking_token;
        string plane_name;
        string min_deposit;
        string max_deposit;
        uint256 life_days;
        uint256 percent;
        uint256 num_of_days;
        uint256 ref_bonus;
        bool isActive;
    }
    uint40 public lastUpdated;
    StakingOption[] public stakingOptions;
    address public _owner;

    modifier onlyOwner() {
        require(msg.sender == _owner, 'not authorized');
        _;
    }

    constructor() {
        _owner = msg.sender;
    }

    function AddStakingOption(
        address staking_contract_address,
        sToken memory staking_token,
        string memory plane_name,
        string memory min_deposit,
        string memory max_deposit,
        uint256 life_days,
        uint256 percent,
        uint256 num_of_days,
        uint256 ref_bonus
    ) public onlyOwner returns (bool) {
        lastUpdated = uint40(block.timestamp);

        StakingOption memory SO;
        SO.staking_token = staking_token;
        SO.plane_name = plane_name;
        SO.min_deposit = min_deposit;
        SO.max_deposit = max_deposit;
        SO.staking_contract_address = staking_contract_address;
        SO.life_days = life_days;
        SO.percent = percent;
        SO.num_of_days = num_of_days;
        SO.ref_bonus = ref_bonus;
        SO.isActive = true;
        stakingOptions.push(SO);
        return true;
    }

    function updateStakingOption(
        address staking_contract_address,
        sToken memory staking_token,
        string memory plane_name,
        string memory min_deposit,
        string memory max_deposit,
        uint256 life_days,
        uint256 percent,
        uint256 num_of_days,
        uint256 ref_bonus,
        bool isActive,
        uint256 stakingId
    ) public onlyOwner returns (bool) {
        lastUpdated = uint40(block.timestamp);

        StakingOption memory SO;
        SO.staking_token = staking_token;
        SO.staking_contract_address = staking_contract_address;
        SO.life_days = life_days;
        SO.percent = percent;
        SO.plane_name = plane_name;
        SO.min_deposit = min_deposit;
        SO.max_deposit = max_deposit;
        SO.num_of_days = num_of_days;
        SO.ref_bonus = ref_bonus;
        SO.isActive = isActive;
        stakingOptions[stakingId] = SO;
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

    function owner() public view returns (address) {
        return _owner;
    }

    function getOwner() external view returns (address) {
        return owner();
    }

    function transferOwner(address newOwner) public onlyOwner returns (bool) {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        lastUpdated = uint40(block.timestamp);

        _owner = newOwner;

        return true;
    }
}