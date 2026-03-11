# ARES DAO Treasury System

The ARES Protocol Treasury System basically sets up a way to handle contributor funds with smart contracts that are modular. It uses the multi-signature governance process and has a time lock for security. This makes it harder for anyone to just steal treasury funds quickly.

Contributors can put money into the treasury, then they submit proposals for spending. Approvals come from off-chain signatures by people who are authorized. Transfers only happen after a timelock period that is set by an authorized person.

There's also this Merkle-based claim smart contract for handing out tokens or airdrops to who qualifies. 

The whole architecture aims at being secure and transparent, with decentralized governance. Some parts might overlap in how they ensure that.

---

# System Architecture

The project consists of five main smart contracts:

## 1. AresTreasury.sol

The treasury contract responsible for holding ERC20 tokens.

**Features:**

- Accepts ERC20 token contributions from users
- Tracks contributor addresses and deposits
- Restricts outgoing transfers via the proposal governance contract
- Prevents reentrancy attacks

NOTE: Only the **Proposals contract** is allowed to move funds from the treasury.

---

## 2. Proposals.sol

The governance core of the system.

**Responsibilities:**

- Allows treasury contributors to submit proposals
- Requires a refundable proposal creation fee
- Verifies approvals using off-chain signatures
- Enforces multi-signature threshold approval
- Enforces time-locked execution
- Executes approved proposals through the treasury contract

This contract ensures treasury funds can only move through an approved governance process.

---

## 3. SignatureVerification.sol

A helper contract responsible for verifying signatures.

**It:**

- Hashes proposal data
- Recovers signer addresses using ECDSA library.
- Ensures signatures belong to authorized DAO signers

This enables gas-efficient off-chain voting.

---

## 4. TimeLock.sol

Manages governance timing parameters.

**Configurable delays include:**

- Proposal review delay
- Proposal approval window
- Execution timelock delay

These delays prevent rushed or malicious proposal execution.

---

## 5. Claim.sol

Handles token distribution through Merkle proofs.

**Features:**

- Users claim tokens allocated to them in a Merkle tree
- Prevents double claims
- Allows admin to update Merkle roots when needed

This contract is suitable for:

- Airdrops
- Contributor rewards
- Community incentive programs

---

# Governance Flow

1. Contributors fund the treasury.
2. A contributor creates a proposal describing a token transfer.
3. A review timelock period begins.
4. Authorized signers approve the proposal by providing signatures when review timelock has ended.
5. When the approval threshold is reached, an execution timelock begins.
6. After the approval window expires and the signatures collected is enough for the threshold, a signer can execute the proposal.
7. The treasury transfers tokens to the recipient when the executeProposal function is called.

---

# Key Security Features

- Role-based access control using OpenZeppelin AccessControl
- Reentrancy protection for token transfers
- Off-chain ECDSA signature verification
- Threshold multi-signature governance
- Configurable timelock protections
- Merkle-proof based claim validation
- One-time claim protection

---

# Technologies Used

- Solidity ^0.8.x
- OpenZeppelin Contracts
- Merkle Trees
- ECDSA Signature Verification
- AccessControl Role Management

---

# Future Improvements

Potential enhancements include:

- SafeERC20 integration
- Emergency pause mechanism
- Multi-signature admin control asides the proposal contract
- Gas optimizations for proposal approvals
- UI improvement for proposal creation and claim proofs

---

# License

MIT