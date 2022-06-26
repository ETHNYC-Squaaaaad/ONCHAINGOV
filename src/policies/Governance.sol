// SPDX-License-Identifier: AGPL-3.0-only

// The Proposal Policy submits & activates instructions in a INSTR module

pragma solidity ^0.8.13;

import {Instructions} from "src/modules/INSTR.sol";
import {Token} from "src/modules/TOKEN.sol";
import {Kernel, Policy, Actions, Instruction} from "src/Kernel.sol";

// proposing
error NotEnoughVotesToPropose();

// endorsing
error CannotEndorseNullProposal();
error CannotEndorseInvalidProposal();

// activating
error NotAuthorizedToActivateProposal();
error NotEnoughEndorsementsToActivateProposal();
error ProposalAlreadyActivated();
error ActiveProposalNotExpired();
error SubmittedProposalHasExpired();

// voting
error NoActiveProposalDetected();
error UserAlreadyVoted();

// executing
error NotEnoughVotesToExecute();
error ExecutionTimelockStillActive();

// claiming
error VotingTokensAlreadyClaimed();
error CannotReclaimTokensForActiveVote();

struct ProposalMetadata {
    bytes32 proposalName;
    address proposer;
    uint256 submissionTimestamp;
}

struct ActivatedProposal {
    uint256 instructionsId;
    uint256 activationTimestamp;
}

