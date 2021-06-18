// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

// import 

contract Voting {
    
    struct Voter {
        address voter_address;
        Options voter_choice;
        bool has_voted;
    }

    uint public total_voters;
    //uint public voters_count = 0;
    uint public total_votes = 0;
    uint public time_voting_expires;
    address public admin;

    address public contract_address;
    string public contract_name;

    enum State { Created, Voting, Ended }
    enum Options { abstain, candidate_1, candidate_2 }

    State public state;
    Options public winner;

    mapping (Options => uint) public votes_per_candidate;
    mapping(address => Voter) public voter_register;
    address[] public voters;
    
    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    modifier inState(State _state) {
        require(state == _state);
        _;
    }

    constructor(uint _totalVoters) {
        admin = msg.sender;
        state = State.Created;
        total_voters = _totalVoters;
    }

    event Start_vote(uint indexed time_started, uint indexed time_expires);
    event Result(Options voting_winner, string message, uint total_votes, uint voters_count);

    function addVoters(address[] memory _voterAddresses) external onlyAdmin() inState(State.Created) {
        require(voters.length == 0, 'voters array must be empty');
        require(_voterAddresses.length == total_voters, 'array must contain all the voters defined in the constructor');
       
        Voter memory voter;
        for (uint i = 0; i < _voterAddresses.length ; i ++) {
            voter.voter_address = _voterAddresses[i];
            voter_register[_voterAddresses[i]] = voter;
            voters.push(_voterAddresses[i]);
            //voters_count ++;
        }
    }

    function startVote() external inState(State.Created) onlyAdmin() returns(bool){
        // require statement to check that all the voters are added and allowed to vote
        require(total_voters == voters.length, 'all the voters should be registered');
        state = State.Voting;
        // from this moment the election is going to last 1 day
        time_voting_expires = block.timestamp + 86400;
        emit Start_vote(block.timestamp, time_voting_expires);
        return true;
    }
    
    function vote (Options _choice) external inState(State.Voting) returns(bool) {
        require (block.timestamp < time_voting_expires, 'election has expired');
        require (_choice == Options.abstain || _choice == Options.candidate_1 || _choice == Options.candidate_2, 'your choice has to be one of the candidates');
        Voter storage voter = voter_register[msg.sender];

        require(voter.voter_address == msg.sender && !voter.has_voted);

        // if statements to keep track of each candidate or abstentions

        if (_choice == Options.candidate_1) {
            voter.voter_choice = Options.candidate_1;
            votes_per_candidate[Options.candidate_1] ++;  
        } else if (_choice == Options.candidate_2) {
            voter.voter_choice = Options.candidate_2;
            votes_per_candidate[Options.candidate_2] ++;
        } else {
            voter.voter_choice = Options.abstain;
            votes_per_candidate[Options.abstain] ++;
        }

        voter.has_voted = true;
        total_votes ++;
        return true;
    }

    function endVoting() external onlyAdmin() inState(State.Voting) returns(bool){
        require (block.timestamp >= time_voting_expires, 'too early, election has to continue');
        string memory message;

        uint votes_candidate_1 = votes_per_candidate[Options.candidate_1];
        uint votes_candidate_2 = votes_per_candidate[Options.candidate_2];

        if (votes_candidate_1 == votes_candidate_2) {
            message = 'Both candidates have the same amount of votes';
            winner = Options.abstain;
        } else if (votes_candidate_1 > votes_candidate_2) {
            message = 'candidate 1 have won'; 
            winner = Options.candidate_1;
        } else {
            message = 'candidate 2 have won'; 
            winner = Options.candidate_2;
        }

        emit Result(winner, message, total_votes, voters.length);

        state = State.Ended;
        return true;
    }

    function getVoters () external view returns (address[] memory) {
        return voters;
    }
}