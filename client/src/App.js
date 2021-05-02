import React, { Component } from "react";
import '../node_modules/bootstrap/dist/css/bootstrap.min.css';
import Button from 'react-bootstrap/Button';
import Form from 'react-bootstrap/Form';
import Card from 'react-bootstrap/Card';
import ListGroup from 'react-bootstrap/ListGroup';
import Table from 'react-bootstrap/Table';
import Voting from "./contracts/Voting.json";
import getWeb3 from "./getWeb3";
import "./App.css";

class App extends Component {
	  state = { 
	  web3: null, 
	  accounts: null, 
	  contract: null, 
	  Voting: null,
	  show : false, 
	  isOwner : false,
	  currentAccount:null,
	  adminAdress : null,
	  stateVote:0,
	  winnerProposal:'',
	  proposals: [],
	  addressVote:[],
	  proposalVote:[],
	  chosenProposal: ''
  };
  
  componentWillMount = async () => {
  //componentDidMount = async () => {
    try {
      // Récupérer le provider web3  
      const web3 = await getWeb3();
	  
      // Utiliser web3 pour récupérer les comptes de l’utilisateur (MetaMask dans notre cas) 
      const accounts = await web3.eth.getAccounts();

      // Récupérer l’instance du smart contract “Voting” avec web3 et les informations du déploiement du fichier (client/src/contracts/Whitelist.json)
      const networkId = await web3.eth.net.getId();
      const deployedNetwork = Voting.networks[networkId];
  
      const instance = new web3.eth.Contract(
        Voting.abi,
        deployedNetwork && deployedNetwork.address,
      );
	  				 
	  const adminAdress = await instance.methods.getOwner().call();
	  const adminAdressLower = adminAdress.toString().toLowerCase();
	  const userAdress = accounts[0].toString().toLowerCase();		
	  this.state.isOwner = adminAdressLower == userAdress;		
	  
      // Set web3, accounts, and contract to the state, and then proceed with an
      // example of interacting with the contract's methods.
      this.setState({ 
		web3, 
		accounts, 
		contract: instance,
		adminAdress : adminAdress,
		currentAccount: accounts[0]	},  
		this.runExample, 
		this.runInit);

		this.runExample();
		this.runInit();
		this.CheckOwnerWhenAccountChanged(userAdress);		
		
    } catch (error) {
      // Catch any errors for any of the above operations.
      alert(
        `Non-Ethereum browser detected. Can you please try to install MetaMask before starting.`,
      );
      console.error(error);
    }
  };   
  
  runExample = async () => {
    const { accounts, contract } = this.state;

    // store the current account
    this.setCurrentAccount();
	this.CheckIfOwner();
  };
	
  setCurrentAccount = async() => {
		
		await window.ethereum.on('accountsChanged', (accounts) => {

			//this.setState({ currentAccount: accounts[0] });			
			// this.currentUserAddress.value = this.state.currentAccount;	
					
			//this.currentUserAddress.value = accounts[0];	
			
			this.CheckOwnerWhenAccountChanged(accounts[0]);
		});
    };
   
  // Admin 
  runInit = async() => {
	  
    const { accounts, contract } = this.state;
	
	const countAdress = await contract.methods.getAddressCount().call();
		
	var Voting = [];
	
	for(let i = 0; i < countAdress; i++){
		const adress = await contract.methods.getAddress(i).call();
		Voting.push(adress);
	}
		
	contract.events.VoterRegistered({
	}, function(error, event){ console.log(event); })
	.on("connected", function(subscriptionId){
		console.log(subscriptionId);
	})
	.on('data', function(event){
		console.log('call event'); // same results as the optional callback above
	})
	.on('changed', function(event){
		// remove event from local database
	})
	.on('error', function(error, receipt) { // If the transaction was rejected by the network with a receipt, the second parameter will be the receipt.
		alert('error VoterRegistered');
	});
	
    // Mettre à jour le state 
    this.setState({ Voting: Voting });
	this.CheckIfOwner();
  }; 
  
