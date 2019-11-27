/**
Assume that two players A, B would like to perform a simple lottery based on coin tossing. Each
player tosses a coin randomly, and then if the two outputs are similar, A wins, otherwise B wins.
Winning can be rewarded by collecting initial deposits made by the players. This is likely easy to
run if both players A and B are in the same place as both are able to see each other's coin
tosses, but obviously doing that remotely in a secure way is more challenging. In this paper a
variant protocol for a simple lottery application using Bitcoin was described. Read the protocol
(just to understand the high-level details), and answer the following questions:
a) (5%) How does the protocol protect against players who could either abort, or try to
cheat? Which features of Bitcoin transactions does it rely on?
b) (65%) Code: Describe an alternative solution for this simple lottery using a smart
contract, and provide solidity code for it. Your code should just consider the case of
three players, where each player makes a random choice of either 0, 1 or 2. The winner
index will be computed by (in 0 + in 1 + in2 ) % 3, where in i is the random input submitted by
player i.
Your contract should not allow any party to cheat, and should penalize any party who
aborts, or who doesn't comply with the protocol at any point. You have freedom in
choosing the specifics as long as the main objective is achieved and the contract is
secure. For example, you could assume that an admin will register three specific*/
**/

pragma solidity 0.4.18;

import "";


/** Ethereum Lottery Smart Contract.*/
contract Lottery is Ownable {
    uint internal numTickets;
    uint internal availTickets;
    uint internal ticketPrice;
    uint internal winningAmount;
    bool internal gameStatus;
    uint internal counter;

    // This declares a new complex type which will
    // be used for variables later.
    // It will represent a single voter.
    struct Voter {
        uint weight; // weight is accumulated by delegation
        bool voted;  // if true, that person already voted
        address delegate; // person delegated to
        uint vote;   // index of the voted proposal
    }
    struct Player{
        byte32 name;    //Short name of the player
        bool play;      // if the player played then true
        uint choice;    // index of the choice either 0,1,2
    }
    struct Proposal {
        bytes32 name;   // short name (up to 32 bytes)
        uint voteCount; // number of accumulated votes
    }

    // mapping to have address to Player struct value.
    mapping (address => Player) internal players;

    // Event which would be emmitted once winner is found.
    event Winner(uint indexed counter, address winner, string mesg);

    /** getLotteryStatus function returns the Lotter status.
      * @return numTickets The total # of lottery tickets.
      * @return availTickets The # of available tickets.
      * @return ticketPrice The price for one lottery ticket.
      * @return gameStatus The Status of lottery game.
      * @return contractBalance The total available balance of the contract.
     */
    function getLotteryStatus() public view returns(uint, uint, uint, bool, uint) {
        return (numTickets, availTickets, ticketPrice, gameStatus, winningAmount);
    }

    /** startLottery function inititates the lottery game with #tickets and ticket price.
      * @param tickets - no of max tickets.
      * @param price - price of the ticket.
     */
    function startLottery(uint tickets, uint price) public payable onlyOwner {
        if ((tickets <= 1) || (price == 0) || (msg.value < price)) {
            revert();
        }
        numTickets = tickets;
        ticketPrice = price;
        availTickets = numTickets - 1;
        players[++counter] = owner;
        // increase the winningAmount
        winningAmount += msg.value;
        // set the gameStatus to True
        gameStatus = true;
        playerAddresses[owner] = true;
    }

    /** function playLotter allows user to buy tickets and finds the winnner,
      * when all tickets are sold out.
     */
    function playLottery() public payable {
        // revert in case user already has bought a ticket OR,
        // value sent is less than the ticket price OR,
        // gameStatus is false.
        if ((playerAddresses[msg.sender]) || (msg.value < ticketPrice) || (!gameStatus)) {
            revert();
        }
        availTickets = availTickets - 1;
        players[++counter] = msg.sender;
        winningAmount += msg.value;
        playerAddresses[msg.sender] = true;
        // reset the Lotter as soon as availTickets are zero.
        if (availTickets == 0) {
            resetLottery();
        }
    }

    /** getGameStatus function to get value of gameStatus.
      * @return gameStatus - current status of the lottery game.
     */
    function getGameStatus() public view returns(bool) {
        return gameStatus;
    }

    /** endLottery function which would be called only by Owner.
     */
    function endLottery() public onlyOwner {
        resetLottery();
    }

    /** getWinner getter function.
      * this calls getRandomNumber function and
      * finds the winner using players mapping
     */
    function getWinner() internal {
        uint winnerIndex = getRandomNumber();
        address winnerAddress = players[winnerIndex];
        Winner(winnerIndex, winnerAddress, "Winner Found!");
        winnerAddress.transfer(winningAmount);
    }

    /** getRandomNumber function, which finds the random number using counter.
     */
    function getRandomNumber() internal view returns(uint) {
        uint random = uint(block.blockhash(block.number-1))%counter + 1;
        return random;
    }

    /** resetLottery function resets lottery and find the Winner.
     */
    function resetLottery() internal {
        gameStatus = false;
        getWinner();
        winningAmount = 0;
        numTickets = 0;
        availTickets = 0;
        ticketPrice = 0;
        counter = 0;
    }
}