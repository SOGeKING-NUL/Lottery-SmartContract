//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

/*
    @title Raffle Contract
    @notice This contract is for creating a simple raffle
    @dev This implements a simple raffle contract with entrance fee and winner selection 
*/

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";

contract Raffle{

    //errors
    error Raffle__NotEnoughETH();

    uint256 private immutable i_entranceFee;
    uint256 private s_lastTimestamp;
    uint256 private immutable i_interval;
    address payable[] private s_players; 

    event RaffleEntry(address indexed player);

    constructor(uint256 entranceFee, uint256 interval){
        i_entranceFee= entranceFee;
        s_lastTimestamp= block.timestamp;
        i_interval= interval;

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

        requestId = s_vrfCoordinator.requestRandomWords(
        VRFV2PlusClient.RandomWordsRequest({
            keyHash: s_keyHash,
            subId: s_subscriptionId,
            requestConfirmations: requestConfirmations,
            callbackGasLimit: callbackGasLimit,
            numWords: numWords,
            extraArgs: VRFV2PlusClient._argsToBytes(
                // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
            )
        })
    );

    }

    //getters

    function getEntranceFee() public view returns(uint256){
        return i_entranceFee;
    }
}