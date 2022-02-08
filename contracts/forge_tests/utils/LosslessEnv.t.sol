// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import "../../utils/first-version/LosslessControllerV1.sol";
import "../../LosslessControllerV4.sol";

import "../../utils/mocks/LERC20BurnableMock.sol";
import "../../utils/mocks/LERC20MintableMock.sol";

import "./ICheatcodes.sol";
import "ds-test/test.sol";

contract LosslessTestEnvironment is DSTest {
    LosslessControllerV1 private lssControllerV1;
    LosslessControllerV4 private lssControllerV4;
    TransparentUpgradeableProxy private transparentProxy;
    ProxyAdmin private proxyAdmin;

    LosslessControllerV4 public lssController;

    LERC20BurnableMock public lerc20Burnable;
    LERC20MintableMock public lerc20Mintable;

    CheatCodes public cheats = CheatCodes(HEVM_ADDRESS);

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

      lerc20Burnable = new LERC20BurnableMock(
        100000000000000000000,
        "LERC20 Burnable",
        "lBURN",
        address(this),
        address(this),
        1 days,
        address(lssController)
      );

      lerc20Mintable = new LERC20MintableMock(
        100000000000,
        "LERC20 Mintable",
        "lMINT",
        address(this),
        address(this),
        1 days,
        address(lssController)
      );
    }

    /// @notice Test deployed controller variables
    function testControllerDeploy() public {
      assertEq(lssController.getVersion() , 4);
      assertEq(lssController.admin(), address(this));
      assertEq(lssController.pauseAdmin(), address(this));
      assertEq(lssController.recoveryAdmin(), address(this));
    }
}