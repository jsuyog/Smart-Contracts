// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.0 < 0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract yogToken is ERC20 {
    constructor(uint initialSupply) ERC20("Yog", "YG") {
        _mint(msg.sender, initialSupply);
    }
}
