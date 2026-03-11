// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {IARESTreasury} from "../src/interfaces/IARESTreasury.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";
import {ISignatureVerification} from "../src/interfaces/ISignatureVerification.sol";
import {AresTreasury} from "../src/ARESTreasury.sol";
import {Claim} from "../src/Claim.sol";
import {Proposals} from "../src/Proposals.sol";
import {SignatureVerification} from "../src/SignatureVerification.sol";
import {TimeLock} from "../src/Timelock.sol";

contract ARESProtocolTest is Test {
    AresTreasury public aresTreasury;
    Claim public claim;
    Proposals public proposals;
    SignatureVerification public signatureVerification;
    TimeLock public timelock;


    function setUp() public {
    }

    function testProposalLifeCycle() public {
    }


    function testSIgnatureVerification() public {
    }

    function testTimeLockExecution() public {

    }

    function testRewardClaiming()public {

    }

    // Exploit tests

    function testMaliciousContractReentrancy() public {

    }

    function testDoubleClaimAttempt() public {

    }

    function testInvalidSignature() public {

    }

    function testPrematureExecution() public {

    }

    function testProposalReplay() public {

    }

}
