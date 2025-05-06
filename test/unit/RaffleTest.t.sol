//SPDX-License-Identifier:MIT
pragma solidity ^0.8.18;

import {Test} from "lib/forge-std/src/Test.sol";
import {Raffle} from "src/Raffle.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract RaffleTest is Test{

    //events
    event WinnerPicked(address indexed winner);
    event RaffleEntry(address indexed player);

    Raffle public raffle;
    HelperConfig public helperConfig;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint256 subscriptionId;
    uint32 callbackGasLimit;

    address public PLAYER= makeAddr("player");
    uint256 public constant STARTING_BALANCE= 10 ether;


    function setUp() external {

        DeployRaffle deployRaffle= new DeployRaffle();
        (raffle, helperConfig)= deployRaffle.deployContract();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        vm.deal(PLAYER, STARTING_BALANCE);

        entranceFee= config.entranceFee;
        interval= config.interval;
        vrfCoordinator= config.vrfCoordinator;
        gasLane= config.gasLane;
        subscriptionId= config.subscriptionId;
        callbackGasLimit= config.callbackGasLimit;
    }

    function testRaffleInitilaizesInOpenState() public {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function testRaffleRevertsWhenYouDontPayEnough() public {
        //arrange
        vm.prank(PLAYER);

        //act /asset
        vm.expectRevert(Raffle.Raffle__NotEnoughETH.selector);
        raffle.enterRaffle();
    }

    function testEmitsEventOnEntrance() public {
    // Arrange
    vm.expectEmit(true, false, false, false, address(raffle));
    emit RaffleEntry(PLAYER);

    // Act / Assert
    vm.prank(PLAYER);
    raffle.enterRaffle{value: entranceFee}();
    }

    function testDontAllowPlayersToEnterWhileRaffleIsCalculating() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep();

        // Act / Assert
        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }
}


