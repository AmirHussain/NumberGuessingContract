// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CustomERC20 is ERC20, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name ;
    string private _symbol;


    constructor(
        string memory tokenName, 
        string memory tokensymbol
        ) 
        ERC20(tokenName, tokensymbol) {
            _name = tokenName;
            _symbol = tokensymbol;
        
    }

    function mint(address _to, uint256 amount) public onlyOwner {
         require(_to != address(0), "ERC20: mint to the zero address");
        _mint(_to, amount);
         _totalSupply += amount;
        _balances[_to] += amount;
        emit Transfer(address(0), _to, amount);
    }
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256){
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom( address from, address to, uint256 amount) public virtual override returns (bool) {
        _transfer(from, to, amount);
        return true;
    }
}
