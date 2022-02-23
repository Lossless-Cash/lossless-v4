// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./utils/LosslessEnv.t.sol";

contract ExtraordinaryFundsRetrieval is LosslessTestEnvironment {
    
    /// @notice Test retrieve compensation for contracts that got erroneously reported
    /// @dev should not revert
    function testRetrieveLERC20Compensation() public {
        
        uint256 reportId = generateReport(address(lerc20Token), address(lerc20Token), reporter);
        solveReportNegatively(reportId);
        
        uint256 balanceBefore = lssToken.balanceOf(randTokenAdmin);
        evm.prank(randTokenAdmin);
        lssGovernance.retrieveCompensationForLERC20Contract(address(lerc20Token));
        assertEq(balanceBefore + 100, lssToken.balanceOf(randTokenAdmin));
    }

    /// @notice Test retrieve compensation for contracts that got erroneously reported. 
    /// @dev should revert when claiming twice
    function testRetrieveLERC20CompensationRetrievingTwice() public {
        uint256 reportId = generateReport(address(lerc20Token), address(lerc20Token), reporter);
        solveReportNegatively(reportId);
        evm.startPrank(randTokenAdmin);
        lssGovernance.retrieveCompensationForLERC20Contract(address(lerc20Token));
        evm.expectRevert("LSS: Already retrieved");
        lssGovernance.retrieveCompensationForLERC20Contract(address(lerc20Token));
        evm.stopPrank();
    }

    /// @notice Test retrieve compensation for contracts that got erroneously reported. 
    /// @dev should revert when not token admin
    function testRetrieveLERC20CompensationNonTokenAdmin() public {
        uint256 reportId = generateReport(address(lerc20Token), address(lerc20Token), reporter);
        solveReportNegatively(reportId);
        evm.expectRevert("LSS: Must be token admin");
        lssGovernance.retrieveCompensationForLERC20Contract(address(lerc20Token));
    }

    /// @notice Test retrieve compensation for contracts that got erroneously reported. 
    /// @dev should revert when no retribution is assigned
    function testRetrieveLERC20CompensationNoRetributionAssigned() public {
        evm.prank(randTokenAdmin);
        evm.expectRevert("LSS: No retribution assigned");
        lssGovernance.retrieveCompensationForLERC20Contract(address(lerc20Token));
    }

        /// @notice Test retrieve compensation for contracts that got erroneously reported
    /// @dev should not revert
    function testRetrieveERC20CompensationX() public {
        
        uint256 reportId = generateReport(address(erc20Token), address(erc20Token), reporter);
        solveReportNegatively(reportId);
        
        uint256 balanceBefore = lssToken.balanceOf(address(this));
        evm.prank(address(this));
        lssGovernance.retrieveCompensationForRegularContract(address(erc20Token));
        assertEq(balanceBefore + 100, lssToken.balanceOf(address(this)));
    }

    /// @notice Test retrieve compensation for contracts that got erroneously reported. 
    /// @dev should revert when claiming twice
    function testRetrieveERC20CompensationRetrievingTwice() public {
        uint256 reportId = generateReport(address(erc20Token), address(erc20Token), reporter);
        solveReportNegatively(reportId);
        evm.startPrank(address(this));
        lssGovernance.retrieveCompensationForRegularContract(address(erc20Token));
        evm.expectRevert("LSS: Already retrieved");
        lssGovernance.retrieveCompensationForRegularContract(address(erc20Token));
        evm.stopPrank();
    }

    /// @notice Test retrieve compensation for contracts that got erroneously reported. 
    /// @dev should revert when not token admin
    function testRetrieveERC20CompensationNonTokenAdmin() public {
        uint256 reportId = generateReport(address(erc20Token), address(erc20Token), reporter);
        solveReportNegatively(reportId);
        evm.prank(maliciousActor);
        evm.expectRevert("LSS: Must be token owner");
        lssGovernance.retrieveCompensationForRegularContract(address(erc20Token));
    }

    /// @notice Test retrieve compensation for contracts that got erroneously reported. 
    /// @dev should revert when no retribution is assigned
    function testRetrieveERC20CompensationNoRetributionAssigned() public {
        evm.prank(address(this));
        evm.expectRevert("LSS: No retribution assigned");
        lssGovernance.retrieveCompensationForRegularContract(address(erc20Token));
    }
}