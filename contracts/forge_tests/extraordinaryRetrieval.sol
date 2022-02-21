// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./utils/LosslessEnv.t.sol";

contract ExtraordinaryFundsRetrieval is LosslessTestEnvironment {

    uint256 public constant toRetrieveExtraordinarily = toRetrieveExtraordinarily;

    /// @notice Test extraordinary funds retrieval for one address
    /// @dev should not revert
    function testExtraordinaryRetrievalSingle(address randReported, address randRetrieve) public {
        if (randReported != address(0) && randRetrieve != address(0) && (randReported != randRetrieve)) {
            
            address[] memory addressArray = new address[](1);
            addressArray[0] = randReported;

            generateTestAddress(addressArray[0], randRetrieve);

            evm.prank(randTokenAdmin);
            lssController.extaordinaryRetrievalProposal(addressArray, lerc20Token);

            evm.prank(address(this));
            lssController.acceptProposal(lerc20Token);

            for (uint i = 0; i < committeeMembers.length; i++) {
                evm.prank(committeeMembers[i]);
                lssController.acceptProposal(lerc20Token);
            }

            uint256 previousBal = lerc20Token.balanceOf(randTokenAdmin);

            evm.prank(randTokenAdmin);
            lssController.executeRetrievalProposal(lerc20Token);

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

            evm.prank(randTokenAdmin);
            lssController.extaordinaryRetrievalProposal(addressArray, lerc20Token);

            evm.prank(address(this));
            lssController.acceptProposal(lerc20Token);

            for (uint i = 0; i < committeeMembers.length; i++) {
                evm.prank(committeeMembers[i]);
                lssController.acceptProposal(lerc20Token);
            }

            uint256 previousBal = lerc20Token.balanceOf(randTokenAdmin);

            evm.prank(randTokenAdmin);
            lssController.executeRetrievalProposal(lerc20Token);

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
            lssController.extaordinaryRetrievalProposal(addressArray, lerc20Token);
        }
    }

    /// @notice Test extraordinary funds retrieval accepted by non committee member or lossess owner
    /// @dev should revert
    function testExtraordinaryRetrievalSingleNoRole(address randReported, address randRetrieve) public {
        if (randReported != address(0) && randRetrieve != address(0) && (randReported != randRetrieve)) {
            
            address[] memory addressArray = new address[](1);
            addressArray[0] = randReported;

            generateTestAddress(addressArray[0], randRetrieve);

            evm.prank(randTokenAdmin);
            lssController.extaordinaryRetrievalProposal(addressArray, lerc20Token);

            evm.prank(address(999));
            evm.expectRevert("LSS: Role cannot accept");
            lssController.acceptProposal(lerc20Token);
        }
    }

    /// @notice Test extraordinary funds retrieval for one address being executed by non admin
    /// @dev should revert
    function testExtraordinaryRetrievalSingleNonAdminExec(address randReported, address randRetrieve) public {
        if (randReported != address(0) && randRetrieve != address(0) && (randReported != randRetrieve)) {
            
            address[] memory addressArray = new address[](1);
            addressArray[0] = randReported;

            generateTestAddress(addressArray[0], randRetrieve);

            evm.prank(randTokenAdmin);
            lssController.extaordinaryRetrievalProposal(addressArray, lerc20Token);

            evm.prank(address(this));
            lssController.acceptProposal(lerc20Token);

            for (uint i = 0; i < committeeMembers.length; i++) {
                evm.prank(committeeMembers[i]);
                lssController.acceptProposal(lerc20Token);
            }

            evm.prank(address(999));
            evm.expectRevert("LSS: Must be Token Admin");
            lssController.executeRetrievalProposal(lerc20Token);
        }
    }

    /// @notice Test extraordinary funds retrieval trying to generate more than one
    /// @dev should revert
    function testExtraordinaryRetrievalSingleMultipleProposals(address randReported, address randRetrieve) public {
        if (randReported != address(0) && randRetrieve != address(0) && (randReported != randRetrieve)) {
            
            address[] memory addressArray = new address[](1);
            addressArray[0] = randReported;

            generateTestAddress(addressArray[0], randRetrieve);

            evm.prank(randTokenAdmin);
            lssController.extaordinaryRetrievalProposal(addressArray, lerc20Token);

            evm.prank(randTokenAdmin);
            evm.expectRevert("LSS: Proposal already Active");
            lssController.extaordinaryRetrievalProposal(addressArray, lerc20Token);
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
            lssController.extaordinaryRetrievalProposal(addressArray, lerc20Token);
        }
    }

    /// @notice Test extraordinary funds retrieval execute no active proposal
    /// @dev should revert
    function testExtraordinaryRetrievalNoProposal() public {
            evm.prank(randTokenAdmin);
            evm.expectRevert("LSS: No proposal Active");
            lssController.executeRetrievalProposal(lerc20Token);
    }

    /// @notice Test extraordinary funds retrieval execute non accepted proposal
    /// @dev should revert
    function testExtraordinaryRetrievalNonAcceptedProposal(address randReported, address randRetrieve) public {
        if (randReported != address(0) && randRetrieve != address(0) && (randReported != randRetrieve)) {
            
            address[] memory addressArray = new address[](1);
            addressArray[0] = randReported;

            generateTestAddress(addressArray[0], randRetrieve);

            evm.prank(randTokenAdmin);
            lssController.extaordinaryRetrievalProposal(addressArray, lerc20Token);

            evm.prank(randTokenAdmin);
            evm.expectRevert("LSS: Proposal not accepted");
            lssController.executeRetrievalProposal(lerc20Token);
        }
    }

    /// @notice Test extraordinary funds retrieval execute proposal twice
    /// @dev should revert
    function testExtraordinaryRetrievalExecutedMoreThanOnce(address randReported, address randRetrieve) public {
        if (randReported != address(0) && randRetrieve != address(0) && (randReported != randRetrieve)) {
            
            address[] memory addressArray = new address[](1);
            addressArray[0] = randReported;

            generateTestAddress(addressArray[0], randRetrieve);

            evm.prank(randTokenAdmin);
            lssController.extaordinaryRetrievalProposal(addressArray, lerc20Token);

            evm.prank(address(this));
            lssController.acceptProposal(lerc20Token);

            for (uint i = 0; i < committeeMembers.length; i++) {
                evm.prank(committeeMembers[i]);
                lssController.acceptProposal(lerc20Token);
            }

            uint256 previousBal = lerc20Token.balanceOf(randTokenAdmin);

            evm.prank(randTokenAdmin);
            lssController.executeRetrievalProposal(lerc20Token);

            assertEq(previousBal + toRetrieveExtraordinarily, lerc20Token.balanceOf(randTokenAdmin));

            evm.prank(randTokenAdmin);
            evm.expectRevert("LSS: No proposal Active");
            lssController.executeRetrievalProposal(lerc20Token);
        }
    }

    /// @notice Test extraordinary funds retrieval vote on non exiting proposal
    /// @dev should revert
    function testExtraordinaryRetrievalVoteOnNoProposal() public {
            evm.prank(address(this));
            evm.expectRevert("LSS: No proposal Active");
            lssController.acceptProposal(lerc20Token);

            for (uint i = 0; i < committeeMembers.length; i++) {
                evm.prank(committeeMembers[i]);
                evm.expectRevert("LSS: No proposal Active");
                lssController.acceptProposal(lerc20Token);
            }
    }

    /// @notice Test extraordinary funds retrieval voting twice
    /// @dev should revert
    function testExtraordinaryRetrievalRepeatVote(address randReported, address randRetrieve) public {
        if (randReported != address(0) && randRetrieve != address(0) && (randReported != randRetrieve)) {
            
            address[] memory addressArray = new address[](1);
            addressArray[0] = randReported;

            generateTestAddress(addressArray[0], randRetrieve);

            evm.prank(randTokenAdmin);
            lssController.extaordinaryRetrievalProposal(addressArray, lerc20Token);

            evm.prank(address(this));
            lssController.acceptProposal(lerc20Token);

            evm.prank(address(this));
            evm.expectRevert("LSS: Already Voted");
            lssController.acceptProposal(lerc20Token);

            for (uint i = 0; i < committeeMembers.length; i++) {
                evm.prank(committeeMembers[i]);
                lssController.acceptProposal(lerc20Token);
            }

            for (uint i = 0; i < committeeMembers.length; i++) {
                evm.prank(committeeMembers[i]);
                evm.expectRevert("LSS: Already Voted");
                lssController.acceptProposal(lerc20Token);
            }

            uint256 previousBal = lerc20Token.balanceOf(randTokenAdmin);

            evm.prank(randTokenAdmin);
            lssController.executeRetrievalProposal(lerc20Token);

            assertEq(previousBal + toRetrieveExtraordinarily, lerc20Token.balanceOf(randTokenAdmin));
        }
    }

    /// @notice Test extraordinary funds retrieval vote on expired report
    /// @dev should revert
    function testExtraordinaryRetrievalExpiredProposal(address randReported, address randRetrieve) public {
        if (randReported != address(0) && randRetrieve != address(0) && (randReported != randRetrieve)) {
            
            address[] memory addressArray = new address[](1);
            addressArray[0] = randReported;

            generateTestAddress(addressArray[0], randRetrieve);

            evm.prank(randTokenAdmin);
            lssController.extaordinaryRetrievalProposal(addressArray, lerc20Token);

            evm.warp(block.timestamp + walletDispute + toRetrieveExtraordinarily);

            evm.prank(address(this));
            evm.expectRevert("LSS: No proposal Active");
            lssController.acceptProposal(lerc20Token);

            for (uint i = 0; i < committeeMembers.length; i++) {
                evm.prank(committeeMembers[i]);
                evm.expectRevert("LSS: No proposal Active");
                lssController.acceptProposal(lerc20Token);
            }
        }
    }

    /// @notice Test two extraordinary funds retrieval
    /// @dev should not revert
    function testExtraordinaryRetrievalSingleTwice(address randReported, address randRetrieve) public {
        if (randReported != address(0) && randRetrieve != address(0) && (randReported != randRetrieve)) {
            
            address[] memory addressArray = new address[](1);
            addressArray[0] = randReported;

            generateTestAddress(addressArray[0], randRetrieve);

            evm.prank(randTokenAdmin);
            lssController.extaordinaryRetrievalProposal(addressArray, lerc20Token);

            evm.prank(address(this));
            lssController.acceptProposal(lerc20Token);

            for (uint i = 0; i < committeeMembers.length; i++) {
                evm.prank(committeeMembers[i]);
                lssController.acceptProposal(lerc20Token);
            }

            uint256 previousBal = lerc20Token.balanceOf(randTokenAdmin);

            evm.prank(randTokenAdmin);
            lssController.executeRetrievalProposal(lerc20Token);

            assertEq(previousBal + toRetrieveExtraordinarily, lerc20Token.balanceOf(randTokenAdmin));

            generateTestAddress(addressArray[0], randRetrieve);

            evm.prank(randTokenAdmin);
            lssController.extaordinaryRetrievalProposal(addressArray, lerc20Token);

            evm.prank(address(this));
            lssController.acceptProposal(lerc20Token);

            for (uint i = 0; i < committeeMembers.length; i++) {
                evm.prank(committeeMembers[i]);
                lssController.acceptProposal(lerc20Token);
            }

            previousBal = lerc20Token.balanceOf(randTokenAdmin);

            evm.prank(randTokenAdmin);
            lssController.executeRetrievalProposal(lerc20Token);

            assertEq(previousBal + toRetrieveExtraordinarily, lerc20Token.balanceOf(randTokenAdmin));
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