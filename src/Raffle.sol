// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

/**
 *@title A Sample Raffle contract
 *@author Shubham
 *@notice This contrcat is for creating a simple raffle
 *@dev Implements Chainlink VRFv2.5
 **/

contract Raffle {
    /**Custom Errors */
    error Raffle__SendMoreToEnterRaffle();

    //connot change this /cheap for gas
    uint256 private immutable i_entranceFee;
    //data structure to store all players enters the lottry contest
    address payable[] private s_players;

    /**Events */

    event RaffleEntered(address indexed player);

    constructor(uint256 entranceFee) {
        i_entranceFee = entranceFee;
    }

    function enterRaffle() public payable {
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

    function pickWinner() public {}

    /** Getter functions  */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