  runVoteTalliedEnded = async(winnerProposal) => { 
	if(this.winner != null)
		this.winner.value = winnerProposal;
  }; 
  
  
  runVoteTallied = async() => {
   const { contract } = this.state;
  
    // // récupérer la proposition gagnante
   const winnerVote = await contract.methods.UsersGetWinningProposal().call();
   this.winner.value = winnerVote[1];
  }; 

   Voting = async() => {
     const { accounts, contract } = this.state;
     const address = this.address.value;
     //alert(address);
     // Interaction avec le smart contract pour ajouter un compte 
     await contract.methods.AdminVoteRegisterAdress(address).send({from: accounts[0]});
    
     this.runInit();
   }
  
  StopProposal = async() => {
     const { accounts, contract } = this.state;
    
	// // Interaction avec le smart contract 
	// // pour arrêter la possibilité de faire des propositions
     await contract.methods.AdminActions(2).send({from: accounts[0]});
    
     this.runInit();
   }
  
  StartProposal = async() => {
     const { accounts, contract } = this.state;
    
     // Interaction avec le smart contract 
	 // pour démarrer la possibilité de faire des propositions
     await contract.methods.AdminActions(1).send({from: accounts[0]});
    
     this.runInit();
   }
  
   StopVote = async() => {
     const { accounts, contract } = this.state;
    
	// Interaction avec le smart contract 
	// pour arrêter la possibilité de faire des propositions
     await contract.methods.AdminActions(4).send({from: accounts[0]});
    
     this.runInit();
   }
  
  StartVote = async() => {
     const { accounts, contract } = this.state;
    
    // // Interaction avec le smart contract 
	// // pour démarrer la possibilité de faire des propositions
     await contract.methods.AdminActions(3).send({from: accounts[0]});
    
     this.runInit();
   }
  
  Proposal = async() => {
	  
      const { accounts, contract } = this.state;
	  const userAddress = this.state.currentAccount;
	  const proposition = this.proposition.value;
     // // Interaction avec le smart contract pour ajouter un compte 
      await contract.methods.UsersProposalsRecord(proposition).send({from: userAddress});
      this.state.proposalVote[this.state.currentAccount] = true;
      this.runInit();
   }
  
   Vote = async(idPropositionVote, nameProposal) => {
	   	   
      const { accounts, contract } = this.state;
      const address = this.state.currentAccount;
	  // // //const idPropositionVote = this.idPropositionVote.value;
      const id = idPropositionVote;
      // // // Interaction avec le smart contract pour ajouter un compte 
      await contract.methods.UsersVote(id).send({from: address});
      this.state.addressVote[address]= true;
	  this.state.chosenProposal = nameProposal;
      this.runInit();
   }
  
   VotesTallied = async() => {   
	 const { accounts, contract } = this.state;  
     // Interaction avec le smart contract pour décompter les votes 
     await contract.methods.AdminActions(5).send({from: accounts[0]});
     
	 this.runVoteTallied();
   } 
   
   RegisterAddress = async() => {    
      //const { accounts, contract } = this.state;  
      // Interaction avec le smart contract pour décompter les votes 
    //  await contract.methods.AdminActions(0).send({from: accounts[0]});
	 
	 this.state.show = true;
	 this.runInit();
   } 
   
   handleOptionChange = async(changeEvent) => {
	   this.setState({
		 selectedOption: changeEvent.target.value
	   });
	   	   
	   const { accounts, contract } = this.state;  
	   // Interaction avec le smart contract pour décompter les votes 
	   await contract.methods.AdminActions(changeEvent.target.value).send({from: accounts[0]});
	   
	   this.CheckOwnerWhenAccountChanged(accounts[0]);	  
  }
  
  chooseAdminAction = async() => {
	   var stateVote = this.state.stateVote;
	   stateVote++;
	   //alert(stateVote);
	   const { accounts, contract } = this.state;  
	   // Interaction avec le smart contract pour décompter les votes 
	   await contract.methods.AdminActions(stateVote).send({from: accounts[0]});
	   
	   this.CheckOwnerWhenAccountChanged(accounts[0]);	  
  }
  
