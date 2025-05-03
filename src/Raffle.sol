//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

import {VRFConsumerBaseV2Plus} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/dev/vrf/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/dev/vrf/libraries/VRFV2PlusClient.sol";

/*
    @title Raffle Contract
    @notice This contract is for creating a simple raffle
    @dev This implements a simple raffle contract with entrance fee and winner selection 
*/

contract Raffle is VRFConsumerBaseV2Plus{

    //errors
    error Raffle__NotEnoughETH();

    uint256 private constant REQUEST_CONFIRMATIONS= 3;
    uint32 private constant NUM_WORDS= 1;
    uint256 private immutable i_entranceFee;
    uint256 private s_lastTimestamp;
    uint32 private immutable i_callbackGasLimit;
    uint256 private immutable i_interval;
    uint256 private immutable i_subscriptionId;
    bytes32 private immutable i_keyHash;
    address payable[] private s_players; 

    event RaffleEntry(address indexed player);

    constructor(uint256 entranceFee, uint256 interval, address vrfCoordinator, bytes32 gasLane, uint256 subscriptionId, uint32 callbackGasLimti) VRFConsumerBaseV2Plus(vrfCoordinator){
        i_entranceFee= entranceFee;
        s_lastTimestamp= block.timestamp;
        i_interval= interval;
        i_keyHash= gasLane;
        i_subscriptionId= subscriptionId;
        i_callbackGasLimit= callbackGasLimti;

    }

    function enterRaffle() public payable{
        if(msg.value < i_entranceFee){
            revert Raffle__NotEnoughETH();
        }
        s_players.push(payable(msg.sender));
        emit RaffleEntry(msg.sender);
    }

    function pickWinner() public payable{
        if((block.timestamp - s_lastTimestamp) < i_interval){
            revert();
        }

        VRFV2PlusClient.RandomWordsRequest request= VRFV2PlusClient.RandomWordsRequest({
            keyHash: i_keyHash,
            subId: i_subscriptionId,
            requestConfirmations: REQUEST_CONFIRMATIONS,
            callbackGasLimit: i_callbackGasLimit,
            numWords: NUM_WORDS,
            extraArgs: VRFV2PlusClient._argsToBytes( 
                VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
            )
        });

        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            request
        );

    }

    //getters

    function getEntranceFee() public view returns(uint256){
        return i_entranceFee;
    }
}