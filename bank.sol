//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract Bank {
    
    mapping(address => uint) private balances;
    mapping(address => bool) private freezedAccounts;
    mapping(address => Loan) private loans;

    event Deposit(address indexed owner, uint amount);
    event Withdraw(address indexed owner, uint amount);
    event Transfer(address indexed from, address indexed to, uint amount);
    event LoanRequested(address indexed borrower, uint256 amount);
    event LoanApproved(address indexed borrower, uint256 amount);
    event LoanRepaid(address indexed borrower, uint256 amount);

    struct Loan {
        uint amount;
        bool approved;
        bool repaid;
    }

    modifier UnFreezed(){
        require(!freezedAccounts[msg.sender], "Sorry, your account is currently freezed");
        _;
    }
    function getBalance(address _address) public view returns(uint) {
        return balances[_address];
    } 
    function freeze() public{
        freezedAccounts[msg.sender] = true;
    }
    function unfreeze() public{
        freezedAccounts[msg.sender] = false;
    }
    function enoughBalance(address _address, uint _no) private view {
        uint balance = balances[_address];
        assert(balance >= _no);
    }
    function deposit(address _account, uint _number) public UnFreezed payable {
        require(_number>0, "Only positive amount can be deposited");
        balances[_account] += _number;
        emit Deposit(_account, _number);
    }

    function withdraw(address _account, uint _number) public UnFreezed payable {
        enoughBalance(_account,_number);
        balances[_account] -= _number;
        emit Withdraw(_account, _number);
    }

    function transfer(address _from, address _to, uint _number) public UnFreezed payable {
        enoughBalance(_from, _number);
        balances[_from] -= _number;
        balances[_to] += _number;
        emit Transfer(_from, _to, _number);
    }
    function requestLoan( address receiverAddress, uint amount) public UnFreezed {
        require(amount > 0, "Loan amount must be greater than zero");
        loans[receiverAddress] = Loan(amount, false, false);
        emit LoanRequested(receiverAddress, amount);
    }
    function approveLoan(address receiverAddress, address senderAddress) public UnFreezed {
        Loan storage loan = loans[receiverAddress];
        require(loan.amount > 0, "No loan requested");
        require(!loan.approved, "Loan already approved");
        if(balances[senderAddress]<=loan.amount){
            revert("Sorry, sender don't have enough funds to grant loan!");
        }
        loan.approved = true;
        balances[senderAddress] -= loan.amount;
        balances[receiverAddress] += loan.amount;
        emit LoanApproved(receiverAddress, loan.amount);
    }
    function repayLoan(address receiverAddress, address senderAddress, uint repayAmount) public payable UnFreezed {
        Loan storage loan = loans[receiverAddress];
        require(loan.approved, "Loan not approved");
        require(!loan.repaid, "Loan already repaid");
        require(repayAmount == loan.amount, "Incorrect repayment amount");
        if(balances[receiverAddress]<=loan.amount){
            revert("Sorry, Receiver don't have enough funds to repay the loan!");
        }
        loan.repaid = true;
        balances[receiverAddress] -= repayAmount;
        balances[senderAddress] += repayAmount;
        emit LoanRepaid(receiverAddress, repayAmount);
    }
    
}
