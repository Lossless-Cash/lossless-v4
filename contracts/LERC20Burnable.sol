// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./utils/first-version/LERC20.sol";
import "./utils/first-version/Context.sol";

abstract contract LERC20Burnable is Context, LERC20 {

    modifier lssBurn(address account, uint256 amount) {
        if (isLosslessOn) {
            lossless.beforeBurn(account, amount);
        } 
        _;
    }

    function burn(uint256 amount) public virtual lssBurn(_msgSender(), amount) {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public virtual lssBurn(account, amount) {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
}