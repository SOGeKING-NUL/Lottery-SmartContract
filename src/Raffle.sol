//SPDX-License-Identifier:MIT
pragma solidity ^0.8.18;

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
    error Raffle_TransferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle_UpkeepNotNeeded(uint256 currentState, uint256 balance, uint256 numPlayers);

    //events
    event WinnerPicked(address indexed winner);

    //type Declarations
    enum RaffleState{
        OPEN,
        CALCULATING
    }

    uint16 private constant REQUEST_CONFIRMATIONS= 3;
    uint32 private constant NUM_WORDS= 1;
    uint256 private immutable i_entranceFee;
    uint256 private s_lastTimestamp;
    uint32 private immutable i_callbackGasLimit;
    uint256 private immutable i_interval;
    uint256 private immutable i_subscriptionId;
    bytes32 private immutable i_keyHash;
    address payable[] private s_players; 
    address private s_recentWinner;
    RaffleState private s_raffleState;

    event RaffleEntry(address indexed player);

    constructor(
        uint256 entranceFee, 
        uint256 interval, 
        address vrfCoordinator, 
        bytes32 gasLane, 
        uint256 subscriptionId, 
        uint32 callbackGasLimit) VRFConsumerBaseV2Plus(vrfCoordinator){

        i_entranceFee= entranceFee;
        s_lastTimestamp= block.timestamp;
        i_interval= interval;
        i_keyHash= gasLane;
        i_subscriptionId= subscriptionId;
        i_callbackGasLimit= callbackGasLimit;
        
        s_raffleState= RaffleState.OPEN;
    }

    function enterRaffle() public payable{

        //require that the raffle is open
        if(s_raffleState != RaffleState.OPEN){
            revert Raffle__RaffleNotOpen();
        }

        //require that the player has sent enough ETH
        if(msg.value < i_entranceFee){
            revert Raffle__NotEnoughETH();
        }
        
        s_players.push(payable(msg.sender));
        emit RaffleEntry(msg.sender);
    }

    /*
    When should the Winner be picked?

    *@dev this is the fucntoin the chainlink node will call to see if lottery is ready to be picked
    *@dev The winner will be picked when:
    *1. When the time interval has passed
    *2. Lottery is open
    *3.The contract has ETH
    *4. The contract has players
    *4. Implicitly, your subscription has LINK
    *@params- ignored
    *@return upkeepNeeded - Trure if its time to restartthe Lottery
    *@return- ignored
    */

   function checkUpkeep(bytes memory /* checkData */) public view returns (bool upkeepNeeded, bytes memory /* performData */){
        bool timePassed= ((block.timestamp - s_lastTimestamp) > i_interval);
        bool isOpen= (RaffleState.OPEN == s_raffleState);
        bool hasBalance= (address(this).balance > 0);
        bool hasPlayers= (s_players.length > 0);
        upkeepNeeded= isOpen && timePassed && hasPlayers && hasBalance;
        return(upkeepNeeded, "");
   }

    function performUpkeep() public payable{
        (bool upkeepNeeded, )= checkUpkeep("");
        if(!upkeepNeeded){
            revert Raffle_UpkeepNotNeeded(uint256(s_raffleState), address(this).balance, s_players.length);
        }
        s_raffleState= RaffleState.CALCULATING;
        
        VRFV2PlusClient.RandomWordsRequest memory request= VRFV2PlusClient.RandomWordsRequest({
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

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override{
        //we are finding winner index by randomNumber % numberOfPlayers
        uint256 winnerIndex= randomWords[0] % s_players.length;
        address payable recentWinner = s_players[winnerIndex];
        s_recentWinner= recentWinner;
        s_raffleState= RaffleState.OPEN;
        s_players= new address payable[](0);
        s_lastTimestamp= block.timestamp;

        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success){
            revert Raffle_TransferFailed();
        }  

        emit WinnerPicked(recentWinner);      
    }

    //getters

    function getEntranceFee() public view returns(uint256){
        return i_entranceFee;
    }

    function getRaffleState() public view returns(RaffleState){
        return s_raffleState;
    }

    function getPlayer(uint256 playerIndex) public view returns(address){
        return s_players[playerIndex];
    }
}