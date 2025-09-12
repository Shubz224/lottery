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

    /**Events */

    event RaffleEntered(address indexed player);

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
        s_lastTimeStamp = block.timestamp;
        i_subscriptionId = subscriptionId;
        i_callbackgasLimit = callbackgasLimit;
    }

    function enterRaffle() external payable {
        //having string here is not very gas efficient
        // require(msg.value>= i_entranceFee,"Not enough ETH sent");
        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle();
        }
        s_players.push(payable(msg.sender));

        // 1. Makes migration easier
        // 2. Makes frontend "indexing" easier
        emit RaffleEntered(msg.sender);
    }

    // 1.Get a random number
    // 2. Use random number to pick a player
    // 3. Be automatically called

    function pickWinner() external {
        //check if enough time has passed
        if ((block.timestamp - s_lastTimeStamp) < i_interval) {
            revert();
        }
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
                    VRFV2PlusClient.ExtraArgsV1({
                        nativePayment: true
                    })
                )
            })
        );
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] calldata randomWords
    ) internal virtual override {}

    /** Getter functions  */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
