// SPDX-License-Identifier: MIT
// SoulEvo protocol ERC20
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./MinterRole.sol";
import "./FeeRoyaltyModelV1_00.sol";


contract TechTokenV1 is ERC20, MinterRole, FeeRoyaltyModelV1_00 {

    constructor()
    ERC20("Virtual SoulEvo Transfer Fee Token", "vENVLP")
    MinterRole(msg.sender)
    { 
    }

    function mint(address _to, uint256 _value) external onlyMinter {
        _mint(_to, _value);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (msg.sender == wrapper) {
            // not for mint and burn
            if (from != address(0) && to != address(0)) {
                _mint(from, amount);
                _approve(from, wrapper, amount);
                
            }
        }
    }

}
