// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

// import 

contract Voting {
    
    struct Voter {
        address voter_address;
        Candidate voter_choice;
        bool has_voted;
    }

    uint public total_voters = 0;
    uint public total_votes = 0;
    uint public time_voting_expires;
    address public admin;

    address public contract_address;
    string public contract_name;

    enum State { Created, Voting, Ended }
    enum Candidate { option_1, option_2 }

    State public state;

    mapping (Candidate => uint) private votes_per_candidate;
    mapping(address => Voter) public voter_register;
    
    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    modifier inState(State _state) {
        require(state == _state);
        _;
    }

    constructor() {
        admin = msg.sender;
        state = State.Created;
        
    }

    event Result(string voting_result, string message, uint total_votes, uint total_voters);

    function addVoter(address _voterAddress) public onlyAdmin() inState(State.Created) {
        // improve it by passing an array instead of one by one
        Voter memory voter;
        voter.voter_address = _voterAddress;
        // check if there is need to define as false the other 2 fields
        voter_register[_voterAddress] = voter;
        total_voters ++;
    }

    function startVote() external inState(State.Created) onlyAdmin() returns(bool){
        state = State.Voting;
        // from the moment the election is going to last 1 day
        time_voting_expires = block.timestamp + 86400;
        return true;
    }
    
    function voting (Candidate _choice) external inState(State.Voting) returns(bool) {
        require (block.timestamp < time_voting_expires, 'election has expired');
        require (_choice == Candidate.option_1 || _choice == Candidate.option_2, 'your choice has to be one of the candidates');
        Voter storage voter = voter_register[msg.sender];

        require(voter.voter_address == msg.sender && !voter.has_voted);

        // if statements to keep track of each candidate
        if (_choice == Candidate.option_1) {
            voter.voter_choice = Candidate.option_1;
            votes_per_candidate[Candidate.option_1] += 1;  
        } else {
            voter.voter_choice = Candidate.option_2;
            votes_per_candidate[Candidate.option_2] += 1;
        }

        voter.has_voted = true;
        total_votes ++;
        return true;
    }

    function endVoting() external onlyAdmin() inState(State.Voting) returns(bool){
        require (block.timestamp >= time_voting_expires, 'too early, election has to continue');
        string memory message;
        string memory winner;

        uint votes_candidate_1 = votes_per_candidate[Candidate.option_1];
        uint votes_candidate_2 = votes_per_candidate[Candidate.option_2];

        if (votes_candidate_1 == votes_candidate_2) {
            message = 'Both candidates have the same amount of votes';
            winner = 'No winner';
        } else if (votes_candidate_1 > votes_candidate_2) {
            message = 'candidate 1 have won'; 
            winner = 'Candidate 1';
        } else {
            message = 'candidate 2 have won'; 
            winner = 'Candidate 2';
        }

        emit Result(winner, message, total_votes, total_voters);

        state = State.Ended;
        return true;
    }

}