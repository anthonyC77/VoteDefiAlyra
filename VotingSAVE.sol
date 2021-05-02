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

    uint winningProposalId;
    uint NextiStatus;
    uint nbAddress;
    Proposal[] Proposals;
    address[] public addresses;
    WorkflowStatus CurrentStatus;
    bool ExAequo = false;
    uint8[] idProposals;
    mapping(uint8=> string) private ProposalsById;
    mapping(address=> Voter) private _whitelist;
    enum WorkflowStatus {
        RegisteringVoters,              // 0
        ProposalsRegistrationStarted,   // 1
        ProposalsRegistrationEnded,     // 2
        VotingSessionStarted,           // 3
        VotingSessionEnded,             // 4
        VotesTallied                    // 5
    }

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
    function getCurrentStatus() public view returns(uint8){
       return uint8(CurrentStatus);
    }
    
    function getProposalIds() public view returns(uint8[] memory){
       return idProposals;
    }
    
    function getProposalsById(uint8 _idProposal) public view returns(string memory){
      return string(ProposalsById[_idProposal]);
    }
    // End Public  Datas
    

    // Admin actions
    // -------------------------------------------------------------------------------------------------------------
    // Public functions
    // -------------------------------------------------------------------------------------------------------------

    function getAddresses() public view returns(address[] memory){
       return addresses;
   }

    // To register only one adress
    function AdminVoteRegisterAdress(address _address) external onlyOwner {
        require(CurrentStatus ==  WorkflowStatus.RegisteringVoters, "The voting registering is ended");
        require(!_whitelist[_address].isRegistered, "This address is already registered");
        RegisterAdress(_address);
    }
    // To register a list of adresses
    function AdminVoteRegisterAdresses(address[] calldata _addresses) external onlyOwner {
        require(CurrentStatus ==  WorkflowStatus.RegisteringVoters, "The voting registering is ended");
        uint rangeAdresses = 0;
        for(rangeAdresses=0;rangeAdresses<_addresses.length;rangeAdresses++)
            require(!_whitelist[_addresses[rangeAdresses]].isRegistered, "One of this addresses is already registered");

        for(rangeAdresses=0;rangeAdresses<_addresses.length;rangeAdresses++)
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
    function RegisterAdress(address _address) private {
        _whitelist[_address].isRegistered = true;

        NextiStatus = 1;
        CurrentStatus = WorkflowStatus.RegisteringVoters;
        nbAddress++;
        addresses.push(_address);
        emit VoterRegistered(_address);
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.RegisteringVoters);
    }

    function AdminStartRegisterProposals() internal {
        require(nbAddress > 0, "You can't start proposals registration, no adresses are registered");
        emit ProposalsRegistrationStarted();
    }

    function AdminStopRegisterProposals() internal{
        require(Proposals.length > 0, "You can't stop proposals registration, no propositions are registered");
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
        uint proposalId;
        uint totalCount = 0;

        for(proposalId =0;proposalId< Proposals.length;proposalId++){
            uint countProposalID = Proposals[proposalId].voteCount;
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
            statusAwaited = "The first step is the registration of adresses";
        if(NextiStatus == 1)
            statusAwaited = "The next awaited step is the proposal registration starting";
        else if(NextiStatus == 2)
            statusAwaited = "The next awaited step is the proposal registration ending"; 
        else if(NextiStatus == 3)
            statusAwaited = "The next awaited step is the vote starting"; 
        else if(NextiStatus == 4)
            statusAwaited = "The next awaited step is the vote ending"; 
        else if(NextiStatus == 5)
            statusAwaited = "The next awaited step is the vote counting"; 

        revert(statusAwaited); 
    }

    // if two or more propositions have the same max votes we put it in the ExAequo variable
    function CheckIfExAequo(uint maxCount) internal {
         uint nbVotesMax = 0;
         uint proposalId;
        for(proposalId = 0;proposalId< Proposals.length;proposalId++){
           uint countProposalID = Proposals[proposalId].voteCount;
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
    function UsersProposalsRecord(address _address, string calldata _descriptionProposal) external {
        RequireIsPropositionStarted();
        Voter memory voter = _whitelist[_address];
        RequireUserRegistered(voter);
        
        uint8 proposalIdFor = 0;
        for(proposalIdFor =0;proposalIdFor< Proposals.length;proposalIdFor++){
            string memory description = Proposals[proposalIdFor].description;
            require(keccak256(bytes(_descriptionProposal)) != keccak256(bytes(description)),"This proposition already exists");
        }

        Proposals.push(Proposal(_descriptionProposal, 0));
        uint8 proposalId = uint8(Proposals.length) - 1;
        idProposals.push(proposalId);
        ProposalsById[proposalId] = _descriptionProposal;
        emit ProposalRegistered(proposalId);
    }

    function UsersVote(address _address, uint proposalId) external {
        RequireIsVoting();
        RequireUserRegistered(_whitelist[_address]);
        uint lenProposals = Proposals.length;
        require(proposalId < lenProposals, "This proposition doesn't exist");
        require(!_whitelist[_address].hasVoted, "This user has already voted");

        _whitelist[_address].hasVoted = true;
        Proposals[proposalId].voteCount += 1; 
        emit Voted(_address, proposalId);
    }

    function UsersGetWinningProposal() view external returns(uint, string memory, uint){
        require(CurrentStatus == WorkflowStatus.VotesTallied, "The vote is not tallied yet");
        require(!ExAequo, "There is no winning proposition, at least two are ex aequo");
        string memory winningProposal = Proposals[winningProposalId].description;
        uint count = Proposals[winningProposalId].voteCount;
        return(winningProposalId,winningProposal, count);
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