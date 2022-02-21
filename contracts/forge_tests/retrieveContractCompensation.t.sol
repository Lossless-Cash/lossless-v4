// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./utils/LosslessEnv.t.sol";

contract ExtraordinaryFundsRetrieval is LosslessTestEnvironment {
    
    /// @notice Test retrieve compensation for contracts that got erroneously reported
    /// @dev should not revert
    function testRetrieveCompensation() public {
        
        uint256 reportId = generateReport(address(lerc20Token), address(lerc20Token), reporter);
        solveReportNegatively(reportId);
        
        uint256 balanceBefore = lssToken.balanceOf(randTokenAdmin);
        evm.prank(randTokenAdmin);
        lssGovernance.retrieveCompensationForContract(address(lerc20Token));
        assertEq(balanceBefore + 100, lssToken.balanceOf(randTokenAdmin));
    }

    /// @notice Test retrieve compensation for contracts that got erroneously reported. 
    /// @dev should revert when claiming twice
    function testRetrieveCompensationRetrievingTwice() public {
        uint256 reportId = generateReport(address(lerc20Token), address(lerc20Token), reporter);
        solveReportNegatively(reportId);
        evm.startPrank(randTokenAdmin);
        lssGovernance.retrieveCompensationForContract(address(lerc20Token));
        evm.expectRevert("LSS: Already retrieved");
        lssGovernance.retrieveCompensationForContract(address(lerc20Token));
        evm.stopPrank();
    }

    /// @notice Test retrieve compensation for contracts that got erroneously reported. 
    /// @dev should revert when not token admin
    function testRetrieveCompensationNonTokenAdmin() public {
        uint256 reportId = generateReport(address(lerc20Token), address(lerc20Token), reporter);
        solveReportNegatively(reportId);
        evm.expectRevert("LSS: Must be token admin");
        lssGovernance.retrieveCompensationForContract(address(lerc20Token));
    }

    /// @notice Test retrieve compensation for contracts that got erroneously reported. 
    /// @dev should revert when no retribution is assigned
    function testRetrieveCompensationNoRetributionAssigned() public {
        evm.prank(randTokenAdmin);
        evm.expectRevert("LSS: No retribution assigned");
        lssGovernance.retrieveCompensationForContract(address(lerc20Token));
    }
}