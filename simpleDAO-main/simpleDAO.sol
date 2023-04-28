//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract SimpleDAO {
    
    struct Member { // to find if the given address is member and approved by the admin
        bool isMember;
        bool isApproved;
    }
  
    struct Proposal { //proposal description
        address creator;
        string description;
        uint256 yesVotes;
        uint256 noVotes;
        bool closed;        
    }

    
    address private admin;

    //mapping
    mapping(address => Member) public members;
    mapping(address => mapping(uint => bool)) public voted;


    Proposal[] public proposals;

    //events
    event MembershipApplication(address applicant);
    event MembershipApproval(address member);
    event ProposalCreated(address creator, string description);
    event VoteCasted(uint proposalIndex, address voter);
    event ProposalClosed(uint proposalIndex, bool result);
    
    modifier onlyAdmin {
        require(msg.sender == admin, "Only admin can call this function.");
        _;
    }
    
    constructor() {
        admin = msg.sender;
    }

    function giveAdmin() public view returns(address Admin){
        return admin;
    }

    //apply for membership checks the sender is not already member
    function applyForMembership() external {
        require(!members[msg.sender].isMember, "You are already a member.");
        members[msg.sender].isMember = true;

        emit MembershipApplication(msg.sender);
    }
    
    //can only be accessed by admin check if he apply for the membership and then approves
    function approveMembership(address _member) external onlyAdmin {
        require(members[_member].isMember, "This address is not a member.");
        require(!members[_member].isApproved, "This member is already approved.");
        members[_member].isApproved = true;

        emit MembershipApproval(_member);
    }
    
    //anyone can create proposal 
    function createProposal(string memory _description) external {
        require(members[msg.sender].isMember && members[msg.sender].isApproved, "You are not an approved member.");
        proposals.push(Proposal({
            creator: msg.sender,
            description: _description,
            yesVotes: 0,
            noVotes: 0,
            closed: false
        }));
        
        emit ProposalCreated(msg.sender, _description);
    }
    
    //only members can vote, alos checks if he already voted for given proposal
    function vote(uint _proposalIndex, bool _vote) external {
        require(members[msg.sender].isMember && members[msg.sender].isApproved, "You are not an approved member.");
        require(msg.sender == admin, "Admin cannot take part in voting");
    
        Proposal storage proposal = proposals[_proposalIndex];
    
        require(!proposal.closed, "Voting for this proposal is closed.");
        require(!voted[msg.sender][_proposalIndex], "You have already voted for this proposal.");
    
        voted[msg.sender][_proposalIndex] = true;
        if (_vote) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }

        emit VoteCasted(_proposalIndex, msg.sender);
    }
    
    //can only accessed by the admin and return the resulr if its true of false
    function closeProposal(uint _proposalIndex) external onlyAdmin {
        Proposal storage proposal = proposals[_proposalIndex];
        require(!proposal.closed, "This proposal is already closed.");
        proposal.closed = true;
        bool result = proposal.yesVotes > proposal.noVotes;

        emit ProposalClosed(_proposalIndex, result);
    }
}
