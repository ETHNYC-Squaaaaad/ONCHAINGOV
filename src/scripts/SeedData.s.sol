// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {Script, console2} from "forge-std/Script.sol";

import {Kernel, Instruction, Actions} from "src/Kernel.sol";

import {Instructions} from "src/modules/INSTR.sol";
import {Token} from "src/modules/TOKEN.sol";
import {Authorization} from "src/modules/AUTHR.sol";
import {Treasury} from "src/modules/TRSRY.sol";
import {Random} from "src/modules/RANDM.sol";

import {Governance} from "src/policies/Governance.sol";
import {CoinflipCasino} from "src/policies/CoinflipCasino.sol";
import {TreasuryYieldManager} from "src/policies/TreasuryYieldManager.sol";
import {Faucet} from "src/policies/Faucet.sol";

contract SeedData is Script {

    function run() external {
        vm.startBroadcast();


        // deploy kernel
        Kernel kernel = new Kernel();
        console2.log("Kernel deployed at:", address(kernel));

        // deploy modules
        Instructions instr = new Instructions(kernel);
        Token token = new Token(kernel);
        Treasury treasury = new Treasury(kernel);
        Authorization auth = new Authorization(kernel);
        Random random = new Random(kernel);

        // deploy policies
        Governance gov = new Governance(kernel);
        CoinflipCasino casino = new CoinflipCasino(kernel);
        TreasuryYieldManager treasuryManager = new TreasuryYieldManager(kernel);
        Faucet faucet = new Faucet(kernel);

        // install modules
        kernel.executeAction(Actions.InstallModule, address(instr));
        kernel.executeAction(Actions.InstallModule, address(token));
        kernel.executeAction(Actions.InstallModule, address(treasury));
        kernel.executeAction(Actions.InstallModule, address(auth));
        kernel.executeAction(Actions.InstallModule, address(random));

        // approve policies
        kernel.executeAction(Actions.ApprovePolicy, address(gov));
        kernel.executeAction(Actions.ApprovePolicy, address(casino));
        kernel.executeAction(Actions.ApprovePolicy, address(treasuryManager));
        kernel.executeAction(Actions.ApprovePolicy, address(faucet));

        // approve votes
        token.approve(address(gov), type(uint256).max);

        // SEED DATA IS HERE

        // create new token module
        Token tokenProposal = new Token(kernel);
        Token tokenProposal1 = new Token(kernel);

        // create proposal 1
        Instruction[] memory instructions = new Instruction[](1);
        instructions[0] = Instruction(Actions.InstallModule, address(tokenProposal));
        bytes32 proposalName = "Test Proposal";
        uint256 proposalId = gov.submitProposal(instructions, proposalName);

        // create proposal 2
        Instruction[] memory instructions1 = new Instruction[](1);
        instructions1[0] = Instruction(Actions.InstallModule, address(tokenProposal1));
        bytes32 proposalName1 = "Malicious Proposal :)";
        uint256 proposal1Id = gov.submitProposal(instructions1, proposalName1);

        // mint account 1 tokens
        faucet.mintMeTokens(1000);
        gov.endorseProposal(proposalId);
        gov.endorseProposal(proposal1Id);

        gov.activateProposal(proposalId);

        vm.stopBroadcast();
    }
}