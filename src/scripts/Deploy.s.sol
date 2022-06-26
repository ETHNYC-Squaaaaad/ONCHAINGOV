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
        Token token = new Token(kernel);
        Treasury treasury = new Treasury(kernel);
        Authorization auth = new Authorization(kernel);
        Random random = new Random(kernel);

        // deploy policies
        Governance gov = new Governance(kernel);
<<<<<<< HEAD
        TreasuryYieldManager yieldMgr = new TreasuryYieldManager(kernel);
        Faucet faucet = new Faucet(kernel);
        CoinflipCasino flip = new CoinflipCasino(kernel);
=======
        CoinflipCasino casino = new CoinflipCasino(kernel);
        TreasuryYieldManager treasuryManager = new TreasuryYieldManager(kernel);
        Faucet faucet = new Faucet(kernel);
>>>>>>> 787ac6fca9c122bb2efeea0e6424b388af9f8fdd

        // install modules
        kernel.executeAction(Actions.InstallModule, address(instr));
        kernel.executeAction(Actions.InstallModule, address(token));
        kernel.executeAction(Actions.InstallModule, address(treasury));
        kernel.executeAction(Actions.InstallModule, address(auth));
        kernel.executeAction(Actions.InstallModule, address(random));

        // approve policies
        kernel.executeAction(Actions.ApprovePolicy, address(gov));
<<<<<<< HEAD
        kernel.executeAction(Actions.ApprovePolicy, address(yieldMgr));
        kernel.executeAction(Actions.ApprovePolicy, address(faucet));
        kernel.executeAction(Actions.ApprovePolicy, address(flip));
=======
        kernel.executeAction(Actions.ApprovePolicy, address(casino));
        kernel.executeAction(Actions.ApprovePolicy, address(treasuryManager));
        kernel.executeAction(Actions.ApprovePolicy, address(faucet));

        // approve votes
        token.approve(address(gov), type(uint256).max);

>>>>>>> 787ac6fca9c122bb2efeea0e6424b388af9f8fdd

        // transfer executive powers to governance
        kernel.executeAction(Actions.ChangeExecutor, address(gov));

        vm.stopBroadcast();
    }
}
