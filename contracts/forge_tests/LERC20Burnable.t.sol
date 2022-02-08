// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./utils/LosslessEnv.t.sol";

contract LERC20BurnableTests is LosslessTestEnvironment {

    /// @notice Test deployed Burnable LERC20 variables
    function testLERC20BurnableDeploy() public {
      assertEq(lerc20Burnable.totalSupply(), 100000000000000000000);
      assertEq(lerc20Burnable.name(), "LERC20 Burnable");
      assertEq(lerc20Burnable.admin(), address(this));
      assertEq(lerc20Burnable.recoveryAdmin(), address(this));
      assertEq(lerc20Burnable.timelockPeriod(), 1 days);
    }

    /// @notice Test simple burn
    /// @dev Should not revert
    /// @param burnAmount Random burn amount
    function testLERC20Burn(uint8 burnAmount) public {
      lerc20Burnable.transfer(address(1), burnAmount + 10000);
      uint256 balanceBefore = lerc20Burnable.balanceOf(address(1));
      cheats.startPrank(address(1));
      lerc20Burnable.burn(burnAmount);
      cheats.stopPrank();
      assertEq(lerc20Burnable.balanceOf(address(1)), balanceBefore - burnAmount);
    }

    /// @notice Test simple burnFrom
    /// @dev Should not revert
    /// @param burnAmount Random burn amount
    function testLERC20BurnFrom(uint8 burnAmount) public {
      lerc20Burnable.transfer(address(1), burnAmount + 10000);
      uint256 balanceBefore = lerc20Burnable.balanceOf(address(1));
      cheats.prank(address(1));
      lerc20Burnable.approve(address(this), balanceBefore);
      lerc20Burnable.burnFrom(address(1), burnAmount);
      assertEq(lerc20Burnable.balanceOf(address(1)), balanceBefore - burnAmount);
    }

    /// @notice Test burnFrom when not admin
    /// @dev Should revert
    /// @param randAddress Random address
    function testFailLERC20BurnFromNonAdmin(address randAddress) public {
      lerc20Burnable.transfer(address(1), 1500);
      cheats.startPrank(randAddress);
      lerc20Burnable.burnFrom(address(1), 1000);
      cheats.stopPrank();
    }
}