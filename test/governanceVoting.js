const { expect } = require('chai');
const { ethers } = require('hardhat');
const { bigToDecimal, decimalToBig } = require('./utils/helper');


const historyStatuses = {
      activeAt:    {id:"1"},
      succeededAt: {id:"2"},
      queueAt:     {id:"3"},
      executeAt:   {id:"4"}
}

describe('Governance voting test cases', function () {
  let gv, owner, user1, user2, user3, user4, restUsers;

  it('beforeAll', async function () {
    if (network.name != 'hardhat') {
      console.log('PLEASE USE --network hardhat');
      process.exit(0);
    }
    console.log('start');
    [owner, user1, user2, user3, user4, ...restUsers] = await ethers.getSigners();
    console.log('OWNER ', owner.address);
    const GovernanceVoting = await ethers.getContractFactory('GovernanceVoting');

    gv = await GovernanceVoting.deploy();
  });

  it('Create proposal', async function () {
    await gv.createProposal('My title at index 0', 'My description 0');
    await gv.createProposal('My title at index 1', 'My description 1');
    await gv.createProposal('My title at index 2', 'My description 2');
    let proposal = await gv.getProposal(owner.address);
    let totalProposals = await gv.totalProposals();
    console.log(proposal);
    console.log("totalProposals=>", totalProposals);
  });
  it('Update proposal & proposal status', async function () {
    await gv.updateProposal('Updated title 2', 'Updated description 2',owner.address,"2");
    
    let proposal = await gv.getProposal(owner.address);
    console.log("Updated Proposals=>",proposal);
    
    await gv.updateProposalStatus('Updated',owner.address,"1");
     proposal = await gv.getProposal(owner.address);
    console.log("Updated status=>",proposal);
  });

  it('Proposal history', async function () {
      let history = await gv.getProposalHistory('1');
      let history2 = await gv.getProposalHistory('2');
      console.log("history => ",history);
      console.log("history2 => ",history2);
      await gv.activateProposalHistory('1');
      history = await gv.getProposalHistory('1');
      console.log("======================== Activating =========================== ");
      console.log("history => ",history);

      await gv.successProposalHistory('1');
      history = await gv.getProposalHistory('1');
      console.log("======================== Success =========================== ");
      console.log("history => ",history);

    
  });

});


