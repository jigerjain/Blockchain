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
secure. 
}

*/

pragma solidity >=0.4.22 <0.7.0;

/** Ethereum Lottery Smart Contract.*/
contract Lottery {
    uint public min_deposit;
    uint internal choice_sum;
    uint public winningAmount;
    uint internal lottery_start;
    uint internal lottery_expiry;


    // This declares a new complex type which will
    // be used for variables later.
    // It will represent a single player.
    struct Player{
        address player_address; // Address of the player
        string name;            // Name of the player
        bool played;            // if the player played then true
        uint choice;            // index of the choice either 0,1,2
        uint deposit;           //  Deposit for their play
        uint weight;            // Eligibility to play, set by Constructor
        bool defaulter;         // Checks if you are a defaulter
        uint playedat;          // Checks the time when the player played their lottery
        
    }


    // mapping to have address to Player struct value.
    mapping (uint => Player) public players;
    // Maintaining Administrator for this contract
    address private admin;
  
    // Event which would be emmitted once winner is found.
    event Winner(uint amount, address winner, string mesg);
     // Event which would be emmitted if an interrupt is found.
    event Compensate(uint amount, address player, string msg);
    
    
    // Constructor code is only run when the contract
    // is created
    // In this function we are declaring the lottery_expiry time along with that settig up the timer for lottery
    constructor(uint bet, uint number_of_players, address[] memory player_addresses) public payable{
        resetLottery();
        uint N = number_of_players;
        winningAmount = N*bet;
        min_deposit = N*(N-1)*winningAmount;
        lottery_start = now;
        lottery_expiry = 1 hours;
        
        // Admin assigns minimum deposit required to play in the game which is generally 
        // N*(N-1) times the winningAmount where
        // N equals number of players playing

        for (uint j=0; j<4; j++){
            players[j].player_address = player_addresses[j];
            players[j].weight = 1;
        }
        // 4th address is our lottery admin
        admin = players[3].player_address;
    
    }

    // Function for playing the Lottery which requires a player to enter
    // their name, choice and deposit for playing

    function play(string memory name, uint choice, uint deposit) public {
        // Random initialization of person structure
        Player storage person = players[5];
        // This loop checks 
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
        choice_sum += person.choice;
        
        // Setting the time when the player played
        person.playedat = now;
    }

    function inRange(uint check) internal pure returns(bool isIndeed) {
        return check >= 0 && check <= 2;
    }
    
    // This function checks if all the players have played their part and calls compensation function if someone cheated
    function all_played() internal {
        uint defaulter_count = 0;
        bool interrupt = false;
        for (uint i=0; i<3; i++){
           require(players[i].played, "All players did not participate");
           // This validates if all the players played in time or else they are considered to be defaulters/ cheaters
            if (players[i].playedat - lottery_start > lottery_expiry)
            {
                players[i].defaulter = true;
                interrupt = true;
                defaulter_count++;
            }
        }
        if(interrupt)
        {compensatition(defaulter_count);}

    }
    
    // This function Compensates/ Penalizes the players when a situation occurs
    function compensatition(uint count) internal{
        uint compensation_amount = winningAmount/count;
        for (uint i=0; i<3; i++)
        {   
            if(players[i].defaulter)
            {
                emit Compensate(0,players[i].player_address,"You are a defaulter, thus your deposit is been holded");
            }
            emit Compensate(compensation_amount,players[i].player_address, "You are been compensated because the lottery was interrupted");
        }
        resetLottery();
    }

    // Function to start the lottery only admin could initiate this
    function start_lottery() public payable returns(string memory name){
        require(admin==msg.sender,"Only admin can execute this function");
        all_played();
        uint random_index = (choice_sum)%3;
        name = players[random_index].name;
        address winnerAddress = players[random_index].player_address;
        emit Winner(winningAmount,winnerAddress,"You are winner");
        resetLottery();
    }
    
    // Resets all the variables such that everyone could play again
    function resetLottery() internal {
        min_deposit = 0;
        winningAmount = 0;
        min_deposit = 0;
        choice_sum = 0;
        for (uint i=0; i<4; i++){
           players[i].played = false;
           players[i].deposit = 0;
           players[i].weight = 0;
           players[i].defaulter = false;
        }
        
    }
}