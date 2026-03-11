# Architecture
- The ARES system compromises of modular contract that are inter-operable and specific in concern.

## Contracts Modules
- ARESTreasury.sol
- Claim.sol
- Proposals.sol
- SignatureVerification.sol
- Timelock.sol
- TokenClaim.sol

## Interfaces
The protocol uses interfaces from contracts to define an interaction blue print with other contracts. Interfaces in this project include;
- IARESTreasury.sol
- IERC20.sol
- ISignatureVerification.sol

## ARESTreasury
- This contract is the core treasury contracts where contributors can fund the contract and get validated as contributors. It implements the following functions: fundTreasury, transferOutOfTreasury, checkIsContributor
- The transferOutOfTreasury function is callable from only an address with the role PROPOSAL_CONTRACT_ROLE.

## Claim
- This contract can be used by contributors to claim rewards.
- Contributors are verified using merkle proof.
- setMerkleRoot function is callable by only ADMIN_ROLE.

## Proposals
- The proposals contract allows any contributor to create a proposal as long as they can risk paying a Governance grief fee (refundableProposalCreateFee). If their proposal gets cancelled before approvalTimeStart, they lose the fee paid. This checks that proposals submitted are not spams and are well thought of.
- the following functions are covered in this contract: setRefundableProposalFee, createProposal, approveProposal, executeProposal, cancelProposal
- only verified signers signatures can be be used to approve proposals, and only a verified signer can either execute or cancel a proposal.
- refunds of proposal fee is possible when proposals are cancelled at/after approval time begins. This means the proposal was well discussed and was ready for signers to begin voting, however there could be a possibility that there are not enough signatures, hence the proposal was not executed. 

## Signature Verification
- This contract contains two functions: hashProposal, recoverAddressFromSignatureAndMessage.
- hashProposal generates a proposal hash using several parameters such as, address of proposal contract, chainId to ensure that the message was generated on that chain, proposalId, name, erc20Address, amount, recipient.
- recoverAddressFromSignatureAndMessage recovers the signer address from their signature and the messageHash using libraries from OpenZeppelin; ECDSA, MessageHashUtils.sol.

## Timelock
- This contract handles timelock durations for several contexts such as proposalReviewTimeLock, approveEndDuration, executionTimelockDuration.
- Timelocks for several contracts can be set by only the deployer of the contract.
- Checks are implemented such that, timelocks set are not lower than a threshold minimum.

## Inter-Contract Dependencies
- The ARESTreasury contracts must set the proposal contract address in the constructor
- Due to circular dependency nature of contracts, when deploying the proposal contract, use a place holder of address(0) in the _aresAddr argument in the constructor and after deployment, call the function setAERSContractAddr in deployment script to set the actual address of the ARESTreasury.
- Proposal contract uses the Signature Verification contract to recover address from signatures collected from signers.
- Proposal contract also depends on the timelock contract to correctly set timelocks for all possile contexts.

## Security Boundaries
- Signature replay protection is checked in approval function using the check hasSigned boolean mapping and the reentrancyGuard modifier from openzeppelin.
- There is a timelock before execution to prevent flash-attacks
- Reentrancy protection from openzeppelin is used to sheild against reentrancy attacks;
- Role based is implemented across contracts for functions that are sensitive to who is calling it for example:
 transferOutOfTreasury IN ARESTREASURY is protected by the role PROPOSAL_CONTRACT_ROLE, executeProposal, refundProposalFee in proposals contract is protected by SIGNERS_ROLE. Also setExecutionTimeLockDuration, setProposalReviewTimeLock, setApproveEndDuration in the timelock contract are protected by the DEFAULT_ADMIN_ROLE.
 - several checks were observed across all contracts especially for function input parameters to prevent spamming and wrong inputs. For example:
 checks like; check if amount > 0, address is not a zero address, mapping boolean cross-contract checks, timelock checks against block.timestamp.

## Trust Assumptions
The following assumptions are observed in the project
- It is assumed that addresses with the DEFAULT_ADMIN_ROLE in all contracts where they were granted such role do not go rogue.
