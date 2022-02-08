// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./utils/LosslessEnv.t.sol";

contract LERC20MintableTests is LosslessTestEnvironment {

    /// @notice Test deployed Mintable LERC20 variables
    function testLERC20MintableDeploy() public {
      assertEq(lerc20Mintable.totalSupply(), 100000000000);
      assertEq(lerc20Mintable.name(), "LERC20 Mintable");
      assertEq(lerc20Mintable.admin(), address(this));
      assertEq(lerc20Mintable.recoveryAdmin(), address(this));
      assertEq(lerc20Mintable.timelockPeriod(), 1 days);
    }

    /// @notice Test simple mint
    /// @dev Should not revert
    /// @param mintAmount Random mint amount
    function testLERC20Mint(uint256 mintAmount) public {
      uint256 balanceBefore = lerc20Mintable.balanceOf(address(1));
      lerc20Mintable.mint(address(1), mintAmount);
      assertEq(lerc20Mintable.balanceOf(address(1)), balanceBefore + mintAmount);
    }

    /// @notice Test mint when not admin
    /// @dev Should revert
    /// @param randAddress Random address
    function testFailLERC20MintNonAdmin(address randAddress) public {
      cheats.startPrank(randAddress);
      lerc20Mintable.mint(address(1), 1000);
      cheats.stopPrank();
    }
}