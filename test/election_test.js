const { time } = require('@openzeppelin/test-helpers')

const { assert, expect } = require('chai');
const truffleAssert = require('truffle-assertions');
const Voting = artifacts.require('./Voting.sol');

const State = {
    Created: 0,
    Voting: 1,
    Ended: 2
}

const Options = {
    abstain: 0,
    candidate_1: 1,
    candidate_2: 2
}

require('chai')
    .use(require('chai-as-promised'))
    .should()

contract('Voting', ([admin, voter1, voter2, voter3]) => {

    let voting, time_start;
    beforeEach(async () => {
        voting = await Voting.deployed();
    })

    describe('deployment', async () => {
        it('is deployed succesfully', async () => {
            const address = await voting.address
            assert.notEqual(address, 0x0)
            assert.notEqual(address, '')
            assert.notEqual(address, null)
            assert.notEqual(address, undefined)
        })
        it('admin address is set correctly', async () => {
            const admin_address = await voting.admin()
            assert.equal(admin, admin_address)
        })
        it('after deployment, state is set correctly', async () => {
            const state = await voting.state()
            assert.equal(state, State.Created)
        })
    })

    describe('functionality', async () => {
        it('should allow admin to add voters correctly', async () => {
            await voting.addVoter(voter1, {from:admin})
            const voter = await voting.voter_register(voter1)
            assert.equal(voter.voter_address, voter1, 'voters address has to match')
            assert.equal(voter.voter_choice, Options.abstain, 'default value has to be abstain')
            expect(voter.has_voted).to.be.false
        })
        it('voters_count should increase by 1 after adding a voter', async () => {
            const count_before = await voting.voters_count()
            await voting.addVoter(voter2, {from: admin})
            const count_after = await voting.voters_count()
            const increase = count_after - count_before
            assert.equal(increase, 1, 'should increase by 1')
        })
        it('should not allow someone different from the admin to add voters', async () => {
            await voting.addVoter(voter2, {from:voter1}).should.be.rejected
        })
        it('admin should not be abe to start the voting without registering all the voters', async () => {
            await voting.startVote({from:admin}).should.be.rejected
        })
        it('voters should not be able to vote before admin starts the voting period', async () => {
            await voting.vote(Options.candidate_1, {from: voter1}).should.be.rejected
        })
        it('admin should be abe to start the voting after registering all the voters', async () => {
            await voting.addVoter(voter3, {from:admin})
            const start = await voting.startVote({from:admin}).should.be.fulfilled
            time_start = await time.latest()
            const time_expires = await voting.time_voting_expires()
            const status = await voting.state()
            assert.equal(status, State.Voting, 'State should be Voting')
            
            truffleAssert.eventEmitted(start, 'Start_vote', e => {
                const time_start_event = e.time_started.toString();
                const time_expires_event = e.time_expires.toString();
                return time_start_event === time_start.toString() 
                    && time_expires_event === time_expires.toString()
            })
            
        })
        it('voters should be able to vote after admin starts the voting period', async () => {
            await voting.vote(Options.candidate_1, {from: voter1}).should.be.fulfilled
            const voter_1 = await voting.voter_register(voter1)
            assert.equal(voter_1.voter_address, voter1, 'voters address has to match')
            assert.equal(voter_1.voter_choice, Options.candidate_1, 'default value has to be abstain')
            expect(voter_1.has_voted).to.be.true
            const candidate_1_votes = await voting.votes_per_candidate(Options.candidate_1)
            assert.equal(candidate_1_votes, 1, 'candidate 1 should have 1 vote')
            const candidate_2_votes = await voting.votes_per_candidate(Options.candidate_2)
            assert.equal(candidate_2_votes, 0, 'candidate 2 should have 0 votes')
            const abstain_votes = await voting.votes_per_candidate(Options.abstain)
            assert.equal(abstain_votes, 0, 'abstain votes should be equal to 0')
            await voting.vote(Options.candidate_1, {from: voter2}).should.be.fulfilled
            await voting.vote(Options.candidate_2, {from: voter3}).should.be.fulfilled
        })
        it('admin should not be able to end the voting period earlier', async() => {
            await voting.endVoting({from: admin}).should.be.rejected
        })
        it('only admin can end voting period', async () => {
            await time.increaseTo(time_start.add(time.duration.days(1)))
            await voting.endVoting({from: voter1}).should.be.rejected
        })
        it('admin should be able to end the voting period after 1 day', async() => {
            const end = await voting.endVoting({from: admin}).should.be.fulfilled
            const status = await voting.state()
            assert.equal(status, State.Ended, 'Status should change to Ended')
            
            truffleAssert.eventEmitted(end, 'Result', (e) => {
                const winner = e.voting_winner
                const message = e.message
                const total_votes = e.total_votes
                const voters_count = e.voters_count
                
                // check that winner, total votes and voters count are set correctly 
                return winner == Options.candidate_1 && message == 'candidate 1 have won' 
                    && total_votes == 3 && voters_count == 3
            })
        })
    })
})