//SPDX-License-Identifier:MIT
pragma solidity 0.8.19;

import {Script} from "lib/forge-std/src/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";

contract DeployRaffle is Script{

    function run() public {
        deployContract();
    }

    function deployContract() public  returns(Raffle, HelperConfig){
        HelperConfig helperConfig= new HelperConfig();
        address account= helperConfig.getConfig().account;
        HelperConfig.NetworkConfig memory config= helperConfig.getConfig();

        uint256 subscriptionId= config.subscriptionId;
        address vrfCoordinatorV2= config.vrfCoordinator;

        if(config.subscriptionId == 0){
            CreateSubscription createSubscription= new CreateSubscription();
            (subscriptionId, vrfCoordinatorV2) = createSubscription.createSubscription(config.vrfCoordinator, account);

            //fund it
            FundSubscription fundSubscription= new FundSubscription();
            fundSubscription.fundSubscription(vrfCoordinatorV2, subscriptionId, config.link, account);
        }

        vm.startBroadcast(account);
        Raffle raffle= new Raffle(
            config.entranceFee,
            config.interval,
            vrfCoordinatorV2,
            config.gasLane,
            subscriptionId,
            config.callbackGasLimit
        );
        vm.stopBroadcast();

        AddConsumer addConsumer= new AddConsumer();
        addConsumer.addConsumer(address(raffle), vrfCoordinatorV2, subscriptionId, account);
        
        return (raffle, helperConfig);   
    }
}
