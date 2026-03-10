// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

contract SignatureVerification{

    function hashProposal(uint _proposalsId, string memory _name, address _erc20Address, uint _amount, address _recipient) external pure returns(bytes32){
      return  keccak256(abi.encode(_proposalsId, _name, _erc20Address, _amount, _recipient));
    }

    function recoverAddressFromSignatureAndMessage(
        bytes32 messageHash,
        bytes memory signature
    ) external pure returns (address) {
        return ECDSA.recover(messageHash, signature);
    }
}