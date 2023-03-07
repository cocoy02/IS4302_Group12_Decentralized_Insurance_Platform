pragma solidity ^0.5.0;
import "./Insurance.sol";

contract InsuranceCompany {

    Insurance insuranceInstance;

    struct insuranceCompany {
        uint256 credit;
        string name;
        address owner;
        mapping(uint256 => Insurance) products;
        mapping(uint256 => Insurance) insuranceId;
        // uint256 completed;
        // uint256 created;
    }

    uint256 numOfCompany = 0;
    mapping(uint256 => insuranceCompany) public companies;

    event createInsurance (uint256 insuranceId);
    event autoTransfer (address beneficiary, uint256 amount);
    
    //function to create a new insurance company requires at least 0.01ETH to create
    function add(string memory name) public payable returns(uint256) {
        require(msg.value > 0.01 ether, "at least 0.01 ETH is needed to create a company");
        
        insuranceCompany memory newCompany = insuranceCompany(
            0,
            name,
            msg.sender
        );
        
        uint256 companyId = numOfCompany++;
        companies[Id] = newCompany; //commit to state variable
        return Id;   //return new Id
    }

    //modifier to ensure a function is callable only by its owner    
    modifier ownerOnly(uint256 companyId) {
        require(companies[companyId].owner == msg.sender);
        _;
    }
    
    modifier validCompanyId(uint256 companyId) {
        require(companyId < numOfCompanies);
        _;
    }

    //from insurance contract 
    function createInsurance() public payable ownerOnly(companyId) validCompanyId(companyId) {
        
    }

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
        if(insuranceInstance.getReason(insuranceId) == Insurance.reason.suicide) { // insurance need getreason and getvaliddate
            require(insuranceInstance.getDate(insuranceId)+ 2 years >= block.timestamp);
        }

        //insurance valid from date modifier

        uint256 value = insuranceInstance.getValue(insuranceId);
        insuranceCompany company = companies[companyId];
        require(company.owner.balance >= value,"not enough ether to pay");

        company.owner.send(value);
        
        address payable recipient = address(uint160(insuranceInstance.getBeneficiary(insuranceId)));
        recipient.transfer(value);  
        insuranceInstance.updatePaid(insuranceId);
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
