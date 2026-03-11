// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import {AccessControl} from "lib/openzeppelin-contracts/contracts/access/AccessControl.sol";

contract TimeLock is AccessControl{

uint256 public proposalReviewTimeLock = 24 hours;
uint256 public approveEndDuration = 12 hours;

 uint256 public executionTimelockDuration = 5 hours;

//  function getTimeLockDuration() external view returns(uint){
//     return timelockDuration;
//  }

constructor(){
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
}
 function setExecutionTimeLockDuration(uint _durationInHours) external onlyRole(DEFAULT_ADMIN_ROLE){
    require(_durationInHours >= 1, "Duration is too short");
    executionTimelockDuration = _durationInHours * 1 hours;
 }

 function setProposalReviewTimeLock(uint _durationInHours) external onlyRole(DEFAULT_ADMIN_ROLE){
    require(_durationInHours >= 1, "Duration is too short");
    proposalReviewTimeLock = _durationInHours * 1 hours;
 }

 function setApproveEndDuration(uint _durationInHours) external onlyRole(DEFAULT_ADMIN_ROLE){
    require(_durationInHours >= 1, "Duration is too short");
    approveEndDuration = _durationInHours * 1 hours;
 }

}