//  _____                       _ _     _______    _              
// |  __ \                     (_) |   |__   __|  | |             
// | |  | | ___ _ __   ___  ___ _| |_     | | ___ | | _____ _ __  
// | |  | |/ _ \ '_ \ / _ \/ __| | __|    | |/ _ \| |/ / _ \ '_ \ 
// | |__| |  __/ |_) | (_) \__ \ | |_     | | (_) |   <  __/ | | |
// |_____/ \___| .__/ \___/|___/_|\__|    |_|\___/|_|\_\___|_| |_|
//             | |                                                
//             |_|                                                
//
// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DepositToken is ERC20 {

    constructor(uint256 initialSupply) ERC20("DepositToken", "DPTKN") {
        _mint(msg.sender, initialSupply);
    }
}