contract Governance is Policy {
    /////////////////////////////////////////////////////////////////////////////////
    //                         Kernel Policy Configuration                         //
    /////////////////////////////////////////////////////////////////////////////////

    Instructions public INSTR;
    Token public TOKEN;

    constructor(Kernel kernel_) Policy(kernel_) {}

    function configureReads() external override {
        INSTR = Instructions(getModuleAddress("INSTR"));
        TOKEN = Token(getModuleAddress("TOKEN"));
    }

    function requestRoles()
        external
        view
        override
        onlyKernel
        returns (Kernel.Role[] memory roles)
    {
        roles = new Kernel.Role[](1);
        roles[0] = INSTR.GOVERNOR();
    }

    /////////////////////////////////////////////////////////////////////////////////
    //                             Policy Variables                                //
    /////////////////////////////////////////////////////////////////////////////////

    event ProposalSubmitted(uint256 instructionsId);
    event ProposalEndorsed(
        uint256 instructionsId,
        address voter,
        uint256 amount
    );
    event ProposalActivated(uint256 instructionsId, uint256 timestamp);
    event WalletVoted(
        uint256 instructionsId,
        address voter,
        bool for_,
        uint256 userVotes
    );
    event ProposalExecuted(uint256 instructionsId);

    // Reward for vote participation. 4 decimals.
    uint256 public rewardRate;

    // currently active proposal
    ActivatedProposal public activeProposal;

    mapping(uint256 => ProposalMetadata) public getProposalMetadata;

    mapping(uint256 => uint256) public totalEndorsementsForProposal;
    mapping(uint256 => mapping(address => uint256))
        public userEndorsementsForProposal;
    mapping(uint256 => bool) public proposalHasBeenActivated;

    mapping(uint256 => uint256) public yesVotesForProposal;
    mapping(uint256 => uint256) public noVotesForProposal;
    mapping(uint256 => mapping(address => uint256)) public userVotesForProposal;

    mapping(uint256 => mapping(address => bool)) public tokenClaimsForProposal;

    /////////////////////////////////////////////////////////////////////////////////
    //                               User Actions                                  //
    /////////////////////////////////////////////////////////////////////////////////

    function getMetadata(uint256 instructionsId_)
        public
        view
        returns (ProposalMetadata memory)
    {
        return getProposalMetadata[instructionsId_];
    }

    function getActiveProposal()
        public
        view
        returns (ActivatedProposal memory)
    {
        return activeProposal;
    }

    function submitProposal(
        Instruction[] calldata instructions_,
        bytes32 proposalName_
    ) external returns (uint256) {
        // require the proposing wallet to own at least 1% of the outstanding governance power
        if (TOKEN.balanceOf(msg.sender) * 100 < TOKEN.totalSupply()) {
            revert NotEnoughVotesToPropose();
        }

        // store the proposed instructions in the INSTR module and save the proposal metadata to the proposal mapping
        uint256 instructionsId = INSTR.store(instructions_);
        getProposalMetadata[instructionsId] = ProposalMetadata(
            proposalName_,
            msg.sender,
            block.timestamp
        );

        // emit the corresponding event
        emit ProposalSubmitted(instructionsId);
        return instructionsId;
    }

    function endorseProposal(uint256 instructionsId_) external {
        // get the current votes of the user
        uint256 userVotes = TOKEN.balanceOf(msg.sender);

        // revert if endorsing null instructionsId
        if (instructionsId_ == 0) {
            revert CannotEndorseNullProposal();
        }

        // revert if endorsed instructions are empty
        Instruction[] memory instructions = INSTR.getInstructions(
            instructionsId_
        );
        if (instructions.length == 0) {
            revert CannotEndorseInvalidProposal();
        }

        // undo any previous endorsement the user made on these instructions
        uint256 previousEndorsement = userEndorsementsForProposal[
            instructionsId_
        ][msg.sender];
        totalEndorsementsForProposal[instructionsId_] -= previousEndorsement;

        // reapply user endorsements with most up-to-date votes
        userEndorsementsForProposal[instructionsId_][msg.sender] = userVotes;
        totalEndorsementsForProposal[instructionsId_] += userVotes;

        // emit the corresponding event
        emit ProposalEndorsed(instructionsId_, msg.sender, userVotes);
    }

    function activateProposal(uint256 instructionsId_) external {
        // require endorsements from at least 20% of the total outstanding governance power
        if (
            (totalEndorsementsForProposal[instructionsId_] * 5) <
            TOKEN.totalSupply()
        ) {
            revert NotEnoughEndorsementsToActivateProposal();
        }

        // ensure the proposal is being activated for the first time
        if (proposalHasBeenActivated[instructionsId_] == true) {
            revert ProposalAlreadyActivated();
        }

        // ensure the current active proposal has had at least a week of voting
        if (block.timestamp < activeProposal.activationTimestamp + 1 weeks) {
            revert ActiveProposalNotExpired();
        }

        // activate the proposal
        activeProposal = ActivatedProposal(instructionsId_, block.timestamp);

        // record that the proposal has been activated
        proposalHasBeenActivated[instructionsId_] = true;

        // emit the corresponding event
        emit ProposalActivated(instructionsId_, block.timestamp);
    }

    function vote(bool for_) external {
        // get the amount of user votes
        uint256 userVotes = TOKEN.balanceOf(msg.sender);

        // ensure an active proposal exists
        if (activeProposal.instructionsId == 0) {
            revert NoActiveProposalDetected();
        }

        // ensure the user has no pre-existing votes on the proposal
        if (
            userVotesForProposal[activeProposal.instructionsId][msg.sender] > 0
        ) {
            revert UserAlreadyVoted();
        }

        // record the votes
        if (for_) {
            yesVotesForProposal[activeProposal.instructionsId] += userVotes;
        } else if (!for_) {
            noVotesForProposal[activeProposal.instructionsId] += userVotes;
        }

        // record that the user has casted votes
        userVotesForProposal[activeProposal.instructionsId][
            msg.sender
        ] = userVotes;

        // transfer voting tokens to contract
        TOKEN.transferFrom(msg.sender, address(this), userVotes);

        // emit the corresponding event
        emit WalletVoted(
            activeProposal.instructionsId,
            msg.sender,
            for_,
            userVotes
        );
    }

    function executeProposal() external {
        // require the net votes (yes - no) to be greater than 33% of the total voting supply
        if (
            (yesVotesForProposal[activeProposal.instructionsId] -
                noVotesForProposal[activeProposal.instructionsId]) *
                3 <
            TOKEN.totalSupply()
        ) {
            revert NotEnoughVotesToExecute();
        }

        // ensure three days have passed before the proposal can be executed
        if (block.timestamp < activeProposal.activationTimestamp + 3 days) {
            revert ExecutionTimelockStillActive();
        }

        // execute the active proposal
        Instruction[] memory instructions = INSTR.getInstructions(
            activeProposal.instructionsId
        );

        for (uint256 step = 0; step < instructions.length; step++) {
            kernel.executeAction(
                instructions[step].action,
                instructions[step].target
            );
        }

        // emit the corresponding event
        emit ProposalExecuted(activeProposal.instructionsId);

        // deactivate the active proposal
        activeProposal = ActivatedProposal(0, 0);
    }

    function reclaimVotes(uint256 instructionsId_) external {
        // get the amount of tokens the user voted with
        uint256 userVotes = userVotesForProposal[instructionsId_][msg.sender];

        // ensure the user is not claiming for the active propsal
        if (instructionsId_ == activeProposal.instructionsId)
            revert CannotReclaimTokensForActiveVote();

        // ensure the user has not already claimed before for this proposal
        if (tokenClaimsForProposal[instructionsId_][msg.sender] == true)
            revert VotingTokensAlreadyClaimed();

        // Record the voting tokens being claimed from the contract
        tokenClaimsForProposal[instructionsId_][msg.sender] = true;

        // Get voting reward according to reward rate
        uint256 voteReward = (userVotes * (10000 + rewardRate)) / 1e4;
        // TODO can do this on first claim for a proposal to mint entire
        // reward for all TOKEN.

        // return the tokens back to the user
        TOKEN.transfer(msg.sender, userVotes);
        TOKEN.mintTo(msg.sender, voteReward);
    }
}
