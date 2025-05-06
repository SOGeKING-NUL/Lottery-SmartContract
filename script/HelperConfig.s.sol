//SPDX-License-Identifier:MIT
pragma solidity ^0.8.18;

import {Script} from "lib/forge-std/src/Script.sol";
import {VRFCoordinatorV2_5Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";

abstract contract CodeConstants {
    
    /* VRF MOCK VALUES */
    uint96 constant public MOCK_BASE_FEE= 0.25 ether; // 0.25 LINK per request
    uint96 constant public MOCK_GAS_PRICE_LINK= 1e9; // 0.000000001 LINK per gas
    // LINK ETH price
    int256 constant public LINK_ETH_PRICE= 4e15; // 0.004 ETH per LINK

    uint256 constant public SEPOLIA_CHAIN_ID= 11155111;
    uint256 constant public LOCAL_CHAIN_ID= 31337; // anvil chain id
}

contract HelperConfig is CodeConstants, Script{

    error HelperConfig_InvalidChainID();

    struct NetworkConfig{
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint256 subscriptionId;
        uint32 callbackGasLimit;
        address link;
        address account;
    }

    NetworkConfig public localNetworkConfig;

    mapping (uint256 chainId => NetworkConfig) public networkConfigs;

    constructor(){
        networkConfigs[SEPOLIA_CHAIN_ID]= getSepoliaEthConfig();
    }

    function getNetworkConfigByChainId(uint256 chainId) public returns(NetworkConfig memory){

        if(networkConfigs[chainId].vrfCoordinator != address(0)){
            return networkConfigs[chainId];
        }else if(chainId == LOCAL_CHAIN_ID){
            return getOrCreateAnvilEthConfig();
        }else {
            revert HelperConfig_InvalidChainID();
        }
    }

    function getConfig() public returns(NetworkConfig memory){
        return getNetworkConfigByChainId(block.chainid);
    }

    function getSepoliaEthConfig() public view returns(NetworkConfig memory){
        return NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 30,
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            callbackGasLimit: 500000,
            subscriptionId: 1392451470619400622339566929558166924195205641676355351015131301558350380300,
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            account:0xF6B7c432181Bd8fc28D7a77D4FeBaabCd028Df4b
        });

    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory){
        if(localNetworkConfig.vrfCoordinator != address(0)){
            return localNetworkConfig;
        }

        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinator= new VRFCoordinatorV2_5Mock(MOCK_BASE_FEE, MOCK_GAS_PRICE_LINK, LINK_ETH_PRICE);
        LinkToken linkToken= new LinkToken();
        vm.stopBroadcast();

        localNetworkConfig= NetworkConfig({
            entranceFee : 0.01 ether,
            interval: 30,
            vrfCoordinator: address(vrfCoordinator),
            //gaslane doesnt matter for local network
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            callbackGasLimit: 500000,
            subscriptionId: 0,
            link: address(linkToken),
            account: 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38 //from base.sol
        });

        return localNetworkConfig;
    }
}