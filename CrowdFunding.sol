// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.5;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";
 
contract CrowdFunding {
    using SafeMath for uint256; 
    
    address public admin;
    uint256 public noOfContributors;
    uint256 public minimumContribution;
    uint256 public deadline; //timestamp
    uint256 public goal;
    uint256 public raisedAmount;
    uint256 public numRequests;  

    event ContributeEvent(address _sender, uint256 _value);
    event CreateRequestEvent(string _description, address _recipient, uint256 _value);
    event MakePaymentEvent(address _recipient, uint256 _value);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can execute this");
        _;
    }

    // Spending Request
    struct Request {
        string description;
        address payable recipient;
        uint256 value;
        uint256 noOfVoters;
        bool completed;
        mapping(address => bool) voters;
    }
    
    // mapping of spending requests
    // the key is the spending request number (index) - starts from zero
    // the value is a Request struct
    mapping(uint256 => Request) public requests;
    mapping(address => uint256) public contributors;
    
    constructor(uint256 _goal, uint256 _deadline) {
        goal = _goal;
        deadline = block.timestamp.add(_deadline);
        admin = msg.sender;
        minimumContribution = 100 wei;
    }
    
    function contribute() public payable {
        require(block.timestamp < deadline, "The Deadline has passed!");
        require(msg.value >= minimumContribution, "The Minimum Contribution not met!");
        
        // incrementing the no. of contributors the first time when 
        // someone sends eth to the contract
        if(contributors[msg.sender] == 0) {
            noOfContributors;
        }
        
        contributors[msg.sender].add(msg.value);
        raisedAmount.add(msg.value);
        
        emit ContributeEvent(msg.sender, msg.value);
    }
    
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    // a contributor can get a refund if goal was not reached within the deadline
    function getRefund() public {
        require(block.timestamp > deadline, "Deadline has not passed");
        require(raisedAmount < goal, "The goal was met");
        require(contributors[msg.sender] > 0);
        
        address payable recipient = payable(msg.sender);
        uint256 value = contributors[msg.sender];

        recipient.transfer(value);

        contributors[msg.sender] = 0;
    }
    
    function createRequest(string calldata _description, address payable _recipient, uint256 _value) public onlyAdmin {
        //numRequests starts from zero
        Request storage newRequest = requests[numRequests];
        numRequests.add(1);
        
        newRequest.description = _description;
        newRequest.recipient = _recipient;
        newRequest.value = _value;
        newRequest.completed = false;
        newRequest.noOfVoters = 0;
        
        emit CreateRequestEvent(_description, _recipient, _value);
    }
    
    function voteRequest(uint256 _requestNo) public {
        require(contributors[msg.sender] > 0, "You must be a contributor to vote!");
        
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.voters[msg.sender] == false, "You have already voted!");
        
        thisRequest.voters[msg.sender] = true;
        thisRequest.noOfVoters.add(1);
    }
    
    function makePayment(uint256 _requestNo) public onlyAdmin {
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.completed == false, "The request has been already completed!");
        
        require(thisRequest.noOfVoters > noOfContributors.div(2), "The request needs more than 50% of the contributors.");
        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed = true;
        
        emit MakePaymentEvent(thisRequest.recipient, thisRequest.value);
    }
}
