// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {AccessControl} from "lib/openzeppelin-contracts/contracts/access/AccessControl.sol";

contract TimeLock is AccessControl{

bytes32 public constant DAO_ROLE = keccak256("DAO_ROLE");

uint256 public proposalReviewTimeLock = 24 hours;
uint256 public approveEndDuration = 12 hours;

 uint256 public executionTimelockDuration = 5 hours;

//  function getTimeLockDuration() external view returns(uint){
//     return timelockDuration;
//  }

 function setexecutionTimeLockDuration(uint _duration) external onlyRole(DAO_ROLE){
    executionTimelockDuration = _duration;
 }

 function setProposalReviewTimeLock(uint _duration) external onlyRole(DAO_ROLE){
    proposalReviewTimeLock = _duration;
 }

 function setApproveEndDuration(uint _duration) external onlyRole(DAO_ROLE){
    approveEndDuration = _duration;
 }


}