// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "contracts/external/openzeppelin/contracts/token/ERC20.sol";
import "contracts/external/openzeppelin/contracts/access/Ownable.sol";

contract MockERC20 is ERC20, Ownable {
    constructor(string memory name_, string memory symbol_) 
    ERC20(name_, symbol_)
    {}

    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }
}
