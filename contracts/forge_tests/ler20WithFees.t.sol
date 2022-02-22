// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./utils/LosslessEnv.t.sol";

contract LERC20WithFeesTests is LosslessTestEnvironment {

    /// @notice Test deployed Burnable LERC20 variables
    function testLERC20withFeesDeploy() public {
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
      if ((randAddress != address(0) && anotherRandAddress != address(0)) && (randAddress != anotherRandAddress)) {
        evm.prank(randAddress);
        lerc20WithFees.approve(address(this), randAmount);

        lerc20WithFees.transfer(randAddress, randAmount);

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

  /// @notice Test Committee members claiming their rewards when all participating
  /// @dev Should not revert and update balances correctly
  ///      reported amount * committee rewards / all members
  function testLERC20WithFeesClaimAllParticipating() public {
    uint256[5] memory memberBalances;

    for (uint i = 0; i < committeeMembers.length; i++) {
      memberBalances[i] = lerc20WithFees.balanceOf(committeeMembers[i]);
    }

    uint256 reportId = generateReport(address(lerc20WithFees), maliciousActor, reporter);
    solveReportPositively(reportId);

    for (uint i = 0; i < committeeMembers.length; i++) {
      evm.prank(committeeMembers[i]);
      lssGovernance.claimCommitteeReward(reportId);
      uint256 newBalance =  memberBalances[i] + ((reportedAmount * committeeReward) / 1e2) / committeeMembers.length;
      assertEq(lerc20WithFees.balanceOf(committeeMembers[i]), newBalance);  
    }
  }

  /// @notice Test Committee members claiming their rewards when some participating
  /// @dev Should not revert and update balances correctly
  ///      reported amount * committee rewards / all members
  function testLERC20WithFeesClaimSomeParticipating() public {
    uint totalMembers = committeeMembers.length;
    uint256[5] memory memberBalances;
    uint256 participatingMembers = 3;

    for (uint i = 0; i < totalMembers; i++) {
      memberBalances[i] = lerc20WithFees.balanceOf(committeeMembers[i]);
    }

    uint256 reportId = generateReport(address(lerc20WithFees), maliciousActor, reporter);
    solveReport(reportId, participatingMembers, true, true, true);

    for (uint i = 0; i < totalMembers; i++) {
      evm.startPrank(committeeMembers[i]);
      if (i < participatingMembers) {
        lssGovernance.claimCommitteeReward(reportId);
        uint256 newBalance =  memberBalances[i] + ((reportedAmount * committeeReward) / 1e2) / participatingMembers;
        assertEq(lerc20WithFees.balanceOf(committeeMembers[i]), newBalance);  
      } else {
        evm.expectRevert("LSS: Did not vote on report");
        lssGovernance.claimCommitteeReward(reportId);
      }
      evm.stopPrank();
    }
  }

  /// @notice Test Rewards distribution to Lossless Contracts whent everyone participates
  /// @dev Should not revert and transfer correctly
  function testLERC20WithFeesDistributionFull() public {
    uint256 participatingMembers = 3;
    uint256 participatingStakers = 3;
    uint256 expectedToRetrieve = reportedAmount - (reportedAmount * (committeeReward + stakersReward + reporterReward + losslessReward) / 1e2);

    uint256 reportId = generateReport(address(lerc20WithFees), maliciousActor, reporter);
    stakeOnReport(reportId, participatingStakers, 30 minutes);
    solveReport(reportId, participatingMembers, true, true, true);

    (,,uint256 fundsToRetrieve,,,,,,,,) = lssGovernance.proposedWalletOnReport(reportId);

    assertEq(fundsToRetrieve, expectedToRetrieve);
  }

  /// @notice Test Rewards distribution to Lossless Contracts whent nobody stakes
  /// @dev Should not revert and transfer correctly
  function testLERC20WithFeesDistributionNoStakes() public {
    uint256 participatingMembers = 3;
    uint256 expectedToRetrieve = reportedAmount - (reportedAmount * (reporterReward + committeeReward + losslessReward) / 1e2);

    uint256 reportId = generateReport(address(lerc20WithFees), maliciousActor, reporter);
    
    solveReport(reportId, participatingMembers, true, true, true);

    (,,uint256 fundsToRetrieve,,,,,,,,) = lssGovernance.proposedWalletOnReport(reportId);

    assertEq(fundsToRetrieve, expectedToRetrieve);
  }

  /// @notice Test Rewards distribution to Lossless Contracts whent nobody stakes and committee does not participate
  /// @dev Should not revert and transfer correctly
  function testLERC20WithFeesDistributionNoStakesNoCommittee() public {

    uint256 participatingMembers = 0;
    uint256 expectedToRetrieve = reportedAmount - (reportedAmount * (reporterReward + losslessReward) / 1e2);

    uint256 reportId = generateReport(address(lerc20WithFees), maliciousActor, reporter);
    
    solveReport(reportId, participatingMembers, true, true, true);

    (,,uint256 fundsToRetrieve,,,,,,,,) = lssGovernance.proposedWalletOnReport(reportId);

    assertEq(fundsToRetrieve, expectedToRetrieve);
  }
}