//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract RewardToken is ERC20 {
    uint8 public _decimals = 18;
    address public owner;
    
    constructor() ERC20("Reward Token", "RT") {
        _mint(msg.sender, 100**_decimals);
        owner = msg.sender;
    }
        modifier onlyOwner() {
        require(msg.sender == owner,"Only owner of the contract can run this operation");
        _;
    }

    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }
}