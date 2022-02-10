// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./utils/LosslessEnv.t.sol";

contract ContractsRewardsDistributionTests is LosslessTestEnvironment {

  /// @notice Test Committee members claiming their rewards when all participating
  /// @dev Should not revert and update balances correctly
  ///      reported amount * committee rewards / all members
  function testMembersClaimAllParticipating() public {
    uint256[5] memory memberBalances;

    for (uint i = 0; i < committeeMembers.length; i++) {
      memberBalances[i] = lerc20Token.balanceOf(committeeMembers[i]);
    }

    uint256 reportId = generateReport(address(lerc20Token), maliciousActor, reporter);
    solveReportPositively(reportId);

    for (uint i = 0; i < committeeMembers.length; i++) {
      evm.prank(committeeMembers[i]);
      lssGovernance.claimCommitteeReward(reportId);
      uint256 newBalance =  memberBalances[i] + ((reportedAmount * committeeReward) / 1e2) / committeeMembers.length;
      assertEq(lerc20Token.balanceOf(committeeMembers[i]), newBalance);  
    }
  }

  /// @notice Test Committee members claiming their rewards when some participating
  /// @dev Should not revert and update balances correctly
  ///      reported amount * committee rewards / all members
  function testMembersClaimSomeParticipating() public {
    uint totalMembers = committeeMembers.length;
    uint256[5] memory memberBalances;
    uint256 participatingMembers = 3;

    for (uint i = 0; i < totalMembers; i++) {
      memberBalances[i] = lerc20Token.balanceOf(committeeMembers[i]);
    }

    uint256 reportId = generateReport(address(lerc20Token), maliciousActor, reporter);
    solveReport(reportId, participatingMembers, true, true, true);

    for (uint i = 0; i < totalMembers; i++) {
      evm.startPrank(committeeMembers[i]);
      if (i < participatingMembers) {
        lssGovernance.claimCommitteeReward(reportId);
        uint256 newBalance =  memberBalances[i] + ((reportedAmount * committeeReward) / 1e2) / participatingMembers;
        assertEq(lerc20Token.balanceOf(committeeMembers[i]), newBalance);  
      } else {
        evm.expectRevert("LSS: Did not vote on report");
        lssGovernance.claimCommitteeReward(reportId);
      }
      evm.stopPrank();
    }
  }

  /// @notice Test Rewards distribution to Lossless Contracts whent everyone participates
  /// @dev Should not revert and transfer correctly
  function testRewardDistributionFull() public {
    uint256 participatingMembers = 3;
    uint256 participatingStakers = 3;
    uint256 expectedToRetrieve = reportedAmount - (reportedAmount * (committeeReward + stakersReward + reporterReward + losslessReward) / 1e2);

    uint256 reportId = generateReport(address(lerc20Token), maliciousActor, reporter);
    stakeOnReport(reportId, participatingStakers, 30 minutes);
    solveReport(reportId, participatingMembers, true, true, true);

    (,,uint256 fundsToRetrieve,,,,,,,,) = lssGovernance.proposedWalletOnReport(reportId);

    assertEq(fundsToRetrieve, expectedToRetrieve);
  }

  /// @notice Test Rewards distribution to Lossless Contracts whent nobody stakes
  /// @dev Should not revert and transfer correctly
  function testRewardDistributionNoStakes() public {
    uint256 participatingMembers = 3;
    uint256 expectedToRetrieve = reportedAmount - (reportedAmount * (reporterReward + committeeReward + losslessReward) / 1e2);

    uint256 reportId = generateReport(address(lerc20Token), maliciousActor, reporter);
    
    solveReport(reportId, participatingMembers, true, true, true);

    (,,uint256 fundsToRetrieve,,,,,,,,) = lssGovernance.proposedWalletOnReport(reportId);

    assertEq(fundsToRetrieve, expectedToRetrieve);
  }

  /// @notice Test Rewards distribution to Lossless Contracts whent nobody stakes and committee does not participate
  /// @dev Should not revert and transfer correctly
  function testRewardDistributionNoStakesNoCommittee() public {
    uint256 participatingMembers = 0;
    uint256 expectedToRetrieve = reportedAmount - (reportedAmount * (reporterReward + losslessReward) / 1e2);

    uint256 reportId = generateReport(address(lerc20Token), maliciousActor, reporter);
    
    solveReport(reportId, participatingMembers, true, true, true);

    (,,uint256 fundsToRetrieve,,,,,,,,) = lssGovernance.proposedWalletOnReport(reportId);

    assertEq(fundsToRetrieve, expectedToRetrieve);
  }
}