  getProposals = async() => {    
    const { accounts, contract } = this.state;  
    // Interaction avec le smart contract pour décompter les votes 	
	
	const length = await contract.methods.getProposalsByIdLength().call();
	
	for (let i = 0; i < length; i++) {
		const proposal = await contract.methods.getProposalsById(i).call(); 
		
		this.state.proposals[i]={id:i,name:proposal};
		var prop = this.state.proposals[i];
	}			
	 
	 this.runInit();
   } 
   
   getOneProposal = async(idProposal) =>{
	 const { accounts, contract } = this.state;  
	 return await contract.methods.getProposalsById(idProposal).call();
   }
   
   CheckIfOwner = async() =>{
	  	  
		const { contract, isOwner} = this.state;  
		
		const adminAdress = await contract.methods.getOwner().call();
		const adminAdressLower = adminAdress.toString().toLowerCase();
		const userAdress = this.state.currentAccount.toString().toLowerCase();		
		this.state.isOwner = adminAdressLower == userAdress;	   
   }
   
   CheckOwnerWhenAccountChanged = async(userAdress) =>{
	    //alert(userAdress);
		const { contract, isOwner} = this.state;  
	    
		const adminAdress = await contract.methods.getOwner().call();
		
		const countAdress = await contract.methods.getAddressCount().call();
		
		var Voting = []; 
		
		for(let i = 0; i < countAdress; i++){
			const adress = await contract.methods.getAddress(i).call();
			Voting.push(adress);
		}
		
		var stateVote = await contract.methods.getCurrentStatus().call();
		
		const adminAdressLower = adminAdress.toString().toLowerCase();
		userAdress = userAdress.toString().toLowerCase();
		
		this.state.isOwner = adminAdressLower == userAdress;
		var winnerProposal = '';
						
		if(stateVote == 3){
			this.getProposals();
		}
		
		// décompte du vote
		if(stateVote == 5){
			const winnerVote = await contract.methods.UsersGetWinningProposal().call();
			
			winnerProposal = winnerVote[1];			
		}
		
		this.setState({ 
			isOwner: adminAdressLower == userAdress, 
			Voting: Voting,
			currentAccount:userAdress,
			stateVote : stateVote,	
			winnerProposal: winnerProposal
		});	
		
        if(stateVote == 5)				
			this.runVoteTalliedEnded(winnerProposal);

		this.runExample();
		this.runInit();			
   }
   
   actionAdmin(name) {
	 return (
		<div>
			<h2 className="text-center">Système de vote</h2>
			<hr></hr>
			<br></br>
			<Button onClick={ this.chooseAdminAction } variant="dark" > {name} </Button>
		</div>
	 );
   }
   
   choicesAdmin() {
	 return (		
		<div className="App">
				<div>
					<h2 className="text-center">Système de vote</h2>
					<hr></hr>
					<br></br>
				</div>
				<div id="admin">	  
					<div className="radio">
					  <label>
						<input type="radio" value="0" 
									  checked={this.state.selectedOption === '0'} 
									  onChange={this.handleOptionChange} />
						 Enregistrement des adresses
					  </label>
					</div>
					<div className="radio">
					  <label>
						<input type="radio" value="1" 
									  checked={this.state.selectedOption === '1'} 
									  onChange={this.handleOptionChange} />
						Début proposition
					  </label>
					</div>
					<div className="radio">
					  <label>
						<input type="radio" value="2" 
									  checked={this.state.selectedOption === '2'} 
									  onChange={this.handleOptionChange} />
						Fin de proposition
					  </label>
					</div>
					<div className="radio">
					  <label>
						<input type="radio" value="3" 
									  checked={this.state.selectedOption === '3'} 
									  onChange={this.handleOptionChange} />
						Début du vote
					  </label>
					</div>
					<div className="radio">
					  <label>
						<input type="radio" value="4" 
									  checked={this.state.selectedOption === '4'} 
									  onChange={this.handleOptionChange} />
						Fin du vote
					  </label>
					</div>
					<div className="radio">
					  <label>
						<input type="radio" value="5" 
									  checked={this.state.selectedOption === '5'} 
									  onChange={this.handleOptionChange} />
						Dépouillement 
					  </label>
					</div>					
				</div>
			</div>
	 )
   }
   
