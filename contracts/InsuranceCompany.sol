pragma solidity ^0.5.0;
import "./Insurance.sol";
import "./Stakeholder.sol";
import "./MedicalCert.sol";

contract InsuranceCompany {

    Insurance insuranceInstance;
    Stakeholder stakeholderInstance;
    MedicalCertificate medicalCertInstance;
    enum requestStatus {approved, rejected, pending}

    struct insuranceCompany {
        uint256 credit;
        string name;
        address owner;
        uint256 completed; //number range to stars
        mapping(uint256 => Insurance) insuranceId;
        Request[] requestLists;
    }

    struct Request {
        uint256 reqId;
        address buyer;
        uint256 productId;
        requestStatus status;
    }

    uint256 numOfReq = 0;
    uint256 numOfCompany = 0;
    mapping(uint256 => insuranceCompany) public companies;


    event create (uint256 insuranceId);
    event transfer (address beneficiary, uint256 amount);


// =====================================================================================
// modifiers
// =====================================================================================
   
    modifier ownerOnly(uint256 companyId) {
        require(companies[companyId].owner == msg.sender);
        _;
    }
    
    modifier validCompanyId(uint256 companyId) {
        require(companyId < numOfCompany);
        _;
    }

// =====================================================================================
// functions
// =====================================================================================


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
        companies[companyId] = newCompany; 
        return companyId; 
    }
 
    //function to call Insurance contract to create insurance
    function createInsurance(Stakeholder policyOwner,
        Stakeholder lifeAssured,
        Stakeholder payingAccount,
        uint256 insuredAmount,
        Insurance.insuranceType insType,
        uint256 issueDate,
        Insurance.reasonType reason,
        uint256 price
    ) public payable returns(uint256){
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
            return newId;
    }

    //yearly/monthly payment function
    // function payInsurance(){

    // }

    //function to pass the contract draft to stakeholder to sign
    function passToStakeHolder(uint256 id,uint256 insuranceId) public{
        Stakeholder st = stakeholderInstance.getStakeholder(id);
        // add to st list
        stakeholderInstance.addToSignList(insuranceId, id);
    }

    // insurance need to have a insurance state(boolean) to indicate whether approved by beneficiary
    function signInsurance(uint256 insuranceId,uint256 companyId) public payable ownerOnly(companyId) validCompanyId(companyId) {
        InsuranceCompany company = companies[companyId];
        Insurance insurance = insuranceInstance.getInsurance(insuranceId);
        require(insuranceInstance.getInsuranceState(insuranceId),"not approved by beneficiary!");
        company.insurance[insuranceId] = insurance;
        company.completed++;
        updateCredit(companyId);
    }

    //function to update the credit of company once a insurance is signed
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

    function autoTransfer(uint256 insuranceId,InsuranceCompany company,uint256 _hospitalId,bytes32 mcId) public payable{
        Insurance insurance = insuranceInstance.getInsurance(insuranceId);
        require(insuranceInstance.getPremiumStatus(insuranceId) == Insurance.premiumStatus.paid);
        //insurance valid from date 
        require(insuranceInstance.getIssueDate(insuranceId)+ 90 days >= block.timestamp);

        //check cert details

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

        
// =====================================================================================
// getters
// =====================================================================================

    function getCredit(uint256 companyId) public view validCompanyId(companyId) returns (uint256) {
        return companies[companyId].credit;
    }
    
    function getOwner(uint256 companyId) public view validCompanyId(companyId) returns (address) {
        return companies[companyId].owner;
    }
    
    function getCompanyById(uint256 companyId) public view validCompanyId(companyId) returns (InsuranceCompany) {
        return companies[companyId];
    }

    function getNumOfCompany() public view returns (uint256) {
        return numOfCompany;
    }

    function getProducts(uint256 companyId) public view validCompanyId(companyId) returns (Insurance[] memory) {
        return companies[companyId].products;
    }


// =====================================================================================
// Not finalized functions
// =====================================================================================

    //function to add request from market to request list
    function addRequestLists(address buyer, uint256 id) public {
        InsuranceCompany company = insuranceInstance.getInsuranceCompany(id);
        Request memory req = new Request(numOfReq++,buyer, id, "Pending");
        company.requestLists.push(req);
    }
    
    //function to check request in request list
    function checkRequests(uint256 companyId) public validCompanyId(companyId) returns(string memory){
        InsuranceCompany Company = companies[companyId];
        string memory reqs = "";
        require(msg.sender == Company);

        //print requests
        for(uint256 i = 0;i< Company.requestLists.length;i++){
            reqs = reqs + string(abi.encodePacked("Id: ", uint2str(Company.requestLists[i].reqId), ", Address: ", toString( Company.requestLists[i].buyer))) + Company.requestLists[i].status + "\n";
        }
        return reqs;
    }
    
    function approve(uint256 id,uint256 companyId) private {
        InsuranceCompany Company = companies[companyId];
        require(msg.sender == Company);
    }

    function reject(uint256 id,uint256 companyId) private {
        InsuranceCompany Company = companies[companyId];
        require(msg.sender == Company);
        Company.requestsLists[id].status = "rejected";
    }

    //function to add product to product array for market to display
    function addProduct(uint256 insuranceId,uint256 companyId,uint256 amount,Insurance.insuranceType insType,Insurance.reasonType reason,uint256 price) public payable ownerOnly(companyId) validCompanyId(companyId) {
        //date set default to current timing
        createInsurance(address(0),address(0),address(0),msg.sender,amount,insType,block.timestamp,reason,price);
        InsuranceCompany company = companies[companyId];
        Insurance insurance = insuranceInstance.getInsurance(insuranceId);
        company.products.push(insurance);
    }
   


// =====================================================================================
// Helper functions
// =====================================================================================

   
    function uint2str(uint _i) internal pure returns (string memory str) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint k = length;
        while (_i != 0) {
            k--;
            uint8 temp = (48 + uint8(_i % 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        str = string(bstr);
    }
    
    function toString(address _addr) internal pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(_addr)));
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(42);
        str[0] = '0';
        str[1] = 'x';
        for (uint i = 0; i < 20; i++) {
            str[2+i*2] = alphabet[uint(uint8(value[i + 12] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(value[i + 12] & 0x0f))];
        }
        return string(str);
    }

}
