// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "../utils/first-version/LosslessControllerV1.sol";
import "../LosslessControllerV4.sol";
import "../utils/mocks/LERC20MintableMock.sol";
import "ds-test/test.sol";

contract LERC20MitableTests is DSTest {
    LosslessControllerV1 lssControllerV1;
    LosslessControllerV4 lssControllerV4;
    TransparentUpgradeableProxy transparentProxy;
    ProxyAdmin proxyAdmin;

    LERC20MintableMock lerc20Mintable;

    LosslessControllerV4 lssController;

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

    function testControllerDeploy() public {
      address admin = lssController.admin(); 
      uint version = lssController.getVersion();
      assertEq(version , 4);
      assertEq(admin, address(this));
    }

    function testLERC20Deploy() public {
      assertEq(lerc20Mintable.name(), "LERC20 Mintable");
    }
}