   showWinner(){
	 return(
		<div style={{display: 'flex', justifyContent: 'center'}}>
		   <Card style={{ width: '50rem' }}>
			 <Card.Header><strong>Vote Results</strong></Card.Header>
			 <Card.Body>
			   <Form.Group controlId="formAddress">
				 { this.state.winnerProposal}
			   </Form.Group>              
			 </Card.Body>
		   </Card>
		 </div>
	   
	   );
   }
   
   showAdresses(){
	   const { Voting } = this.state;
	   return (
			<div style={{display: 'flex', justifyContent: 'center'}}>
			  <Card style={{ width: '50rem' }}>
				<Card.Header><strong>Liste des comptes autorisés</strong></Card.Header>
				<Card.Body>
				  <ListGroup variant="flush">
					<ListGroup.Item>
					  <Table striped bordered hover>
						<thead>
						  <tr>
							<th>@</th>
						  </tr>
						</thead>
						<tbody>
						  {
							Voting !== null && 
							Voting.map((a) => <tr><td>{a}</td></tr>)
						  }
						</tbody>
					  </Table>
					</ListGroup.Item>
				  </ListGroup>
				</Card.Body>
			  </Card>
			</div>
		);
   }
   
   setAdresses(){
	 const { Voting } = this.state;
	 return (
		<div>
			<div style={{display: 'flex', justifyContent: 'center'}}>
			  <Card style={{ width: '50rem' }}>
				<Card.Header><strong>Authorized accounts</strong></Card.Header>
				<Card.Body>
				  <ListGroup variant="flush">
					<ListGroup.Item>
					  <Table striped bordered hover>
						<thead>
						  <tr>
							<th>@</th>
						  </tr>
						</thead>
						<tbody>
						  {
							Voting !== null && 
							Voting.map((a) => <tr><td>{a}</td></tr>)
						  }
						</tbody>
					  </Table>
					</ListGroup.Item>
				  </ListGroup>
				</Card.Body>
			  </Card>
			</div>
			<br></br>
			<div style={{display: 'flex', justifyContent: 'center'}}>
			  <Card style={{ width: '50rem' }}>
				<Card.Header><strong>Autoriser un nouveau compte</strong></Card.Header>
				<Card.Body>
				  <Form.Group controlId="formAddress">
					<Form.Control type="text" id="address"
					ref={(input) => { this.address = input }}
					/>
				  </Form.Group>
				  <Button onClick={ this.Voting } variant="dark" > Autoriser </Button>
				</Card.Body>
			  </Card>
			</div>
		</div>
	 );
   }

