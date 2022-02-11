// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./utils/first-version/LERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";

abstract contract LERC20Mintable is Context, LERC20 {

    modifier lssMint(address msgSender, address account, uint256 amount) {
        if (isLosslessOn) {
            lossless.beforeMint(msgSender, account, amount);
        } 
        _;
    }

    function mint(address to, uint256 amount) public virtual lssMint(msg.sender, to, amount) {
        require(msg.sender == admin, "LERC20: Must be admin");
        _mint(to, amount);
    }
}