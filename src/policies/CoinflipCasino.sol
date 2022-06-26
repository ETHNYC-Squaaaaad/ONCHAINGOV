// SPDX-License-Identifier: AGPL-3.0-only

// The Proposal Policy submits & activates instructions in a INSTR module

pragma solidity ^0.8.13;

import {Token} from "src/modules/TOKEN.sol";
import {Random} from "src/modules/RANDM.sol";
import {Kernel, Policy} from "src/Kernel.sol";

contract CoinflipCasino is Policy {
    /////////////////////////////////////////////////////////////////////////////////
    //                         Kernel Policy Configuration                         //
    /////////////////////////////////////////////////////////////////////////////////

    Random public RANDM;
    Token public TOKEN;

    constructor(Kernel kernel_) Policy(kernel_) {}

    function configureReads() external override {
        RANDM = Random(getModuleAddress("RANDM"));
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
        roles[0] = TOKEN.ISSUER;
    }

    /////////////////////////////////////////////////////////////////////////////////
    //                             Policy Variables                                //
    /////////////////////////////////////////////////////////////////////////////////

    function flip() external {
        if (RANDM.generateRandom(1) % 2 == 1) {
            TOKEN.mintTo(msg.sender, 1);
        }
    }
}
