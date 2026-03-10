// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ISignatureVerification{
    function hashProposal(uint _proposalsId, string memory _name, address _erc20Address, uint _amount, address _recipient) external pure returns(bytes32);
    function recoverAddressFromSignatureAndMessage(
        bytes32 messageHash,
        bytes memory signature
    ) external pure returns (address);
}