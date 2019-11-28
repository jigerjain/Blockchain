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
secure. For example, you could assume that an admin will register three specific
Code:
Protocol:

Case with 3 players,
Each with a random choice either 0,1,2

Winner index (ch1, ch2, ch3)%3

ex: 
(1,1,1)%3 = 0
(1,1,2)%3 = 1
(1,2,2)%3 = 2

Struct Player{
    string name;
    uint choice;
}

*/

pragma solidity >=0.4.22 <0.7.0;

/** Ethereum Lottery Smart Contract.*/
contract Lottery {
    //uint public winningAmount;
    uint public total_deposit;
    uint public min_deposit;
    uint internal choice_sum;
    uint winningAmount;

    // This declares a new complex type which will
    // be used for variables later.
    // It will represent a single voter.
    struct Player{
        address player_address;    //Short name of the player
        string name;
        bool played;    // if the player played then true
        uint choice;    // index of the choice either 0,1,2
        uint deposit;   //  Deposit for their play
        uint weight;
        
    }


    // mapping to have address to Player struct value.
    mapping (uint => Player) public players;
    address private admin;

  
    // Event which would be emmitted once winner is found.
    event Winner(uint amount, address winner, string mesg);
    constructor(uint deposit, address[] memory player_addresses) public payable{
        admin = msg.sender;
        min_deposit = deposit;
        
        for (uint j=0; j<3; j++){
            players[j].player_address = player_addresses[j];
            players[j].weight = 1;
        }
        // Minimum deposit required for players to participate;
    }

    function play(string memory name, uint choice, uint deposit) public {
        
        Player storage person = players[5];
        // bool notvalid;
        for (uint k=0; k<3; k++){
            if (players[k].player_address==msg.sender)
               {person = players[k];}
        }

        require(!person.played && person.weight==1, "You have already chosen the value or you are not selected by the admin for play");
        require(inRange(choice), "Please choose number 0, 1 or 2");
        require(deposit >= min_deposit, "Your deposit value is less than minimum required");
        person.played = true;
        person.choice = choice;
        person.name = name;
        person.deposit = deposit;
        total_deposit += person.deposit;
        choice_sum += person.choice;
    }

    function inRange(uint check) internal pure returns(bool isIndeed) {
        return check >= 0 && check <= 2;
    }
    
    function all_played() internal view{
        for (uint i=0; i<3; i++){
           require(players[i].played, "All players did not participate");
        }
    }

    /** getWinner getter function */
    function getWinner() public payable returns(uint random_index){
        all_played();
        random_index = (choice_sum)%3;
        address winnerAddress = players[random_index].player_address;
        winningAmount = total_deposit;
        emit Winner(winningAmount,winnerAddress,"You are winner");
        
        //reset = "Game is been reset, you could play again";
    }
    
    function winner() public returns(string memory name){
        uint random_index = getWinner();
        name = players[random_index].name;
        resetLottery();
    }
    
    function resetLottery() internal {
        total_deposit = 0;
        min_deposit = 0;
        choice_sum = 0;
        for (uint i=0; i<3; i++){
           players[i].played = false;
        }
        
    }
}