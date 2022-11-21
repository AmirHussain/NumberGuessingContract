// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import '@openzeppelin/contracts/access/Ownable.sol';
import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

// import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
// import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import './interfaces/ISwapRouter.sol';
import './Math.sol';
import 'hardhat/console.sol';

contract GovernanceVoting {
    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, 'Not authorized owner');
        _;
    }

    uint256 public totalProposals = 0;
    address public owner;

    struct proposalsObj {
        uint256 id;
        string title;
        string description;
        string status;
        address userAddress;
    }

    struct historyObj {
        uint256 proposalId;
        uint256 createdAt;
        uint256 activeAt;
        uint256 succeededAt;
        uint256 queueAt;
        uint256 executeAt;
    }

    struct votingObj {
        uint256 forr;
        uint256 against;
        uint256 abstain;
    }

    struct weightageObj {
        address userAddress;
        string statusAction;
        uint256 weightage;
    }

    address[] UserAddresses;
    mapping(address => proposalsObj[]) public proposalsMap; //proposals will be array because one use can create more then one proposals
    mapping(uint256 => historyObj) public historyMap; //uint will be the proposal id
    mapping(uint256 => votingObj) public votingMap; //uint will be the proposal id
    mapping(uint256 => weightageObj[]) public weightageMap; //proposals will be array because one use can create more then one proposals

    function inArray(address who) public view returns (bool) {
        // address 0x0 is not valid if pos is 0 is not in the array
        if (proposalsMap[who].length > 0) {
            return true;
        }
        return false;
    }

    function createProposal(string memory _title, string memory _description) public returns (bool) {
        proposalsObj memory p;
        p.id = totalProposals;
        p.title = _title;
        p.description = _description;
        p.status = 'created';
        p.userAddress = msg.sender;
        proposalsMap[msg.sender].push(p);

        //history
        historyMap[totalProposals].createdAt = block.timestamp;
        historyMap[totalProposals].proposalId = totalProposals;

        //updating proposal id
        totalProposals++;
        if (inArray(msg.sender) == false) {
            UserAddresses.push(msg.sender);
        }
        return true;
    }

    function updateProposal(
        string memory _title,
        string memory _description,
        address _address,
        uint256 _index
    ) public onlyOwner returns (bool) {
        require(proposalsMap[_address][_index].userAddress == _address, 'address not fount');
        proposalsMap[_address][_index].title = _title;
        proposalsMap[_address][_index].description = _description;
        return true;
    }

    function updateProposalStatus(
        string memory _status,
        address _address,
        uint256 _index
    ) public returns (bool) {
        // require(proposalsMap[_address][_index].userAddress == msg.sender, "address not fount");
        proposalsMap[_address][_index].status = _status;
        return true;
    }

    function getAllUserAddresses() public view returns (address[] memory) {
        return UserAddresses;
    }

    function getProposal(address _address) public view returns (proposalsObj[] memory) {
        return proposalsMap[_address];
    }

    function activateProposalHistory(uint256 _proposalId) public returns (bool) {
        historyMap[_proposalId].activeAt = block.timestamp;
        return true;
    }

    function successProposalHistory(uint256 _proposalId) public returns (bool) {
        historyMap[_proposalId].succeededAt = block.timestamp;
        return true;
    }

    function queueProposalHistory(uint256 _proposalId) public returns (bool) {
        historyMap[_proposalId].queueAt = block.timestamp;
        return true;
    }

    function executeProposalHistory(uint256 _proposalId) public returns (bool) {
        historyMap[_proposalId].executeAt = block.timestamp;
        return true;
    }

    function getProposalHistory(uint256 _proposalId) public view returns (historyObj memory) {
        return historyMap[_proposalId];
    }

    function voteFor(uint256 _proposalId, uint256 _weightage) public returns (bool) {
        votingMap[_proposalId].forr = votingMap[_proposalId].forr + _weightage;
        weightageObj memory w;
        w.userAddress = msg.sender;
        w.statusAction = 'for';
        w.weightage = _weightage;
        weightageMap[_proposalId].push(w);

        return true;
    }

    function voteAgainst(uint256 _proposalId, uint256 _weightage) public returns (bool) {
        votingMap[_proposalId].against = votingMap[_proposalId].against + _weightage;
        weightageObj memory w;
        w.userAddress = msg.sender;
        w.statusAction = 'against';
        w.weightage = _weightage;
        weightageMap[_proposalId].push(w);
        return true;
    }

    function voteAbstain(uint256 _proposalId, uint256 _weightage) public returns (bool) {
        votingMap[_proposalId].abstain = votingMap[_proposalId].abstain + _weightage;
        weightageObj memory w;
        w.userAddress = msg.sender;
        w.statusAction = 'abstain';
        w.weightage = _weightage;
        weightageMap[_proposalId].push(w);
        return true;
    }
}
