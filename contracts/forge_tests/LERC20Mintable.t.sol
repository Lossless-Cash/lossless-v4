// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./utils/LosslessEnv.t.sol";

contract LERC20MintableTests is LosslessTestEnvironment {

    /// @notice Test deployed Mintable LERC20 variables
    function testLERC20MintableDeploy() public {
      assertEq(lerc20Mintable.totalSupply(), totalSupply);
      assertEq(lerc20Mintable.name(), "LERC20 Mintable");
      assertEq(lerc20Mintable.admin(), address(this));
      assertEq(lerc20Mintable.recoveryAdmin(), address(this));
      assertEq(lerc20Mintable.timelockPeriod(), 1 days);
    }

    /// @notice Test simple mint
    /// @dev Should not revert
    /// @param mintAmount Random mint amount
    function testLERC20Mint(uint8 mintAmount, address randAddress) public {
      uint256 balanceBefore = lerc20Mintable.balanceOf(randAddress);
      lerc20Mintable.mint(randAddress, mintAmount);
      assertEq(lerc20Mintable.balanceOf(randAddress), balanceBefore + mintAmount);
    }

    /// @notice Test simple mint over limit
    /// @dev Should not revert
    /// @param mintAmount Random mint amount
    function testLERC20MintOverLimit(uint8 mintAmount, address randAddress) public {
      uint256 balanceBefore = lerc20Mintable.balanceOf(randAddress);
      evm.expectRevert("LSS: Token mint per period limit");
      lerc20Mintable.mint(randAddress, mintAndBurnLimit + 1);
    }

    /// @notice Test simple mint over limit and mint after a settlement period
    /// @dev Should not revert
    /// @param mintAmount Random mint amount
    function testLERC20MintOverLimitAndWait(uint8 mintAmount, address randAddress) public {
      uint256 balanceBefore = lerc20Mintable.balanceOf(randAddress);
      if (randAddress != address(0)) {
        lerc20Mintable.mint(randAddress, mintAndBurnLimit);
        evm.expectRevert("LSS: Token mint per period limit");
        lerc20Mintable.mint(randAddress, 3);
        evm.warp(block.timestamp + settlementPeriod + 1);
        lerc20Mintable.mint(randAddress, 1000);
        assertEq(lerc20Mintable.balanceOf(randAddress), balanceBefore + mintAndBurnLimit + 1000);
      }
    }

    /// @notice Test mint when not admin
    /// @dev Should revert
    /// @param randAddress Random address
    function testLERC20MintNonAdmin(address randAddress) public {
      evm.startPrank(randAddress);
      evm.expectRevert("LERC20: Must be admin");
      lerc20Mintable.mint(address(1), 1000);
      evm.stopPrank();
    }

    /// @notice Test minting to blacklisted address
    /// @dev Should revert
    /// @param randAddress Random address
    /// @param mintAmt Random mint amount
    function testLERC20MintBlacklisted(address randAddress, uint256 mintAmt) public {
      if (randAddress != address(0)) {
        generateReport(address(lerc20Token), randAddress, reporter);
        evm.expectRevert("LSS: Cannot mint to blacklisted");
        lerc20Mintable.mint(randAddress, mintAmt);
      }
    }
}