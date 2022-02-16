// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./utils/LosslessEnv.t.sol";

contract ExtraordinaryFundsRetrieval is LosslessTestEnvironment {

    /// @notice Test extraordinary funds retrieval for one address
    function testExtraordinaryRetrievalSingle(address randReported, address randRetrieve) public {
        if (randReported != address(0) && randRetrieve != address(0)) {
            generateTestAddress(randReported, randRetrieve);
            
            address[] memory addressArray = new address[](1);
            addressArray[0] = randReported;

            evm.prank(randTokenAdmin);
            lssController.extaordinaryRetrievalProposal(addressArray, lerc20Token);

            evm.prank(address(this));
            lssController.acceptProposal(lerc20Token);

            for (uint i = 0; i < committeeMembers.length; i++) {
                evm.prank(committeeMembers[i]);
                lssController.acceptProposal(lerc20Token);
            }

            evm.prank(randTokenAdmin);
            lssController.executeRetrievalProposal(lerc20Token);
        }
    }

    /// @notice Generate a blacklisted address which funds were retrieved and then recieved more funds. 
    function generateTestAddress(address reportedAddress, address retrievalAddress) public {
        uint256 reportId = generateReport(address(lerc20Token), reportedAddress, reporter);
        solveReportPositively(reportId);
        retrieveFundsForReport(reportId, false, retrievalAddress);
        evm.prank(address(this));
        lerc20Token.transfer(reportedAddress, 100);
        assertEq(lerc20Token.balanceOf(reportedAddress), 100);
    }
}