// SPDX-License-Identifier: MIT
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
pragma solidity ^0.8.19;

/**
 *@title A Sample Raffle contract
 *@author Shubham
 *@notice This contrcat is for creating a simple raffle
 *@dev Implements Chainlink VRFv2.5
 **/

contract Raffle is VRFConsumerBaseV2Plus {
    /**Custom Errors */
    error Raffle__SendMoreToEnterRaffle();
    error Raffle__TransferFailed();
    error Raffle__StateNotOpen();
    error Raffle__UpKeepNotNeeded(
        uint256 balance,
        uint256 playersLength,
        uint256 raffleState
    );

    /** type declaration */
    enum RaffleState {
        OPEN, //03
        CALCULATING //1
    }

    //connot change this /cheap for gas
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint256 private immutable i_entranceFee;
    // @dev The duration of lottery in seconds
    uint16 private constant NUM_WORDS = 1;
    uint256 private immutable i_interval;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackgasLimit;
    //data structure to store all players enters the lottry contest
    address payable[] private s_players;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    /**Events */

    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackgasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_keyHash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackgasLimit = callbackgasLimit;

        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable {
        //having string here is not very gas efficient
        // require(msg.value>= i_entranceFee,"Not enough ETH sent");
        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle();
        }

        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__StateNotOpen();
        }

        s_players.push(payable(msg.sender));

        // 1. Makes migration easier
        // 2. Makes frontend "indexing" easier
        emit RaffleEntered(msg.sender);
    }

    //this funtion will run again and again till the time is up for drawing up winner

    function checkUpkeep(
        bytes memory /*checkData*/
    ) public view returns (bool upkeepNeeded, bytes memory /*performData */) {
        bool timeHasPassed = ((block.timestamp - s_lastTimeStamp) >=
            i_interval);
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = timeHasPassed && isOpen && hasBalance && hasPlayers;
        return (upkeepNeeded, "");
    }

    // 1.Get a random number
    // 2. Use random number to pick a player
    // 3. Be automatically called

    //pickWinner Function becomes Perform up keep for chainlink automation

    function performUpkeep() external {
        //check if enough time has passed
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpKeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }

        s_raffleState = RaffleState.CALCULATING;

        //get our random number from chainlink
        //Two step method
        // 1.Request Random number generator
        // 2.Get random number generator

        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackgasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal virtual override {
        //s_players =10;
        // rng= 12;
        // 12%10 =2 <-
        //44343434334334343434
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        emit WinnerPicked(s_recentWinner);

        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
    }

    /** Getter functions  */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}

/*
// from chainlink automation result 

 function performUpkeep(bytes calldata ( performData )) external override {
        if ((block.timestamp - lastTimeStamp) > interval) {
            lastTimeStamp = block.timestamp;
            counter = counter + 1;
        }
 */
