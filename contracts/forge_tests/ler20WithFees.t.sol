// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./utils/LosslessEnv.t.sol";

contract LERC20WithFeesTests is LosslessTestEnvironment {

    /// @notice Test deployed Burnable LERC20 variables
    function testLERC20BurnableDeploy() public {
      assertEq(lerc20WithFees.totalSupply(), totalSupply);
      assertEq(lerc20WithFees.name(), "LERC20 With fees");
      assertEq(lerc20WithFees.admin(), address(this));
      assertEq(lerc20WithFees.recoveryAdmin(), address(this));
      assertEq(lerc20WithFees.timelockPeriod(), 1 days);
    }

    /// @notice Test transfer with fees
    /// @dev Should not revert 
    function testLERC20WithFeesTransfer(uint8 randAmount, address randAddress, address anotherRandAddress) public {
      if (randAddress != address(0) && anotherRandAddress != address(0)) {
        evm.startPrank(address(this));
        lerc20WithFees.addExcludedAddress(address(this));
        lerc20WithFees.transfer(randAddress, randAmount);
        evm.stopPrank();

        assertEq(lerc20WithFees.balanceOf(address(lerc20WithFees)), 0);
        assertEq(lerc20WithFees.balanceOf(randAddress), randAmount);
        assertEq(lerc20WithFees.feesPool(), 0);

        evm.prank(randAddress);
        lerc20WithFees.transfer(anotherRandAddress, randAmount);

        uint256 feeToTake = randAmount * lerc20WithFees.feeAmount() / 1e2;

        assertEq(lerc20WithFees.balanceOf(address(lerc20WithFees)), feeToTake);
        assertEq(lerc20WithFees.balanceOf(anotherRandAddress), randAmount - feeToTake);
        assertEq(lerc20WithFees.feesPool(), feeToTake);
      }
    } 

    /// @notice Test transfer with fees
    /// @dev Should not revert 
    function testLERC20WithFeesTransferFrom(uint8 randAmount, address randAddress, address anotherRandAddress) public {
      if (randAddress != address(0) && anotherRandAddress != address(0)) {
        evm.startPrank(address(this));
        lerc20WithFees.addExcludedAddress(address(this));
        lerc20WithFees.transfer(randAddress, randAmount);
        evm.stopPrank();

        assertEq(lerc20WithFees.balanceOf(address(lerc20WithFees)), 0);
        assertEq(lerc20WithFees.balanceOf(randAddress), randAmount);
        assertEq(lerc20WithFees.feesPool(), 0);

        lerc20WithFees.transferFrom(randAddress, anotherRandAddress, randAmount);

        uint256 feeToTake = randAmount * lerc20WithFees.feeAmount() / 1e2;

        assertEq(lerc20WithFees.balanceOf(address(lerc20WithFees)), feeToTake);
        assertEq(lerc20WithFees.balanceOf(anotherRandAddress), randAmount - feeToTake);
        assertEq(lerc20WithFees.feesPool(), feeToTake);
      }
    } 
}