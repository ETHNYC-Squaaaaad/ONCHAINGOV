// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {Script, console2} from "forge-std/Script.sol";

import {Kernel, Actions} from "src/Kernel.sol";

import {Instructions} from "src/modules/INSTR.sol";
import {Token} from "src/modules/TOKEN.sol";
import {Authorization} from "src/modules/AUTHR.sol";
import {Treasury} from "src/modules/TRSRY.sol";
import {Random} from "src/modules/RANDM.sol";

import {Governance} from "src/policies/Governance.sol";
import {CoinflipCasino} from "src/policies/CoinflipCasino.sol";
import {TreasuryYieldManager} from "src/policies/TreasuryYieldManager.sol";
import {Faucet} from "src/policies/Faucet.sol";

contract Deploy is Script {
    function run() external {
        vm.startBroadcast();

        // deploy kernel
        Kernel kernel = new Kernel();
        console2.log("Kernel deployed at:", address(kernel));

        // deploy modules
        Instructions instr = new Instructions(kernel);
        console2.log("Instructions module deployed at:", address(instr));

        Token token = new Token(kernel);
        console2.log("Token module deployed at:", address(token));

        Treasury treasury = new Treasury(kernel);
        console2.log("Treasury module deployed at:", address(treasury));

        Authorization auth = new Authorization(kernel);
        console2.log("auth module deployed at:", address(auth));

        Random random = new Random(kernel);
        console2.log("Instructions module deployed at:", address(random));

        // deploy policies
        Governance gov = new Governance(kernel);
        console2.log("Governance policy deployed at:", address(gov));

        TreasuryYieldManager yieldMgr = new TreasuryYieldManager(kernel);
        console2.log("Yield Manager policy deployed at:", address(yieldMgr));

        Faucet faucet = new Faucet(kernel);
        console2.log("Faucet policy deployed at:", address(faucet));

        CoinflipCasino flip = new CoinflipCasino(kernel);
        console2.log("Coinflip policy deployed at:", address(flip));

        // install modules
        kernel.executeAction(Actions.InstallModule, address(instr));
        kernel.executeAction(Actions.InstallModule, address(token));
        kernel.executeAction(Actions.InstallModule, address(treasury));
        kernel.executeAction(Actions.InstallModule, address(auth));
        kernel.executeAction(Actions.InstallModule, address(random));

        // approve policies
        kernel.executeAction(Actions.ApprovePolicy, address(gov));
        kernel.executeAction(Actions.ApprovePolicy, address(yieldMgr));
        kernel.executeAction(Actions.ApprovePolicy, address(faucet));
        kernel.executeAction(Actions.ApprovePolicy, address(flip));

        token.approve(address(gov), type(uint256).max);

        // transfer executive powers to governance
        kernel.executeAction(Actions.ChangeExecutor, address(gov));

        vm.stopBroadcast();
    }
}
