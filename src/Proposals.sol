// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {AccessControl} from "lib/openzeppelin-contracts/contracts/access/AccessControl.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";
import {IARESTreasury} from "../src/interfaces/IARESTreasury.sol";
import {ISignatureVerification} from "../src/interfaces/ISignatureVerification.sol";
import {TimeLock} from "../src/Timelock.sol";
import {ReentrancyGuard} from "lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

contract Proposals is AccessControl, ReentrancyGuard{

    bytes32 public constant SIGNERS_ROLE = keccak256("SIGNERS_ROLE");

    IERC20 public erc20;
    IARESTreasury public aresTreasury;
    TimeLock public timelock;
    ISignatureVerification public signatureVerification;
    uint proposalId;

    uint refundableProposalCreateFee;
    mapping(address => mapping(uint => uint)) proposerFeeBalances;
    mapping(uint => address) proposalAddress;
    mapping(uint => bytes32) public proposalsHash;

    struct Proposal{
        string name;
        address erc20Address;
        uint amount;
        address recipient;
        uint signatureConfirmations;
        uint submissionTime;
        uint approveStartTime;
        uint approveEndTime;
        uint executionTime;
        bool isExecuted;
        bool isCancelled;
        uint cancellationTime;
    }

    mapping(uint => Proposal) public proposals;
    mapping(address => mapping(uint => bool)) hasVoted;

    uint256 public threshold;

    event ProposalCreated(uint proposalId, address proposer);
    event ProposalApproved(uint proposalId, uint confirmations);
    event ProposalCancelled(uint proposalId, address indexed canceller);
    event ProposalExecuted(uint indexed proposalId, address indexed executor);

    constructor(address _aresAddr, address _timelockAddr, address _sigVerificationAddr, address[] memory _signers, uint _threshold, uint _propFee){
        aresTreasury = IARESTreasury(_aresAddr);
        timelock = TimeLock(_timelockAddr);
        signatureVerification = ISignatureVerification(_sigVerificationAddr);

        require(_threshold <= _signers.length, "threshold too high");
        require(_threshold > 0, "threshold cannot be zero");

         require(_signers.length > 0, "no owners");
         _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        for (uint i = 0; i < _signers.length; i++) {
            address o = _signers[i];
            require(o != address(0));
            _grantRole(SIGNERS_ROLE, o);
        }
        threshold = _threshold;
        refundableProposalCreateFee = _propFee;
    }

    function setRefundableProposalFee(uint _propFee) external onlyRole(SIGNERS_ROLE) {
        refundableProposalCreateFee = _propFee;
    }

    function createProposal(string memory _name, address _erc20Address, uint _amount, address _recipient) external payable{
        proposalId = proposalId + 1;
        require(aresTreasury.checkIsContributor(msg.sender), "Not a valid contributor");
        require(msg.value == refundableProposalCreateFee, "Invalid fee set in msg.value");
        proposals[proposalId] = Proposal({
            name: _name,
            erc20Address: _erc20Address,
            amount: _amount,
            recipient: _recipient,
            signatureConfirmations: 0,
            submissionTime: block.timestamp,
            approveStartTime: block.timestamp + timelock.proposalReviewTimeLock(),
            approveEndTime: block.timestamp + timelock.proposalReviewTimeLock() + timelock.approveEndDuration(),
            executionTime: 0,
            isExecuted: false,
            isCancelled: false,
            cancellationTime: block.timestamp
        });

        bytes32 proposalHash = signatureVerification.hashProposal(
        proposalId,
        _name,
        _erc20Address,
        _amount,
        _recipient
        );

        proposalsHash[proposalId] = proposalHash;

        proposerFeeBalances[msg.sender][proposalId] = msg.value;
        proposalAddress[proposalId] = msg.sender;
        emit ProposalCreated(proposalId, msg.sender);
    }

    function approveProposal(uint _proposalId , bytes[] calldata signatures) external nonReentrant{
        Proposal storage targetProp = proposals[_proposalId];
        require(block.timestamp >= targetProp.approveStartTime, "Approve time has not started");
        require(block.timestamp < targetProp.approveEndTime, "Approve time has ended");

        require(signatures.length > 0, "No signatures");
        require(signatures.length <= threshold, "Too many signatures");
        

        bytes32 proposalHash = proposalsHash[_proposalId];

        for(uint i = 0; i< signatures.length; i++){
            address signer = signatureVerification.recoverAddressFromSignatureAndMessage(proposalHash, signatures[i]);
            require(signer != address(0), "Invalid signature");
            require(hasRole(SIGNERS_ROLE, signer), "Invalid signer");
            require(!hasVoted[signer][_proposalId], "Signer already approved proposal");
            hasVoted[signer][_proposalId] = true;
            targetProp.signatureConfirmations += 1;
        }

        if(targetProp.signatureConfirmations >= threshold && targetProp.executionTime == 0){
            targetProp.executionTime = block.timestamp + timelock.executionTimelockDuration();
        }
        emit ProposalApproved(_proposalId, targetProp.signatureConfirmations);
    }

    function executeProposal(uint _proposalId) external  onlyRole(SIGNERS_ROLE) nonReentrant{
        Proposal storage targetProp = proposals[_proposalId];
        require(targetProp.signatureConfirmations >= threshold);
        require(!targetProp.isCancelled, "proposal was cancelled");
        require(!targetProp.isExecuted, "proposal already executed");
        require(block.timestamp >= targetProp.executionTime);
        targetProp.isExecuted = true;
        aresTreasury.transferOutOfTreasury(targetProp.erc20Address, targetProp.recipient, targetProp.amount);
        emit ProposalExecuted(_proposalId, msg.sender);
    }

    function refundProposerFee(uint _proposalId) external onlyRole(SIGNERS_ROLE) nonReentrant{
            Proposal storage targetProp = proposals[_proposalId];
            if(targetProp.cancellationTime >= targetProp.approveStartTime){
            (bool success, ) = payable(proposalAddress[_proposalId]).call{value: proposerFeeBalances[proposalAddress[_proposalId]][_proposalId]}("");
            require(success, "transfer failed");
        }
    }

    function cancelProposal(uint _proposalId) external {
        Proposal storage targetProp = proposals[_proposalId];
        require(targetProp.submissionTime != 0, "Proposal does not exist");
        require(hasRole(SIGNERS_ROLE, msg.sender) || msg.sender == proposalAddress[_proposalId], "Address not permitted to call this function");
        require(!targetProp.isCancelled, "proposal already cancelled");
        require(!targetProp.isExecuted, "proposal already executed");
        targetProp.isCancelled = true;
        targetProp.cancellationTime = block.timestamp;

        emit ProposalCancelled(_proposalId, msg.sender);
    }
}