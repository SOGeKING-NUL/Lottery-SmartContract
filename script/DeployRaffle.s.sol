//SPDX-License-Identifier:MIT
pragma solidity ^0.8.18;

import {Script} from "lib/forge-std/src/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeplyRaffle is Script{

    function run() public {}

    function deployContract() public  returns(Raffle, HelperConfig){
        HelperConfig helperConfig= new HelperConfig();
        HelperConfig.NetworkConfig memory config= helperConfig.getConfig();

        vm.startBroadcast();
        Raffle raffle= new Raffle(
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.gasLane,
            config.subscriptionId,
            config.callbackGasLimit
        );
        vm.stopBroadcast();
        return (raffle, helperConfig);   
    }
}
