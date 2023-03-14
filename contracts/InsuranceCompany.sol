pragma solidity ^0.5.0;
import "./Insurance.sol";
import "./Stakeholder.sol";

contract InsuranceCompany {

    Insurance insuranceInstance;
    Stakeholder stakeholderInstance;

    struct insuranceCompany {
        uint256 credit;
        string name;
        address owner;
        uint256 completed; //number range to stars
        Insurance[] products;
        mapping(uint256 => Insurance) insuranceId;
        mapping(uint256 => Request) requestLists;
    }
    struct Request {
        address buyer;
        string insuType;
        string status; // {approved, rejected, pending}
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
            msg.sender,
            0
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
    // function payInsurance(){

    // }

    function addProduct(uint256 insuranceId,uint256 companyId,uint256 amount,insuranceType insType,reasonType reason) public payable ownerOnly(companyId) validCompanyId(companyId) {
        createInsurance(address(0),address(0),amount,insType,date(0),reason);
        insuranceCompany company = companies[companyId];
        Insurance insurance = insuranceInstance.getInsurance(insuranceId);
        company.products.push(insurance);
    }

    function passToStakeHolder(uint256 id){
        Stakeholder st = stakeholderInstance.getStakeholder(id);
        pass insurance id to stakeholder
    }

    // insurance need to have a insurance state(boolean) to indicate whether approved by beneficiary
    function signInsurance(uint256 insuranceId,uint256 companyId) public payable ownerOnly(companyId) validCompanyId(companyId) {
        insuranceCompany company = companies[companyId];
        Insurance insurance = insuranceInstance.getInsurance(insuranceId);
        require(insuranceInstance.getInsuranceState(insuranceId),"not approved by beneficiary!");
        company.insurance[insuranceId] = insurance;
        company.completed++;
        updateCredit(companyId);
    }

    function updateCredit(uint256 companyId) public validCompanyId(companyId) {
        InsuranceCompany company = companies[companyId];
        uint256 completed = company.completed;
        if(completed >=50 && completed <=200) {
            company.credit = 1;
        } else if(completed >200 && completed <=350) {
            company.credit = 2;
        } else if(completed >350 && completed <=450) {
            company.credit = 3;
        } else if(completed >450 && completed <=800) {
            company.credit = 4;
        } else if(completed >800 && completed <=2000) {
            company.credit = 5;
        } else if(completed >2000) {
            company.credit = 999;
        } 
    }

    function addRequestLists(address buyer, string memory _type) {
        Request req = new Request(buyer, _type, "Pending");
        requestLists[]
    }

    function checkRequests() public {
        // check the requests inside the request list
        require(msg.sender == Company);
        string memory insuType;
        uint256 _id;
        while (requestsID.length > 0) {
            _id = requestsID[requestsID.length-1];
            insuType = requests[_id].insuType;
            requestsID.pop();
            // whats the criteria for approval and rejection here
            if (keccak256(abi.encodePacked(insuType)) == keccak256(abi.encodePacked("life"))) {
                approve(_id);
            } else if (keccak256(abi.encodePacked(insuType)) == keccak256(abi.encodePacked("accident"))) {
                approve(_id);
            } else {
                reject(_id);
            }
        }
    }

    function approve(uint256 id) private {
        require(msg.sender == Company);
        requests[id].status = "approved";
    }

    function reject(uint256 id) private {
        require(msg.sender == Company);
        requests[id].status = "rejected";
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
        require(company.owner.balance >= value,"not enough token to pay");

        company.owner.send(value);
        
        address payable recipient = address(uint160(insuranceInstance.getBeneficiary(insuranceId)));
        recipient.transfer(value);  
        insuranceInstance.updateStatus(Insurance.premiumStatus.paid, insuranceId);
        emit transfer(recipient, value);
    }

    function getCredit(uint256 companyId) public view validCompanyId(companyId) returns (uint256) {
        return companies[companyId].credit;
    }
    
    function getOwner(uint256 companyId) public view validCompanyId(companyId) returns (address) {
        return companies[companyId].owner;
    }
}
