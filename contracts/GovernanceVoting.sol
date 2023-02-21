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

    uint256 public minimumVoteWeight = 1;
    uint256 public totalProposals = 0;
    address public owner;
    string public createdStatus = 'created';
    string public activeStatus = 'active';
    string public successStatus = 'succeeded';
    string public rejectedStatus = 'rejected';
    string public queuedStatus = 'queued';
    string public executedStatus = 'executed';

    struct proposalsObj {
        uint256 id;
        string title;
        string description;
        string activeUntil;
        string proposalType;
        string status;
        address userAddress;
    }

    struct historyObj {
        uint256 proposalId;
        uint256 createdAt;
        uint256 activeAt;
        uint256 succeededAt;
        uint256 rejectedAt;
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

    address[] public UserAddresses;
    mapping(address => proposalsObj[]) public proposalsMap; //proposals will be array because one use can create more then one proposals
    mapping(uint256 => historyObj) public historyMap; //uint will be the proposal id
    mapping(uint256 => votingObj) public votingMap; //uint will be the proposal id
    mapping(uint256 => weightageObj[]) public weightageMap; //proposals will be array because one use can create more then one proposals

    function inArray(address _address) public view returns (bool) {
        // address 0x0 is not valid if pos is 0 is not in the array
        if (proposalsMap[_address].length > 0) {
            return true;
        }
        return false;
    }

    function createProposal(
        string memory _title,
        string memory _description,
        string memory proposal_Type,
        string memory active_Until
    ) public returns (bool) {
        proposalsObj memory p;
        p.id = totalProposals;
        p.title = _title;
        p.description = _description;
        p.status = activeStatus;
        p.proposalType = proposal_Type;
        p.activeUntil = active_Until;
        p.userAddress = msg.sender;
        proposalsMap[msg.sender].push(p);

        //history
        historyMap[totalProposals].createdAt = block.timestamp;
        historyMap[totalProposals].activeAt = block.timestamp;
        historyMap[totalProposals].proposalId = totalProposals;

        //updating proposal id
        totalProposals++;
        UserAddresses.push(msg.sender);

        return true;
    }

    function updateProposal(
        string memory _title,
        string memory _description,
        string memory proposal_Type,
        string memory active_Until,
        address _address,
        uint256 _index
    ) public onlyOwner returns (bool) {
        require(proposalsMap[_address][_index].userAddress == _address, 'address not fount');
        proposalsMap[_address][_index].title = _title;
        proposalsMap[_address][_index].proposalType = proposal_Type;
        proposalsMap[_address][_index].activeUntil = active_Until;
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

        if (keccak256(abi.encodePacked(_status)) == keccak256(abi.encodePacked(activeStatus))) {
            historyMap[_index].activeAt = block.timestamp;
        } else if (keccak256(abi.encodePacked(_status)) == keccak256(abi.encodePacked(successStatus))) {
            historyMap[_index].succeededAt = block.timestamp;
        } else if (keccak256(abi.encodePacked(_status)) == keccak256(abi.encodePacked(rejectedStatus))) {
            historyMap[_index].rejectedAt = block.timestamp;
        } else if (keccak256(abi.encodePacked(_status)) == keccak256(abi.encodePacked(queuedStatus))) {
            historyMap[_index].queueAt = block.timestamp;
        } else if (keccak256(abi.encodePacked(_status)) == keccak256(abi.encodePacked(executedStatus))) {
            historyMap[_index].executeAt = block.timestamp;
        }

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

    function getWeightageMap(uint256 _proposalId) public view returns (weightageObj[] memory) {
        return weightageMap[_proposalId];
    }

    function getUserAddressLength() public view returns (uint256) {
        return UserAddresses.length;
    }

    function setMinWeightage(uint256 _weightage) public onlyOwner returns (bool) {
        minimumVoteWeight = _weightage;
        return true;
    }

    function getMinWeightage() public view returns (uint256) {
        return minimumVoteWeight;
    }
}
