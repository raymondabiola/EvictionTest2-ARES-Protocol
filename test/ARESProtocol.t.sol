// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {IARESTreasury} from "../src/interfaces/IARESTreasury.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";
import {ISignatureVerification} from "../src/interfaces/ISignatureVerification.sol";
import {AresTreasury} from "../src/ARESTreasury.sol";
import {Claim} from "../src/Claim.sol";
import {Proposals} from "../src/Proposals.sol";
import {SignatureVerification} from "../src/SignatureVerification.sol";
import {TimeLock} from "../src/Timelock.sol";

contract ARESProtocolTest is Test {
    uint amount1 = 100 ether;
    uint amount2 = 50 ether;
    uint amount3 = 75 ether;
    uint amount4 = 80 ether;

    address DAIAddress = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address  DAIHolder = 0x79AC3536c4B21C10ecb5298cdfDe93E7Be3cE954;
    string public rpcUrl = "https://mainnet.infura.io/v3/36cc63546c6846aebf5c9c74e61cf84d";
    uint public amount = 1_000_000e18;

    AresTreasury public aresTreasury;
    Claim public claim;
    Proposals public proposals;
    SignatureVerification public signatureVerification;
    TimeLock public timelock;

    address public signer1;
    address public signer2;
    address public signer3;
    address public signer4;
    address public zeroAddress;
    address[] public signers;

    uint256 pKey1 = 0x450802246;
    uint256 pKey2 = 0xF333BB;
    uint256 pKey3 = 0xDEAD;
    uint256 pKey4 = 0xF39A;

    error ECDSAInvalidSignature();

    function setUp() public {
        vm.createSelectFork(rpcUrl);
        vm.startPrank(DAIHolder);

        signer1 = vm.addr(pKey1);
        zeroAddress = address(0);
        signer2 = vm.addr(pKey2);
        signer3 = vm.addr(pKey3);
        signer4 = vm.addr(pKey4);

        signers.push(signer1);
        signers.push(signer2);
        signers.push(signer3);
        signers.push(signer4);

        bytes32 leaf1 = keccak256(abi.encodePacked(signer1, amount1));
        bytes32 leaf2 = keccak256(abi.encodePacked(signer2, amount2));
        bytes32 leaf3 = keccak256(abi.encodePacked(signer3, amount3));
        bytes32 leaf4 = keccak256(abi.encodePacked(signer4, amount4));

        bytes32 hash12 = keccak256(
            abi.encodePacked(
                leaf1 < leaf2 ? leaf1 : leaf2,
                leaf1 < leaf2 ? leaf2 : leaf1
            )
        );

        bytes32 hash34 = keccak256(
            abi.encodePacked(
                leaf3 < leaf4 ? leaf3 : leaf4,
                leaf3 < leaf4 ? leaf4 : leaf3
            )
        );

        bytes32 root = keccak256(
            abi.encodePacked(
                hash12 < hash34 ? hash12 : hash34,
                hash12 < hash34 ? hash34 : hash12
            )
        );
        console2.logBytes32(root);

        timelock = new TimeLock();
        signatureVerification = new SignatureVerification();
        claim = new Claim(DAIAddress, root ,DAIHolder);
        proposals = new Proposals(zeroAddress, address(timelock), address(signatureVerification), signers, 3, 1 ether);
        aresTreasury = new AresTreasury(address(proposals));
        proposals.setAERSContractAddr(address(aresTreasury));
        vm.stopPrank();
    }

    function testProposalLifeCycle() public {

    // Fund treasury

    vm.startPrank(DAIHolder);

    IERC20(DAIAddress).approve(address(aresTreasury), 50 ether);

    aresTreasury.fundTreasury(
        "Raymond",
        50 ether,
        DAIAddress
    );

    proposals.createProposal{value: 1 ether}(
        "Transfer funds",
        DAIAddress,
        10 ether,
        signer4
    );

    vm.stopPrank();

    vm.warp(block.timestamp + timelock.proposalReviewTimeLock() + 1);

    // create signatures here

    bytes32 messageHash = signatureVerification.hashProposal(
        address(proposals),
        1,
        "Transfer funds",
        DAIAddress,
        10 ether,
        signer4
    );

    bytes32 ethSignedHash = keccak256(
    abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
    );

    (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(pKey1, ethSignedHash);
    (uint8 v2, bytes32 r2, bytes32 s2) = vm.sign(pKey2, ethSignedHash);
    (uint8 v3, bytes32 r3, bytes32 s3) = vm.sign(pKey3, ethSignedHash);

    bytes memory sig1 = abi.encodePacked(r1, s1, v1);
    bytes memory sig2 = abi.encodePacked(r2, s2, v2);
    bytes memory sig3 = abi.encodePacked(r3, s3, v3);

    bytes[] memory signatures = new bytes[](3);
    signatures[0] = sig1;
    signatures[1] = sig2;
    signatures[2] = sig3;

    // Approve proposal

    proposals.approveProposal(1, signatures);

    // Wait execution time lock

    vm.warp(block.timestamp + timelock.executionTimelockDuration() + 1);

    // execute the proposal

    vm.prank(signer1);

    proposals.executeProposal(1);

    uint recipientBalance = IERC20(DAIAddress).balanceOf(signer4);

    assertEq(recipientBalance, 10 ether);
    }


    function testSignatureVerification() public {

    // Create a proposal hash
    bytes32 messageHash = signatureVerification.hashProposal(
        address(proposals),
        1,
        "Transfer funds",
        DAIAddress,
        10 ether,
        signer4
    );

    bytes32 ethSignedHash = keccak256(
    abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
    );

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(pKey1, ethSignedHash);

    bytes memory signature = abi.encodePacked(r, s, v);

    address recovered = signatureVerification
        .recoverAddressFromSignatureAndMessage(messageHash, signature);

    assertEq(recovered, signer1);
    }

   function testTimeLockExecution() public {

    vm.startPrank(DAIHolder);

    IERC20(DAIAddress).approve(address(aresTreasury), 50 ether);

    aresTreasury.fundTreasury(
        "Raymond",
        50 ether,
        DAIAddress
    );

    proposals.createProposal{value: 1 ether}(
        "Transfer funds",
        DAIAddress,
        10 ether,
        signer4
    );
    vm.stopPrank();

    vm.warp(block.timestamp + timelock.proposalReviewTimeLock() + 1);

    bytes32 messageHash = signatureVerification.hashProposal(
        address(proposals),
        1,
        "Transfer funds",
        DAIAddress,
        10 ether,
        signer4
    );

     bytes32 ethSignedHash = keccak256(
    abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
    );

    (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(pKey1, ethSignedHash);
    (uint8 v2, bytes32 r2, bytes32 s2) = vm.sign(pKey2, ethSignedHash);
    (uint8 v3, bytes32 r3, bytes32 s3) = vm.sign(pKey3, ethSignedHash);

    bytes memory sig1 = abi.encodePacked(r1, s1, v1);
    bytes memory sig2 = abi.encodePacked(r2, s2, v2);
    bytes memory sig3 = abi.encodePacked(r3, s3, v3);

    bytes[] memory signatures = new bytes[](3);

    signatures[0] = sig1;
    signatures[1] = sig2;
    signatures[2] = sig3;

    proposals.approveProposal(1, signatures);

    // Should fail because timelock is not reached

    vm.expectRevert();

    proposals.executeProposal(1);

   
    vm.warp(block.timestamp + timelock.executionTimelockDuration() + 1);

    vm.prank(signer1);
    proposals.executeProposal(1);

    uint recipientBalance = IERC20(DAIAddress).balanceOf(signer4);

    assertEq(recipientBalance, 10 ether);
}

   function testRewardClaiming() public {

    vm.startPrank(DAIHolder);
    IERC20(DAIAddress).transfer(address(claim), 400 ether);
    vm.stopPrank();

    bytes32 leaf1 = keccak256(abi.encodePacked(signer1, amount1)); 
    bytes32 leaf2 = keccak256(abi.encodePacked(signer2, amount2)); 
    bytes32 leaf3 = keccak256(abi.encodePacked(signer3, amount3)); 
    bytes32 leaf4 = keccak256(abi.encodePacked(signer4, amount4));

    bytes32 hash12 = keccak256(abi.encodePacked(
        leaf1 < leaf2 ? leaf1 : leaf2,
        leaf1 < leaf2 ? leaf2 : leaf1
    ));

    bytes32 hash34 = keccak256(abi.encodePacked(
        leaf3 < leaf4 ? leaf3 : leaf4,
        leaf3 < leaf4 ? leaf4 : leaf3
    ));

    bytes32[] memory proof1 = new bytes32[](2);
    proof1[0] = leaf2;
    proof1[1] = hash34;

    vm.prank(signer1);
    claim.claim(amount1, proof1);

    assertEq(IERC20(DAIAddress).balanceOf(signer1), amount1);

    bytes32[] memory proof2 = new bytes32[](2);
    proof2[0] = leaf1;
    proof2[1] = hash34;

    vm.prank(signer2);
    claim.claim(amount2, proof2);

    assertEq(IERC20(DAIAddress).balanceOf(signer2), amount2);

    bytes32[] memory proof3 = new bytes32[](2);
    proof3[0] = leaf4;
    proof3[1] = hash12;

    vm.prank(signer3);
    claim.claim(amount3, proof3);

    assertEq(IERC20(DAIAddress).balanceOf(signer3), amount3);

    // Double claim revert
    vm.prank(signer1);
    vm.expectRevert("Already claimed");
    claim.claim(amount1, proof1);

    // Invalid proof revert
    bytes32[] memory badProof = new bytes32[](2);
    badProof[0] = bytes32(0);
    badProof[1] = bytes32(0);

    vm.prank(signer4);
    vm.expectRevert("Invalid proof");
    claim.claim(amount4, badProof);
}

function testInvalidSignatureWhenWrongMessageIsSigned() public {

    vm.startPrank(DAIHolder);
    IERC20(DAIAddress).approve(address(aresTreasury), 50 ether);
    aresTreasury.fundTreasury("Raymond", 50 ether, DAIAddress);

    proposals.createProposal{value: 1 ether}(
        "Transfer funds",
        DAIAddress,
        10 ether,
        signer4
    );
    vm.stopPrank();

    vm.warp(block.timestamp + timelock.proposalReviewTimeLock() + 1);
    // case1 test when wrong message was signed

    bytes32 tamperedHash = keccak256(abi.encodePacked("wrong message"));
    (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(pKey1, tamperedHash);
    bytes memory tamperedSig = abi.encodePacked(r1, s1, v1);

    bytes[] memory tamperedSigs = new bytes[](1);
    tamperedSigs[0] = tamperedSig;

    vm.expectRevert("Invalid signer");
    proposals.approveProposal(1, tamperedSigs);
}

function testInvalidSignatureWhenWrongSignerSigns() public{

        vm.startPrank(DAIHolder);
    IERC20(DAIAddress).approve(address(aresTreasury), 50 ether);
    aresTreasury.fundTreasury("Raymond", 50 ether, DAIAddress);

    proposals.createProposal{value: 1 ether}(
        "Transfer funds",
        DAIAddress,
        10 ether,
        signer4
    );
    vm.stopPrank();

    vm.warp(block.timestamp + timelock.proposalReviewTimeLock() + 1);

    bytes32 messageHash = signatureVerification.hashProposal(
        address(proposals),
        1,
        "Transfer funds",
        DAIAddress,
        10 ether,
        signer4
    );

    bytes32 ethSignedHash = keccak256(
        abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
    );
    // valid hash message but wrong signer testing

    uint256 nonSignerKey = 0xABCD1234;
    (uint8 v2, bytes32 r2, bytes32 s2) = vm.sign(nonSignerKey, ethSignedHash);
    bytes memory nonSignerSig = abi.encodePacked(r2, s2, v2);

    bytes[] memory nonSignerSigs = new bytes[](1);
    nonSignerSigs[0] = nonSignerSig;

    vm.expectRevert("Invalid signer");
    proposals.approveProposal(1, nonSignerSigs);
}
    
    function testInvalidSignatureWhenSignerSignsTwice() public {

        vm.startPrank(DAIHolder);
    IERC20(DAIAddress).approve(address(aresTreasury), 50 ether);
    aresTreasury.fundTreasury("Raymond", 50 ether, DAIAddress);

    proposals.createProposal{value: 1 ether}(
        "Transfer funds",
        DAIAddress,
        10 ether,
        signer4
    );
    vm.stopPrank();

    vm.warp(block.timestamp + timelock.proposalReviewTimeLock() + 1);

    bytes32 messageHash = signatureVerification.hashProposal(
        address(proposals),
        1,
        "Transfer funds",
        DAIAddress,
        10 ether,
        signer4
    );

    bytes32 ethSignedHash = keccak256(
        abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
    );
    // same signer but using a valid signature twice should fail

    (uint8 v3, bytes32 r3, bytes32 s3) = vm.sign(pKey1, ethSignedHash);
    bytes memory validSig1 = abi.encodePacked(r3, s3, v3);

    bytes[] memory duplicateSigs = new bytes[](2);
    duplicateSigs[0] = validSig1;
    duplicateSigs[1] = validSig1; // submits same sig twice

    vm.expectRevert("Signer already approved proposal");
    proposals.approveProposal(1, duplicateSigs);
    }

    function testInvalidSignatureWhenSignedWithEmptyBytes() public {
        vm.startPrank(DAIHolder);
    IERC20(DAIAddress).approve(address(aresTreasury), 50 ether);
    aresTreasury.fundTreasury("Raymond", 50 ether, DAIAddress);

    proposals.createProposal{value: 1 ether}(
        "Transfer funds",
        DAIAddress,
        10 ether,
        signer4
    );
    vm.stopPrank();

    vm.warp(block.timestamp + timelock.proposalReviewTimeLock() + 1);

    //  signing with empty bytes signature

    bytes[] memory emptySigs = new bytes[](1);
    emptySigs[0] = new bytes(65); 

    vm.expectRevert(ECDSAInvalidSignature.selector);
    proposals.approveProposal(1, emptySigs);
}
}
