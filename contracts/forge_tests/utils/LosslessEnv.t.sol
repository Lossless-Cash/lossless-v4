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

    Evm public evm = Evm(HEVM_ADDRESS);

    address public dex = address(99);

    address[] whitelist = [address(this), dex];
    address[] dexList = [dex]; 

    uint256 public totalSupply = 100000000000000000000;
    uint256 public mintAndBurnLimit = 99999999;
    uint256 public settlementPeriod = 600;

    uint256 public stakingAmount = 1000;
    uint256 public reportingAmount = 1000;

    uint256 public reportLifetime = 1 days;

    uint256 public reporterReward  = 2;
    uint256 public stakersReward   = 2;
    uint256 public committeeReward = 2;
    uint256 public losslessReward = 10;

    uint256 public walletDispute = 7 days;

    uint256 public dexTransferTreshold = 200;
    uint256 public settlementTimelock = 60;

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

    /// @notice Test deployed Controller variables
    function testControllerDeploy() public {
      assertEq(lssController.getVersion() , 4);
      assertEq(lssController.admin(), address(this));
      assertEq(lssController.pauseAdmin(), address(this));
      assertEq(lssController.recoveryAdmin(), address(this));
    }

    /// @notice Test deployed Reporting Config
    function testReportingDeploy() public {
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
      assertEq(lssStaking.stakingAmount(), stakingAmount);
      assertEq(address(lssStaking.stakingToken()), address(lssToken));
      assertEq(address(lssStaking.losslessReporting()), address(lssReporting));
      assertEq(address(lssStaking.losslessGovernance()), address(lssGovernance));
      assertEq(address(lssStaking.losslessController()), address(lssController));
    }

    /// @notice Test deployed Governance Contract
    function testGovernanceDeploy() public {
      assertEq(lssGovernance.walletDisputePeriod(), walletDispute);
      assertEq(address(lssGovernance.losslessStaking()), address(lssStaking));
      assertEq(address(lssGovernance.losslessReporting()), address(lssReporting));
      assertEq(address(lssGovernance.losslessController()), address(lssController));
    }

    /// @notice Test deployed LssToken
    function testLssTokenDeploy() public {
      assertEq(lssToken.totalSupply(), totalSupply);
      assertEq(lssToken.name(), "Lossless Token");
      assertEq(lssToken.admin(), address(this));
      assertEq(lssToken.recoveryAdmin(), address(this));
      assertEq(lssToken.timelockPeriod(), 1 days);
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
    }

    /// @notice Sets up Lossless Controller
    function setUpController() public {
      lssController.setTokenMintLimit(lerc20Mintable, mintAndBurnLimit);
      lssController.proposeNewSettlementPeriod(lerc20Mintable, settlementPeriod);

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
    }
}