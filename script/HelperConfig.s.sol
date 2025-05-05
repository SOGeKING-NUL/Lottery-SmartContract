//SPDX-License-Identifier:MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";

abstract contract CodeConstants {
    uint256 constant public SEPOLIA_CHAIN_ID= 11155111;
}

contract HelperConfig is CodeConstants, Script{

    error HelperConfig_InvalidChainID();

    struct NetworkConfig{
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        byte32 gasLane;
        uint256 subscriptionId;
        uint32 callbackGasLimit;
    }

    NetworkConfig public localNetworkConfig;

    mapping (uint256 chainId => NetowkrConfig) public networkConfigs;

    constructor(){
        networkConfigs[SEPOLIA_CHAIN_ID]= getSepoliaEthConfig();
    }

    function getNetworkConfigByChainId(uint256 chainId) public returns(NetworkConfig memory){

        if(networkConfigs[chainId].vrfCoordinator != address(0)){
            return networkConfigs[chainId];
        }else if(chainId == LOCAL_CHAIN_ID){
            //getLocalConfig();
        }else {
            revert HelperConfig_InvalidChainID();
        }
    }

    function getSepoliaEthConfig() public view returns(NetworkConfig memory){
        entranceFee= 0.01 ether;
        interval= 30;
        vrfCoordinator= 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B;
        gasLane= 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae;
        callbackGasLimit= 500000;
        subscriptionId= 0;

    }
}