// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import {Kernel, Module} from "src/Kernel.sol";

// [RANDM] The Random Module generates random numbers using Boba's native RNG
contract Random is Module {
    /////////////////////////////////////////////////////////////////////////////////
    //                         Kernel Module Configuration                         //
    /////////////////////////////////////////////////////////////////////////////////

    constructor(Kernel kernel_) Module(kernel_) {}

    function KEYCODE() public pure override returns (Kernel.Keycode) {
        return Kernel.Keycode.wrap("RANDM");
    }

    function ROLES() public pure override returns (Kernel.Role[] memory roles) {
        roles = new Kernel.Role[](0);
    }

    function INIT() external override {}

    /////////////////////////////////////////////////////////////////////////////////
    //                              Module Variables                               //
    /////////////////////////////////////////////////////////////////////////////////

    function generateRandom(uint256 maxInt_) external pure returns (uint256) {
        // generate random from BOBA's rng system
        return 0;
    }
}
