// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../first-version/LERC20.sol";

contract LERC20WithFees is LERC20 {

    modifier onlyAdmin() {
        require(_msgSender() == admin, "LERC20: Must be admin");
        _;
    }

    mapping(address => bool) private excluded;

    uint256 public feeAmount = 10;
    uint256 public feesPool;

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

    function setFees(uint256 fee) public onlyAdmin {
      require(feeAmount != fee, "LERC20: Cannot set same amount");
      feeAmount = fee;
    }

    function withdrawFromPool(address to) public onlyAdmin {
      transfer(to, feesPool);
    }

    function addExcludedAddress(address adr) public onlyAdmin {
      require(!excluded[adr], "LERC20: Already excluded");
      excluded[adr] = true;
    }

    function transfer(address recipient, uint256 amount) public virtual override lssTransfer(recipient, amount) returns (bool) {
        if (!excluded[_msgSender()]) {
          uint256 feeToTake = amount * feeAmount / 1e2;
          amount -= feeToTake;
          feesPool += feeToTake;
          _transfer(_msgSender(), address(this), feeToTake);
        }
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override lssTransferFrom(sender, recipient, amount) returns (bool) {
        uint256 currentAllowance = allowance(sender, _msgSender());
        require(currentAllowance >= amount, "LERC20: transfer amount exceeds allowance");

        if (!excluded[sender]) {
          uint256 feeToTake = amount * feeAmount / 1e2;
          amount -= feeToTake;
          feesPool += feeToTake;
          _transfer(sender, address(this), feeToTake);
        }

        _transfer(sender, recipient, amount);
        
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }
}