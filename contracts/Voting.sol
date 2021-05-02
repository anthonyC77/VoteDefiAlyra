// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.21 <0.8.1;

import "./Ownable.sol";

contract Voting is Ownable{

    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    struct Proposal {
        string description;
        uint voteCount;
    }
    
    uint private winningProposalId;
    uint private NextiStatus;
    uint private nbAddress;
    uint private nbProposals;
    bool private ExAequo = false;
    address private owner;
    
    enum WorkflowStatus {
        RegisteringVoters,              // 0
        ProposalsRegistrationStarted,   // 1
        ProposalsRegistrationEnded,     // 2
        VotingSessionStarted,           // 3
        VotingSessionEnded,             // 4
        VotesTallied                    // 5
    }
    
    WorkflowStatus  private CurrentStatus;
    
    mapping(uint=> address) private adresses;
    mapping(address=> Voter) private _whitelist;
    mapping(uint=> Proposal) private proposals;

    event VoterRegistered(address voterAddress);
    event ProposalsRegistrationStarted();
    event ProposalsRegistrationEnded();
    event ProposalRegistered(uint proposalId);
    event VotingSessionStarted();
    event VotingSessionEnded();
    event Voted (address voter, uint proposalId);
    event VotesTallied();
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);

    // Public  Datas
    function getCurrentStatus() external view returns(uint){
       return uint(CurrentStatus);
    }
    
    function getProposalsById(uint _idProposal) external view returns(string memory){
      return proposals[_idProposal].description;
    }
    
    function getProposalsByIdLength() external view returns(uint){
      return nbProposals;
    }
    
    function getAddress(uint index) external view returns(address){
       return adresses[index];
    }
   
    function getAddressCount() external view returns(uint){
       return nbAddress;
    }
    
    // End Public  Datas
    

    // Admin actions
    // -------------------------------------------------------------------------------------------------------------
    // Public functions
    // -------------------------------------------------------------------------------------------------------------

   

    // To register only one adress
    function AdminVoteRegisterAdress(address _address) external onlyOwner {
        require(CurrentStatus ==  WorkflowStatus.RegisteringVoters, "The voting registering is ended");
        require(!_whitelist[_address].isRegistered, "This address is already registered");
        RegisterAdress(_address);
    }
    // To register a list of adresses
    function AdminVoteRegisterAdresses(address[] calldata _addresses) external onlyOwner {
        require(CurrentStatus ==  WorkflowStatus.RegisteringVoters, "The voting registering is ended");
        
        for(uint rangeAdresses=0;rangeAdresses<_addresses.length;rangeAdresses++)
            require(!_whitelist[_addresses[rangeAdresses]].isRegistered, "One of this addresses is already registered");

        for(uint rangeAdresses=0;rangeAdresses<_addresses.length;rangeAdresses++)
            RegisterAdress(_addresses[rangeAdresses]);
    }

    function AdminActions(WorkflowStatus _status) external onlyOwner {

        // we convert enum in uint to increment it at the end of this call to have the next awaited status for the next call
        uint istatus = uint(_status);

         // if it's more than 5 it's after the last WorkflowStatus
        if(istatus > 5)
            revert("There is not further step after the vote is tallied");

        // we test if the next event action awaited is the good one if not we throw an error
        if(istatus != NextiStatus)
            ErrorStatus();

        if(_status == WorkflowStatus.ProposalsRegistrationStarted) 
            AdminStartRegisterProposals();
        else if(_status == WorkflowStatus.ProposalsRegistrationEnded)
            AdminStopRegisterProposals();
        else if(_status == WorkflowStatus.VotingSessionStarted)
            AdminStartVoting;
        else if(_status == WorkflowStatus.VotingSessionEnded)
            AdminStopVoting();
         else if(_status == WorkflowStatus.VotesTallied)
             AdminTallied();

         if(_status !=  WorkflowStatus.VotesTallied)
            NextiStatus++;

        emit WorkflowStatusChange(CurrentStatus,_status);

        CurrentStatus = _status;
    }

    // --------------------------------------------------------------------------------------------------------------
    // End Public functions
    // --------------------------------------------------------------------------------------------------------------
    // --------------------------------------------------------------------------------------------------------------
    // Private functions
    // --------------------------------------------------------------------------------------------------------------
    function RegisterAdress(address _address) internal {
        _whitelist[_address].isRegistered = true;

        (NextiStatus,CurrentStatus, adresses[nbAddress]) = (1, WorkflowStatus.RegisteringVoters, _address);
        nbAddress++;
        emit VoterRegistered(_address);
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.RegisteringVoters);
    }

    function AdminStartRegisterProposals() internal {
        require(nbAddress > 0, "no adresses are registered");
        emit ProposalsRegistrationStarted();
    }

    function AdminStopRegisterProposals() internal{
        require(nbProposals > 0, "no propositions are registered");
        emit ProposalsRegistrationEnded();
    }

    function AdminStartVoting() internal{
        emit VotingSessionStarted();
    }

    function AdminStopVoting() internal{
        emit VotingSessionEnded();
    }

    function AdminTallied() internal{
        uint maxCount = 0;
        uint totalCount = 0;

        for(uint proposalId =0;proposalId< nbProposals;proposalId++){
            uint countProposalID = proposals[proposalId].voteCount;
            totalCount += countProposalID;
            if (countProposalID > maxCount){
                maxCount = countProposalID;
                winningProposalId = proposalId;
            }
        }

       CheckIfExAequo(maxCount);

        require(totalCount>0, "There is no winning proposition no votes were done");

        emit VotesTallied();
    }

    function ErrorStatus() view internal {
        string memory statusAwaited = "";
        if(NextiStatus == 0)
            statusAwaited = "First step : registration";
        if(NextiStatus == 1)
            statusAwaited = "Next step : registration start";
        else if(NextiStatus == 2)
            statusAwaited = "Next step : registration end"; 
        else if(NextiStatus == 3)
            statusAwaited = "Next step : vote start"; 
        else if(NextiStatus == 4)
            statusAwaited = "Next step : vote end"; 
        else if(NextiStatus == 5)
            statusAwaited = "Next step : vote counting"; 

        revert(statusAwaited); 
    }

    // if two or more propositions have the same max votes we put it in the ExAequo variable
    function CheckIfExAequo(uint maxCount) internal {
        uint nbVotesMax = 0;
        for(uint proposalId = 0;proposalId< nbProposals;proposalId++){
           uint countProposalID = proposals[proposalId].voteCount;
           if(countProposalID == maxCount){
               nbVotesMax++;
           }
        }

        ExAequo = nbVotesMax > 1;
    }
    // --------------------------------------------------------------------------------------------------------------
     // End Private functions
    // --------------------------------------------------------------------------------------------------------------
    // --------------------------------------------------------------------------------------------------------------
    // End Admin actions
    // --------------------------------------------------------------------------------------------------------------


    // --------------------------------------------------------------------------------------------------------------
    // Users voting actions
    // --------------------------------------------------------------------------------------------------------------
    // --------------------------------------------------------------------------------------------------------------
    // Public functions
    // --------------------------------------------------------------------------------------------------------------
    function UsersProposalsRecord(string calldata _descriptionProposal) external {
        RequireIsPropositionStarted();
        Voter memory voter = _whitelist[msg.sender];
        RequireUserRegistered(voter);
        
        for(uint proposalIdFor =0;proposalIdFor< nbProposals;proposalIdFor++){
            string memory description = proposals[proposalIdFor].description;
            require(keccak256(bytes(_descriptionProposal)) != keccak256(bytes(description)),"This proposition already exists");
        }

        proposals[nbProposals] = Proposal(_descriptionProposal, 0);
        
        emit ProposalRegistered(nbProposals);
        
        nbProposals++;
    }

    function UsersVote(uint proposalId) external {
        RequireIsVoting();
        RequireUserRegistered(_whitelist[msg.sender]);
        require(proposalId < nbProposals, "This proposition doesn't exist");
        require(!_whitelist[msg.sender].hasVoted, "This user has already voted");

        _whitelist[msg.sender].hasVoted = true;
        proposals[proposalId].voteCount += 1; 
        emit Voted(msg.sender, proposalId);
    }

    function UsersGetWinningProposal() view external returns(uint, string memory, uint){
        require(CurrentStatus == WorkflowStatus.VotesTallied, "The vote is not tallied yet");
        require(!ExAequo, "There is no winning proposition, at least two are ex aequo");
        return(
            winningProposalId,
            proposals[winningProposalId].description, 
            proposals[winningProposalId].voteCount
            );
    }
    // --------------------------------------------------------------------------------------------------------------
    // End Public functions
    // --------------------------------------------------------------------------------------------------------------

    // --------------------------------------------------------------------------------------------------------------
    // Private functions
    // --------------------------------------------------------------------------------------------------------------
    function RequireIsPropositionStarted() view internal{
        if(CurrentStatus != WorkflowStatus.ProposalsRegistrationStarted) {
           if(CurrentStatus == WorkflowStatus.RegisteringVoters)
            revert("The propostion recording is not started");
           else
            revert("The proposition recording is ended");
        }
    }

    function RequireIsVoting() view internal{
         if(CurrentStatus != WorkflowStatus.VotingSessionStarted) {
           if(CurrentStatus == WorkflowStatus.VotingSessionEnded || CurrentStatus == WorkflowStatus.VotesTallied)
            revert("The voting is finished");
           else
            revert("The voting is not started");
        }
    }

    function RequireUserRegistered(Voter memory voter) pure internal {
         require(voter.isRegistered, "This address is not registered");
    }
    // --------------------------------------------------------------------------------------------------------------
    // End Private functions
    // --------------------------------------------------------------------------------------------------------------
    // --------------------------------------------------------------------------------------------------------------
    // End Users voting actions
    // --------------------------------------------------------------------------------------------------------------
}