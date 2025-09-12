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
    error SendMoreToEnterRaffle();

    //connot change this /cheap for gas
    uint256 private immutable i_entranceFee;

    constructor(uint256 entranceFee) {
        i_entranceFee = entranceFee;
    }

    function enterRaffle() public payable {
        //having string here is not very gas efficient
        // require(msg.value>= i_entranceFee,"Not enough ETH sent");
        if (msg.value < i_entranceFee) {
            revert SendMoreToEnterRaffle();
        }
    }

    function pickWinner() public {}

    /** Getter functions  */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
