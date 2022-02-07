// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../LERC20Mintable.sol";

contract LERC20MintableMock is LERC20Mintable {
    constructor(
    uint256 totalSupply_, 
    string memory name_, 
    string memory symbol_, 
    address admin_, 
    address recoveryAdmin_, 
    uint256 timelockPeriod_, 
    address lossless_
    ) LERC20(
    totalSupply_, 
    name_, 
    symbol_, 
    admin_, 
    recoveryAdmin_, 
    timelockPeriod_, 
    lossless_
    ) {}
}