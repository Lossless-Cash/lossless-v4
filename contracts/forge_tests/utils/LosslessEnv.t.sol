// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import "../../utils/first-version/LosslessControllerV1.sol";
import "../../utils/first-version/LERC20.sol";

import "../../utils/hack-mitigation-protocol/LosslessGovernance.sol";
import "../../utils/hack-mitigation-protocol/LosslessReporting.sol";
import "../../utils/hack-mitigation-protocol/LosslessStaking.sol";

import "../../utils/mocks/LERC20BurnableMock.sol";
import "../../utils/mocks/LERC20MintableMock.sol";
import "../../LosslessControllerV4.sol";

import "./IEvm.sol";
import "ds-test/test.sol";

contract LosslessTestEnvironment is DSTest {
    LosslessControllerV1 private lssControllerV1;
    LosslessControllerV4 private lssControllerV4;

    LosslessReporting public lssReporting;
    LosslessGovernance public lssGovernance;
    LosslessStaking public lssStaking;

    TransparentUpgradeableProxy private transparentProxy;
    ProxyAdmin private proxyAdmin;

    LosslessControllerV4 public lssController;

    LERC20BurnableMock public lerc20Burnable;
    LERC20MintableMock public lerc20Mintable;
    LERC20 public lssToken;
    LERC20 public lerc20Token;

    Evm public evm = Evm(HEVM_ADDRESS);

    address public dex = address(99);

    address[] public whitelist = [address(this), dex];
    address[] public dexList = [dex]; 
    address[] public committeeMembers = [address(100), address(101), address(102), address(103), address(104)];
    address public randTokenAdmin = address(105);

    address public reporter = address(200);
    address[] public stakers = [address(201), address(202), address(203), address(204), address(205)];
    address maliciousActor = address(999);

    uint256 public totalSupply = 100000000000000000000;
    uint256 public mintAndBurnLimit = 99999999;
    uint256 public settlementPeriod = 10 minutes;
    uint256 public extraordinaryPeriod = 10 minutes;

    uint256 public mintPeriod = 10 minutes;
    uint256 public burnPeriod = 10 minutes;

    uint256 public stakingAmount = 1000;
    uint256 public reportingAmount = 1000;

    uint256 public reportLifetime = 1 days;

    uint256 public reporterReward  = 2;
    uint256 public stakersReward   = 2;
    uint256 public committeeReward = 2;
    uint256 public losslessReward = 10;

    uint256 public walletDispute = 7 days;

    uint256 public dexTransferTreshold = 200;
    uint256 public settlementTimelock = 1 minutes;

    uint256 public reportedAmount = 100000;

    function setUp() public {

      lssControllerV1 = new LosslessControllerV1();

      lssControllerV4 = new LosslessControllerV4();

      transparentProxy = new TransparentUpgradeableProxy(address(lssControllerV1), address(this), "");

      proxyAdmin = new ProxyAdmin();
      
      transparentProxy.changeAdmin(address(proxyAdmin));

      LosslessControllerV1(address(transparentProxy)).initialize(
        address(this), 
        address(this), 
        address(this));

      proxyAdmin.upgrade(transparentProxy, address(lssControllerV4));

      lssController = LosslessControllerV4(address(transparentProxy));
      lssReporting = new LosslessReporting();
      lssStaking = new LosslessStaking();
      lssGovernance = new LosslessGovernance();

      // Set up tokens

      lssToken = new LERC20(
        totalSupply,
        "Lossless Token",
        "LSS",
        address(this),
        address(this),
        1 days,
        address(lssController)
      );
      
      lerc20Token = new LERC20(
        totalSupply,
        "Random LERC20 Token",
        "LERC",
        randTokenAdmin,
        randTokenAdmin,
        1 days,
        address(lssController)
      );

      lerc20Burnable = new LERC20BurnableMock(
        totalSupply,
        "LERC20 Burnable",
        "lBURN",
        address(this),
        address(this),
        1 days,
        address(lssController)
      );

      lerc20Mintable = new LERC20MintableMock(
        totalSupply,
        "LERC20 Mintable",
        "lMINT",
        address(this),
        address(this),
        1 days,
        address(lssController)
      );

      // Set up Reporting
      setUpReporting();

      // Set up Staking
      setUpStaking();

      // Set up Governance
      setUpGovernance();

      // Set up Controller
      setUpController();
    }

    /// ----- Helpers ------

    /// @notice Sets up Lossless Reporting
    function setUpReporting() public {
      lssReporting.initialize(lssController);
      lssReporting.setReportLifetime(reportLifetime);
      lssReporting.setReportingAmount(reportingAmount);
      lssReporting.setStakingToken(lssToken);
      lssReporting.setLosslessGovernance(lssGovernance);
      lssReporting.setReporterReward(reporterReward);
      lssReporting.setStakersReward(stakersReward);
      lssReporting.setCommitteeReward(committeeReward);
      lssReporting.setLosslessReward(losslessReward);
    }

    /// @notice Sets up Lossless Staking
    function setUpStaking() public {
      lssStaking.initialize(lssReporting, lssController, stakingAmount);
      lssStaking.setStakingToken(lssToken);
      lssStaking.setLosslessGovernance(lssGovernance);
    }

    /// @notice Sets up Lossless Governance
    function setUpGovernance() public {
      lssGovernance.initialize(lssReporting, lssController, lssStaking, walletDispute);
      lssGovernance.addCommitteeMembers(committeeMembers);
    }

    /// @notice Sets up Lossless Controller
    function setUpController() public {
      lssController.setTokenMintPeriod(lerc20Mintable, mintPeriod);
      lssController.setTokenMintLimit(lerc20Mintable, mintAndBurnLimit);
      lssController.proposeNewSettlementPeriod(lerc20Mintable, settlementPeriod);

      lssController.setTokenBurnPeriod(lerc20Burnable, burnPeriod);
      lssController.setTokenBurnLimit(lerc20Burnable, mintAndBurnLimit);
      lssController.proposeNewSettlementPeriod(lerc20Burnable, settlementPeriod);

      lssController.executeNewSettlementPeriod(lerc20Mintable);
      lssController.executeNewSettlementPeriod(lerc20Burnable);

      lssController.proposeNewSettlementPeriod(lssToken, settlementPeriod);
      lssController.executeNewSettlementPeriod(lssToken);

      lssController.setStakingContractAddress(lssStaking);
      lssController.setReportingContractAddress(lssReporting);
      lssController.setGovernanceContractAddress(lssGovernance);

      lssController.setWhitelist(whitelist, true);
      lssController.setDexList(dexList, true);

      lssController.setDexTransferThreshold(dexTransferTreshold);
      lssController.setSettlementTimeLock(settlementTimelock);

      lssController.setExtraordinaryRetrievalPeriod(extraordinaryPeriod);
    }

    /// @notice Generate a report
    function generateReport(address reportedToken, address reportedAdr, address reporter) public returns (uint256) {
      lssToken.transfer(reporter, reportingAmount);
      lerc20Token.transfer(reportedAdr, reportedAmount);
      evm.warp(block.timestamp + settlementPeriod + 1);
      evm.startPrank(reporter);
      lssToken.approve(address(lssReporting), reportingAmount);
      uint256 reportId = lssReporting.report(ILERC20(reportedToken), reportedAdr);
      evm.stopPrank();
      return reportId;
    }

    /// @notice Solve Report Positively
    function solveReportPositively(uint256 reportId) public {
      evm.prank(address(this));
      lssGovernance.losslessVote(reportId, true);
      
      for (uint8 i = 0; i < committeeMembers.length; i++) {
        evm.prank(committeeMembers[i]);
        lssGovernance.committeeMemberVote(reportId, true);
      }

      (,,,, ILERC20 reportedToken,,) = lssReporting.getReportInfo(reportId);
      evm.prank(reportedToken.admin());
      lssGovernance.tokenOwnersVote(reportId, true);

      lssGovernance.resolveReport(reportId);
    }
    
    /// @notice Solve Report Negatively
    function solveReportNegatively(uint256 reportId) public {
      evm.prank(address(this));
      lssGovernance.losslessVote(reportId, false);
      
      for (uint8 i = 0; i < committeeMembers.length; i++) {
        evm.prank(committeeMembers[i]);
        lssGovernance.committeeMemberVote(reportId, false);
      }

      (,,,, ILERC20 reportedToken,,) = lssReporting.getReportInfo(reportId);
      evm.prank(reportedToken.admin());
      lssGovernance.tokenOwnersVote(reportId, false);

      lssGovernance.resolveReport(reportId);
    }

    /// @notice Modular Report solving
    function solveReport(uint256 reportId, uint256 amountOfMembers, bool memberVote, bool losslessVote, bool adminVote) public {
      require(amountOfMembers <= committeeMembers.length, "TEST: Not enough members");

      evm.prank(address(this));
      lssGovernance.losslessVote(reportId, losslessVote);
      
      for (uint8 i = 0; i < amountOfMembers; i++) {
        evm.prank(committeeMembers[i]);
        lssGovernance.committeeMemberVote(reportId, memberVote);
      }

      (,,,, ILERC20 reportedToken,,) = lssReporting.getReportInfo(reportId);
      evm.prank(reportedToken.admin());
      lssGovernance.tokenOwnersVote(reportId, adminVote);

      lssGovernance.resolveReport(reportId);
    }

    /// @notice Stake on a report
    function stakeOnReport(uint256 reportId, uint256 amountOfStakers, uint256 skipTime) public {
      require(amountOfStakers <= stakers.length, "TEST: Not enough stakers");
      
      for (uint8 i = 0; i < amountOfStakers; i++) {
        evm.prank(address(this));
        lssToken.transfer(stakers[i], stakingAmount);
        evm.startPrank(stakers[i]);
        lssToken.approve(address(lssStaking), stakingAmount);
        evm.warp(settlementPeriod + 1);
        lssStaking.stake(reportId);
        evm.warp(skipTime);
        evm.stopPrank();
      }
    }

    /// @notice Proposes wallet and retrieves funds
    function retrieveFundsForReport(uint256 reportId, bool dispute, address retrieveTo) public {
      evm.prank(address(this));
      lssGovernance.proposeWallet(reportId, retrieveTo);

      if (dispute) {
        for (uint i = 0; i < committeeMembers.length; i++) {
          evm.prank(committeeMembers[i]);
          lssGovernance.rejectWallet(reportId);
        }

        evm.prank(randTokenAdmin);
        lssGovernance.rejectWallet(reportId);

        evm.prank(address(this));
        lssGovernance.rejectWallet(reportId);
      }

      evm.warp(block.timestamp + walletDispute + 1 hours);
      evm.prank(retrieveTo);
      lssGovernance.retrieveFunds(reportId);
    }
}