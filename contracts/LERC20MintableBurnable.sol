// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./utils/first-version/LERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";

abstract contract LERC20MintableBurnable is Context, LERC20 {

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


    modifier lssMint(address msgSender, address account, uint256 amount) {
        if (isLosslessOn) {
            lossless.beforeMint(msgSender, account, amount);
        } 
        _;
    }

    function mint(address to, uint256 amount) public virtual lssMint(_msgSender(), to, amount) {
        require(_msgSender() == admin, "LERC20: Must be admin");
        _mint(to, amount);
    }
}