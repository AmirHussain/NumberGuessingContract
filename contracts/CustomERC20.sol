// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract customERC20 is ERC20, Ownable {
    string private _name;
    string private _symbol;
    mapping(address => bool) public authorisedMinters;
    event AuthChanged(address user, bool auth);

    modifier onlyAuth() {
        require(authorisedMinters[msg.sender] || msg.sender == owner(), 'Not Authorised');
        _;
    }

    constructor(string memory tokenName, string memory tokensymbol) ERC20(tokenName, tokensymbol) {
        _name = tokenName;
        _symbol = tokensymbol;
        mint(msg.sender, 100000 * 10**decimals());
    }

    function mint(address to, uint256 amount) public onlyAuth {
        _mint(to, amount);
    }

    function burn(address to, uint256 amount) public onlyAuth {
        _burn(to, amount);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function setAuthorisedMinter(address user, bool auth) public onlyOwner {
        authorisedMinters[user] = auth;
        emit AuthChanged(user, auth);
    }

    function isAuthorisedMinter(address _account) public view returns (bool) {
        return authorisedMinters[_account];
    }
}
