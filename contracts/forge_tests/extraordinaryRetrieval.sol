// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./utils/LosslessEnv.t.sol";

contract ExtraordinaryFundsRetrieval is LosslessTestEnvironment {

    uint256 public constant toRetrieveExtraordinarily = 100;

    /// @notice Test extraordinary funds retrieval for one address
    /// @dev should not revert
    function testExtraordinaryRetrievalSingle(address randReported, address randRetrieve) public {
        if (randReported != address(0) && randRetrieve != address(0) && (randReported != randRetrieve)) {
            
            address[] memory addressArray = new address[](1);
            addressArray[0] = randReported;

            generateTestAddress(addressArray[0], randRetrieve);

            uint256 previousBal = lerc20Token.balanceOf(randTokenAdmin);

            evm.prank(randTokenAdmin);
            lssGovernance.extaordinaryRetrieval(addressArray, lerc20Token);

            assertEq(previousBal + toRetrieveExtraordinarily, lerc20Token.balanceOf(randTokenAdmin));
        }
    }

    /// @notice Test extraordinary funds retrieval for an array of addresses
    /// @dev should not revert
    function testExtraordinaryRetrievalMulti(address randRetrieve) public {
        if (randRetrieve != address(0)) {
            
            address[] memory addressArray = new address[](5);
            addressArray[0] = address(1);
            addressArray[1] = address(2);
            addressArray[2] = address(3);
            addressArray[3] = address(4);
            addressArray[4] = address(5);

            for (uint i = 0; i < addressArray.length; i++) {
                generateTestAddress(addressArray[i], randRetrieve);
            }
            
            uint256 previousBal = lerc20Token.balanceOf(randTokenAdmin);

            evm.prank(randTokenAdmin);
            lssGovernance.extaordinaryRetrieval(addressArray, lerc20Token);

            assertEq(previousBal + (toRetrieveExtraordinarily * addressArray.length), lerc20Token.balanceOf(randTokenAdmin));
        }
    }

    /// @notice Test extraordinary funds retrieval beign proposed by non token admin
    /// @dev should revert
    function testExtraordinaryRetrievalSingleNonAdmin(address randReported, address randRetrieve) public {
        if (randReported != address(0) && randRetrieve != address(0) && (randReported != randRetrieve)) {
            
            address[] memory addressArray = new address[](1);
            addressArray[0] = randReported;

            generateTestAddress(addressArray[0], randRetrieve);

            evm.prank(address(500));
            evm.expectRevert("LSS: Must be Token Admin");
            lssGovernance.extaordinaryRetrieval(addressArray, lerc20Token);
        }
    }

    /// @notice Test extraordinary funds retrieval with an address not in blacklist
    /// @dev should revert
    function testExtraordinaryRetrievalNonBlacklistedAddress(address randReported, address randRetrieve) public {
        if (randReported != address(0) && randRetrieve != address(0) && (randReported != randRetrieve)) {
            
            address[] memory addressArray = new address[](2);
            addressArray[0] = randReported;
            addressArray[1] = address(999);

            generateTestAddress(addressArray[0], randRetrieve);

            evm.prank(randTokenAdmin);
            evm.expectRevert("LSS: An address not in blacklist");
            lssGovernance.extaordinaryRetrieval(addressArray, lerc20Token);
        }
    }

    /// @notice Generate a blacklisted address which funds were retrieved and then recieved more funds. 
    function generateTestAddress(address reportedAddress, address retrievalAddress) public {
        uint256 reportId = generateReport(address(lerc20Token), reportedAddress, reporter);
        solveReportPositively(reportId);
        retrieveFundsForReport(reportId, false, retrievalAddress);
        evm.prank(address(this));
        lerc20Token.transfer(reportedAddress, toRetrieveExtraordinarily);
    }
}