  render() {
    const { Voting } = this.state;
	
    if (!this.state.web3) {	  
      return <div>Loading Web3, accounts, and contract...</div>;
    } 
	
	var isWhitelisted = false;
	if(!this.state.isOwner && this.state.Voting != null &&  this.state.Voting.length > 0) { 
		const currentAdressToLower = this.state.currentAccount.toString().toLowerCase();
		
		const whitelists = this.state.Voting.map((whitelist) =>
		{
			if(whitelist.toString().toLowerCase() === currentAdressToLower)
				isWhitelisted = true; 			
		});		
		
   }
   
   if(isWhitelisted){
	   // en attente d'ouverture des propositions
	   if(this.state.stateVote == 0) return (
			<div style={{display: 'flex', justifyContent: 'center'}}>
			  <Card style={{ width: '50rem' }}>
				 <Card.Header><strong>The proposal session is not started yet</strong></Card.Header>
			  </Card>
			</div>
	   );
	   
	   if(this.state.stateVote == 1){
		   
		   // si l'utilisateur vient de faire une proposition
		   if(this.state.proposalVote[this.state.currentAccount]){
				return(
					<div style={{display: 'flex', justifyContent: 'center'}}>
					<Card style={{ width: '50rem' }}>
					
					<Card.Body>
					  <Form.Group>
						 Your proposition was sent to the blockchain
					   </Form.Group> 
					   <Form.Group>
						 { this.proposition.value}
					   </Form.Group>              
					</Card.Body>
			   </Card>
			 </div>
				);
		   }
		   
		   return(
			 <div style={{display: 'flex', justifyContent: 'center'}}>
				   <Card style={{ width: '50rem' }}>
					 <Card.Header><strong>The proposal session is opened</strong></Card.Header>
					 <Card.Body>
					   <Form.Group controlId="formAddress">					
						 Proposition : 
						 <Form.Control type="text" id="proposition"
						 ref={(input) => { this.proposition = input }}
						 />
					   </Form.Group>
					   <Button onClick={ this.Proposal } variant="dark" > Add </Button>
					 </Card.Body>
				   </Card>
				 </div>
			);
	   }
	   
	   // proposition finie en attente d'ouverture du vote
	   if(this.state.stateVote == 2) return (
			<div style={{display: 'flex', justifyContent: 'center'}}>
			  <Card style={{ width: '50rem' }}>
				 <Card.Header><strong>The vote session is not started yet</strong></Card.Header>
			  </Card>
			</div>
	   );
	   
	   // vote des propositions
	   if(this.state.stateVote == 3){
		   // si a déjà voté message
		   if(this.state.addressVote[this.state.currentAccount]){
				return(
					<div style={{display: 'flex', justifyContent: 'center'}}>
					<Card style={{ width: '50rem' }}>
					
					<Card.Body>
					  <Form.Group>
						 Your vote was sent to the blockchain
					   </Form.Group> 
					   <Form.Group>
						 { this.state.chosenProposal}
					   </Form.Group>              
					</Card.Body>
			   </Card>
			 </div>
				);
		   }
		   return (
			  <div style={{display: 'flex', justifyContent: 'center'}}>
				  <Card style={{ width: '50rem' }}>
					 <Card.Header><strong>Vote</strong></Card.Header>
					 <Card.Body>
					   <Table striped bordered hover>
						<thead>
						  <tr>
							<th>Propositions</th>
						  </tr>
						</thead>
						<tbody>
						  {
							this.state.proposals !== null && 
							this.state.proposals.map((a) => 
							<tr>
								<td>{a.name}</td>
								<td><Button onClick={() => this.Vote(a.id, a.name)} variant="dark" > Envoyer </Button></td>
							</tr>)
							
						  }
						</tbody>
					  </Table>					   
					   
				 </Card.Body>
			   </Card>
			 </div>
		   );
	   }
	   if(this.state.stateVote == 4) return "Waiting for vote Tallied";
	   if(this.state.stateVote == 5){		   
		   return (this.showWinner());
	   }
   }
   
   if(this.state.isOwner && this.state.Voting != null) {	   
	   var setAdresses = "";
	   var winner = "";
	   var actionAdmin = "";
	   
		if(this.state.stateVote == 0)
			actionAdmin = this.actionAdmin("Start proposals");
		
		if(this.state.stateVote == 1)
			actionAdmin = this.actionAdmin("End proposal");
			
		if(this.state.stateVote == 2)
			actionAdmin = this.actionAdmin("Start vote");
		
		if(this.state.stateVote == 3)
			actionAdmin = this.actionAdmin("End vote");
		
		if(this.state.stateVote == 4)
			actionAdmin = this.actionAdmin("Vote tallied");
	   
	    if(this.state.stateVote == 0) setAdresses = this.setAdresses();
	    if(this.state.stateVote > 0) setAdresses = this.showAdresses();
	    if(this.state.stateVote == 5) winner = this.showWinner();
		
		return (
		<div className="App">
		  <div>{actionAdmin}</div>
		  <br />
		  <div>{setAdresses}</div>
		  <div>{winner}</div>
		</div>
	);	
   }
   
   
   
   return "You are not whitelisted!";
  }
}

export default App;