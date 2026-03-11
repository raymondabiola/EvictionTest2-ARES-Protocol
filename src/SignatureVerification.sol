// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";

contract SignatureVerification{

    function hashProposal(address _propContractAddr, uint _proposalsId, string memory _name, address _erc20Address, uint _amount, address _recipient) external view returns(bytes32){
      return  keccak256(abi.encode(_propContractAddr, block.chainid, _proposalsId, _name, _erc20Address, _amount, _recipient));
    }

    function recoverAddressFromSignatureAndMessage(
        bytes32 messageHash,
        bytes memory signature
    ) external pure returns (address) {
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(messageHash);
        return ECDSA.recover(ethSignedMessageHash, signature);
    }
}