// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./utils/LosslessEnv.t.sol";

contract EnvironmentTests is LosslessTestEnvironment {

    /// @notice Test deployed Controller variables
    function testControllerDeploy() public {
      assertEq(lssController.getVersion() , 4);
      assertEq(lssController.admin(), address(this));
      assertEq(lssController.pauseAdmin(), address(this));
      assertEq(lssController.recoveryAdmin(), address(this));
    }

    /// @notice Test deployed Reporting Config
    function testReportingDeploy() public {
      assertEq(lssReporting.getVersion() , 2);
      assertEq(lssReporting.reportLifetime(), reportLifetime);
      assertEq(lssReporting.reportingAmount(), reportingAmount);
      assertEq(address(lssReporting.losslessController()), address(lssController));
      assertEq(address(lssReporting.stakingToken()), address(lssToken));
      assertEq(address(lssReporting.losslessGovernance()), address(lssGovernance));

      (uint256 configReporterReward, uint256 configLosslessReward, uint256 configCommitteeReward, uint256 configStakerReward) = lssReporting.getRewards();

      assertEq(configReporterReward, reporterReward);
      assertEq(configLosslessReward, losslessReward);
      assertEq(configCommitteeReward, committeeReward);
      assertEq(configStakerReward, stakersReward);
    }

    /// @notice Test deployed Staking Contract
    function testStakingDeploy() public {
      assertEq(lssStaking.getVersion() , 2);
      assertEq(lssStaking.stakingAmount(), stakingAmount);
      assertEq(address(lssStaking.stakingToken()), address(lssToken));
      assertEq(address(lssStaking.losslessReporting()), address(lssReporting));
      assertEq(address(lssStaking.losslessGovernance()), address(lssGovernance));
      assertEq(address(lssStaking.losslessController()), address(lssController));
    }

    /// @notice Test deployed Governance Contract
    function testGovernanceDeploy() public {
      assertEq(lssGovernance.getVersion() , 2);
      assertEq(lssGovernance.walletDisputePeriod(), walletDispute);
      assertEq(address(lssGovernance.losslessStaking()), address(lssStaking));
      assertEq(address(lssGovernance.losslessReporting()), address(lssReporting));
      assertEq(address(lssGovernance.losslessController()), address(lssController));

      for (uint8 i = 0; i < committeeMembers.length; i++) {
        assertTrue(lssGovernance.isCommitteeMember(committeeMembers[i]));
      }
    }

    /// @notice Test deployed LssToken
    function testLssTokenDeploy() public {
      assertEq(lssToken.totalSupply(), totalSupply);
      assertEq(lssToken.name(), "Lossless Token");
      assertEq(lssToken.admin(), address(this));
      assertEq(lssToken.recoveryAdmin(), address(this));
      assertEq(lssToken.timelockPeriod(), 1 days);
    }

    /// @notice Test deployed Random LERC20 Token
    function testLERC20TokenDeploy() public {
      assertEq(lerc20Token.totalSupply(), totalSupply);
      assertEq(lerc20Token.name(), "Random LERC20 Token");
      assertEq(lerc20Token.admin(), randTokenAdmin);
      assertEq(lerc20Token.recoveryAdmin(), randTokenAdmin);
      assertEq(lerc20Token.timelockPeriod(), 1 days);
    }
}