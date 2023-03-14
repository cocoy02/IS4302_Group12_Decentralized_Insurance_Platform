pragma solidity ^0.5.0;
import "./Insurance.sol";
import "./Stakeholder.sol";
import "./MedicalCert.sol";

contract InsuranceCompany {

    Insurance insuranceInstance;
    Stakeholder stakeholderInstance;
    MedicalCert medicalCertInstance;

    struct insuranceCompany {
        uint256 credit;
        string name;
        address owner;
        uint256 completed; //number range to stars
        Insurance[] products;
        mapping(uint256 => Insurance) insuranceId;
        Request[] requests;
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
        reasonType reason,
        uint256 price
    ) public payable ownerOnly(companyId) validCompanyId(companyId) returns(uint256){
            uint256 newId = insuranceInstance.createInsurance(
                policyOwner,
                lifeAssured,
                payingAccount,
                msg.sender,
                insuredAmount,
                insType,
                issueDate,
                reason,
                price
            );
            emit create(newId);
            return newIn;
    }

    //price

    //yearly/monthly payment function
    // function payInsurance(){

    // }

    function addProduct(uint256 insuranceId,uint256 companyId,uint256 amount,insuranceType insType,reasonType reason,uint256 price) public payable ownerOnly(companyId) validCompanyId(companyId) {
        createInsurance(address(0),address(0),amount,insType,date(0),reason,price);
        insuranceCompany company = companies[companyId];
        Insurance insurance = insuranceInstance.getInsurance(insuranceId);
        company.products.push(insurance);
    }

    function passToStakeHolder(uint256 id,uint256 insuranceId){
        Stakeholder st = stakeholderInstance.getStakeholder(id);
        // add to st list
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
        requestLists.push(req);
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
    
    function autoTransfer(uint256 insuranceId,InsuranceCompany company,byte mcId) public payable ownerOnly(companyId) validCompanyId(companyId) {
        Insurance insurance = insuranceInstance.getInsurance(insuranceId);
        require(insuranceInstance.getPremiumStatus(insuranceId) == Insurance.premiumStatus.paid);
        //insurance valid from date 
        require(insuranceInstance.getIssueDate(insuranceId)+ 90 days >= block.timestamp);
        //cert if its suicide
        if(medicalCertInstance.getReason(insuranceId) == Insurance.reason.suicide) {  
            require(insuranceInstance.getIssueDate(insuranceId)+ 2 years >= block.timestamp);
        }

        uint256 value = insuranceInstance.getInsuredAmount(insuranceId);
        require(company.owner.balance >= value,"not enough token to pay");

        company.owner.send(value);
        
        address payable recipient = address(uint160(insuranceInstance.getBeneficiary(insuranceId)));
        recipient.transfer(value);  
        insuranceInstance.updateStatus(Insurance.claimStatus.claimed, insuranceId);
        emit transfer(recipient, value);
    }

    function getCredit(uint256 companyId) public view validCompanyId(companyId) returns (uint256) {
        return companies[companyId].credit;
    }
    
    function getOwner(uint256 companyId) public view validCompanyId(companyId) returns (address) {
        return companies[companyId].owner;
    }
}
