//SPDX-License-Identifier:MIT
pragma solidity ^0.8.18;

import {Script, console} from "lib/forge-std/src/Script.sol";
import {HelperConfig, CodeConstants} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";


contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        createSubscription(vrfCoordinator);
    }

    function createSubscription(address vrfCoordinator) public returns (uint256, address) {
        console.log("Creating subscription on chainId: ", block.chainid);
        vm.startBroadcast();
        uint256 subscriptionId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        console.log("Your subscription Id is: ", subscriptionId);
        console.log("Please update the subscriptionId in HelperConfig.s.sol");
        return (subscriptionId, vrfCoordinator);
    }

    function run() external returns (uint256, address) {
        return createSubscriptionUsingConfig();
    }
}

contract FundSubscription is CodeConstants, Script {
    uint256 public constant FUND_AMOUNT = 3 ether;  //3 LINK

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        uint256 subscriptionId = helperConfig.getConfig().subscriptionId;
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        address link = helperConfig.getConfig().link;
        fundSubscription(vrfCoordinator, subscriptionId, link);

        // if (subscriptionId == 0) {
        //     CreateSubscription createSub = new CreateSubscription();
        //     (uint256 updatedsubscriptionId, address updatedVRFv2) = createSub.run();
        //     subscriptionId = updatedsubscriptionId;
        //     vrfCoordinator = updatedVRFv2;
        //     console.log("New subscriptionId Created! ", subscriptionId, "VRF Address: ", vrfCoordinator);
        // }        
    }

    function fundSubscription(address vrfCoordinator, uint256 subscriptionId, address link) public {

        console.log("Funding subscription: ", subscriptionId);
        console.log("Using vrfCoordinator: ", vrfCoordinator);
        console.log("On ChainID: ", block.chainid);

        if (block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subscriptionId, FUND_AMOUNT);
            vm.stopBroadcast();
        } else {
            // Check the balance of the sender (your wallet)
            // console.log("LINK Balance of sender:", LinkToken(link).balanceOf(msg.sender));
            
            vm.startBroadcast();
            // Transfer directly from your wallet to the coordinator
            LinkToken(link).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subscriptionId));
            vm.stopBroadcast();
        }
    }


    function run() external {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {

    function addConsumerUsingConfig(address mostRecentlyDeployed) public {
        HelperConfig helperConfig = new HelperConfig();
        uint256 subId = helperConfig.getConfig().subscriptionId;
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        addConsumer(mostRecentlyDeployed, vrfCoordinator, subId);
    }

    function addConsumer(address contractToAddToVrf, address vrfCoordinator, uint256 subId) public {
        console.log("Adding consumer contract: ", contractToAddToVrf);
        console.log("Using vrfCoordinator: ", vrfCoordinator);
        console.log("On ChainID: ", block.chainid);
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subId, contractToAddToVrf);
        vm.stopBroadcast();
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingConfig(mostRecentlyDeployed);
    }
}