pragma solidity ^0.5.0;
import "./Insurance.sol";
import "./StakeHolder.sol";

contract InsuranceCompany {

    Insurance insuranceInstance;

    struct insuranceCompany {
        uint256 credit;
        string name;
        address owner;
        mapping(uint256 => Insurance) products;
        mapping(uint256 => Insurance) insuranceId;
        uint256 completed; //number range to stars
    }

    uint256 numOfCompany = 0;
    mapping(uint256 => insuranceCompany) public companies;

    event create (uint256 insuranceId);
    event transfer (address beneficiary, uint256 amount);
    
    //function to create a new insurance company requires at least 0.01ETH to create
    function add(string memory name) public payable returns(uint256) {
        require(msg.value > 0.01 ether, "at least 0.01 ETH is needed to create a company");
        
        insuranceCompany memory newCompany = insuranceCompany(
            0,
            name,
            msg.sender
        );
        
        uint256 companyId = numOfCompany++;
        companies[Id] = newCompany; 
        return Id; 
    }
 
    modifier ownerOnly(uint256 companyId) {
        require(companies[companyId].owner == msg.sender);
        _;
    }
    
    modifier validCompanyId(uint256 companyId) {
        require(companyId < numOfCompanies);
        _;
    }

    function createInsurance(Stakeholder policyOwner,
        Stakeholder lifeAssured,
        Stakeholder payingAccount,
        uint256 insuredAmount,
        insuranceType insType,
        uint256 issueDate,
        reasonType reason
    ) public payable ownerOnly(companyId) validCompanyId(companyId) returns(uint256){
            uint256 newId = insuranceInstance.createInsurance(
                policyOwner,
                lifeAssured,
                payingAccount,
                msg.sender,
                insuredAmount,
                insType,
                issueDate,
                reason
            );
            emit create(newId);
            return newIn;
    }

    //yearly/monthly payment function

    function addProduct(uint256 insuranceId,uint256 companyId) public payable ownerOnly(companyId) validCompanyId(companyId) {
        insuranceCompany company = companies[companyId];
        Insurance insurance = insuranceInstance.getInsurance(insuranceId);
        company.products[insuranceId] = insurance;
    }

    // insurance need to have a insurance state(boolean) to indicate whether approved by beneficiary
    function confirmInsurance(uint256 insuranceId,uint256 companyId) public payable ownerOnly(companyId) validCompanyId(companyId) {
        insuranceCompany company = companies[companyId];
        Insurance insurance = insuranceInstance.getInsurance(insuranceId);
        require(insuranceInstance.getInsuranceState(insuranceId),"not approved by beneficiary!");
        company.insurance[insuranceId] = insurance;
    }

    function autoTransfer(uint256 insuranceId,uint256 companyId) public payable ownerOnly(companyId) validCompanyId(companyId) {
        Insurance insurance = insuranceInstance.getInsurance(insuranceId);
        if(insuranceInstance.getReason(insuranceId) == Insurance.reason.suicide) { 
            require(insuranceInstance.getIssueDate(insuranceId)+ 2 years >= block.timestamp);
        }

        //insurance valid from date 
        require(insuranceInstance.getIssueDate(insuranceId)+ 90 days >= block.timestamp);

        uint256 value = insuranceInstance.getValue(insuranceId);
        insuranceCompany company = companies[companyId];
        require(company.owner.balance >= value,"not enough ether to pay");

        company.owner.send(value);
        
        address payable recipient = address(uint160(insuranceInstance.getBeneficiary(insuranceId)));
        recipient.transfer(value);  
        insuranceInstance.updateStatus(Insurance.premiumStatus.paid, insuranceId);
        emit transfer(recipient, value);
    }

    function addCredit(uint256 companyId) public view validCompanyId(companyId) returns (uint256) {
        //add credit rule
    }

    function getCredit(uint256 companyId) public view validCompanyId(companyId) returns (uint256) {
        return companies[companyId].credit;
    }
    
    function getOwner(uint256 companyId) public view validCompanyId(companyId) returns (address) {
        return companies[companyId].owner;
    }
}
