pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;
import "./Insurance.sol";
import "./Stakeholder.sol";
import "./MedicalCert.sol";
import "./TrustInsure.sol";

contract InsuranceCompany {

    Insurance insuranceInstance;
    Stakeholder stakeholderInstance;
    MedicalCertificate medicalCertInstance;
    TrustInsure trustinsureInstance;
    enum requestStatus {approved, rejected, pending}

    struct insuranceCompany {
        uint256 credit;
        string name;
        address owner;
        uint256 completed; //number range to stars
        mapping(uint256 => Insurance.insurance) insuranceId;
        Request[] requestLists;//!!!!!company only could have at most ten requests, they need to fast approve!!!!!!//
    }

    struct Request {
        uint256 reqId;
        uint256 buyerId;
        string productType;
        requestStatus status;
    }

    constructor(Insurance insuranceAddress, Stakeholder stakeholderAddress, 
    MedicalCertificate medicalCertInstanceAddress, TrustInsure trustinsureInstanceAddress) public {
        insuranceInstance = insuranceAddress;
        stakeholderInstance = stakeholderAddress;
        medicalCertInstance = medicalCertInstanceAddress;    
        trustinsureInstance = trustinsureInstanceAddress;   
    }

    uint256 numOfReq = 0;
    uint256 numOfCompany = 0;
    mapping(uint256 => insuranceCompany) public companies;
    

    event create (uint256 insuranceId);
    event transfer (address beneficiary, uint256 amount);
    event allRequests(uint256[] requestids,
        uint256[] buyerids,
        string[] buyercontacts,
        string[] producttypes,
        requestStatus[] statuses);
    event requestSolve(uint256 requestId);
    event requestReject(uint256 requestId);
    event passedToStakeholder();
    event checkRequest(requestStatus status);


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


    /**
    * @dev Company register
    * @return id of the company
    */
    function add(string memory name) public payable returns(uint256) {
        require(msg.value > 0.01 ether, "at least 0.01 ETH is needed to create a company");
        
        insuranceCompany memory newCompany = insuranceCompany({
            credit:0,
            name:name,
            owner:msg.sender,
            completed:0,
            requestLists: new Request[](0)
        });
        
        uint256 companyId = numOfCompany++;
        companies[companyId] = newCompany; 
        return companyId; 
    }
 
    /**
    * @dev Allow insurance company to create insurance. If it is a request, automatically delete the request. 
    * Automatically pass to stakeholder
    * @return new insurance id
    */
    function createInsurance(uint256 policyOwner,
        uint256  beneficiary,
        uint256 lifeAssured,
        uint256  payingAccount,
        uint256 insuredAmount,
        Insurance.insuranceType insType,
        uint256 issueDate,
        Insurance.reasonType reason,
        uint256 price,
        uint256 companyId,
        uint256 requestId
    ) public payable validCompanyId(companyId) returns(uint256){
            if (requestId != 0) {
                uint256 index;
                Request[] memory reqs = companies[companyId].requestLists;
                uint256 length = reqs.length;
                bool find = false;
                for (uint256 i = 0; i < length; i++) {
                    if (reqs[i].reqId == requestId) {
                        index = i;
                        find = true;
                    }
                }
                
                require(find == true, "Invalid request id!");
                if (find) {
                    companies[companyId].requestLists[index] = companies[companyId].requestLists[length - 1];
                    companies[companyId].requestLists.pop();
                    emit requestSolve(requestId);
                }
            }        
            uint256 newId = insuranceInstance.createInsurance(
                policyOwner,
                beneficiary,
                lifeAssured,
                payingAccount,
                companyId,
                insuredAmount,
                insType,
                issueDate,
                reason,
                price
            );
            emit create(newId);
            passToStakeHolder(policyOwner, newId);
            return newId;
    }

    //yearly/monthly payment function
    // function payInsurance(){

    // }

    /**
    * @dev Allow insurance company to pass drafted insurance to stakeholder
    */
    function passToStakeHolder(uint256 policyownerid,uint256 insuranceId) internal {
        //Stakeholder st = stakeholderInstance.getStakeholder(policyownerid);
        // add to st list
        if (stakeholderInstance.addToSignList(insuranceId, policyownerid)) emit passedToStakeholder();
    }

    /** 
    * @dev insurance need to have a insurance state(boolean) to indicate whether approved by beneficiary and add count for credit
    * @param {uint256} insuranceId, {uint256} companyId
    */
    function signInsurance(uint256 insuranceId,uint256 companyId) public payable ownerOnly(companyId) validCompanyId(companyId) {
        insuranceCompany storage company = companies[companyId];
        Insurance.insurance memory insurance = insuranceInstance.getInsurance(insuranceId);
        require(insuranceInstance.getInsuranceState(insuranceId),"not approved by beneficiary!");
        company.insuranceId[insuranceId] = insurance;
        company.completed++;
        updateCredit(companyId);
    }

    /** 
    * @dev function to update the credit of company once a insurance is signed
    * @param {uint256} companyId
    */
    function updateCredit(uint256 companyId) public validCompanyId(companyId) {
        insuranceCompany memory company = companies[companyId];
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

     /** 
    * @dev check stakeholder details and mc details, if correct auto transfer money
    * @param  {uint256} insuranceId, {uint256} companyId,{uint256} _hospitalId,{bytes32} mcId
    */
    function autoTransfer(uint256 insuranceId,uint256 companyId,uint256 _hospitalId,bytes memory mcId) public payable{
        // Insurance memory insurance = insuranceInstance.getInsurance(insuranceId);
        require(insuranceInstance.getPremiumStatus(insuranceId) == Insurance.premiumStatus.paid);
        //insurance valid from date 
        require(insuranceInstance.getIssueDate(insuranceId)+ 90 days >= block.timestamp);
        uint256 st = insuranceInstance.getBeneficiary(insuranceId);
        //get cert details
        (uint256 HospitalID,string memory name,string memory NRIC,uint256 sex,uint256 birthdate,string memory race,string memory nationality,MedicalCertificate.certCategory incident,string memory dateTimeIncident,string memory placeIncident,string memory causeIncident,string memory titleOfCertifier,string memory Institution) = medicalCertInstance.getMC(mcId);
        bytes32  mcName = keccak256(abi.encodePacked(name));
        bytes32  stName = keccak256(abi.encode(stakeholderInstance.getStakeholderName(st)));
        bytes32  mcNRIC = keccak256(abi.encode(NRIC));
        bytes32  stNRIC = keccak256(stakeholderInstance.getStakeholderNRIC(st));
        require(mcName == stName && mcNRIC ==  stNRIC, "Not the same stakeholder!");
        //cert if its suicide
        if(incident == MedicalCertificate.certCategory.suicide) {  
            require(insuranceInstance.getIssueDate(insuranceId)+ 2*365 days >= block.timestamp);
        }

        uint256 value = insuranceInstance.getInsuredAmount(insuranceId);
        insuranceCompany memory company = companies[companyId];

        address companyOwner  = address(company.owner);
        require(trustinsureInstance.checkInsure(companyOwner) >= value,"not enough token to pay");
        
        //// How to transfer here?
        //company.owner.send(value);
        
        address recipient = address(uint160(insuranceInstance.getBeneficiary(insuranceId)));
        trustinsureInstance.transferFromInsure(companyOwner, recipient, value);
        insuranceInstance.updateClaimStatus(Insurance.claimStatus.claimed, insuranceId);
        emit transfer(recipient, value);
    }

    /**
    * @dev Allow insurance market to update requests
    * @return bool whether added successfullly
    * @return numOfReq request id
    */
    function addRequestLists(uint256 _buyerId, uint256 _companyId, string calldata _typeProduct) external returns(bool, uint256) {
        Request memory req = Request(numOfReq++, _buyerId, _typeProduct, requestStatus.pending);
        companies[_companyId].requestLists.push(req);

        return (true, numOfReq);
    }

    /**
    * @dev Allow insurance company check all requests
    */
    function checkRequestsFromCompany(uint256 companyId) public validCompanyId(companyId) ownerOnly(companyId) {
        Request[] memory reqs = companies[companyId].requestLists;
        uint256[] memory requestids = new uint256[](reqs.length);
        uint256[] memory buyerids = new uint256[](reqs.length);
        string[] memory buyercontacts= new string[](reqs.length);
        string[] memory producttypes = new string[](reqs.length);
        requestStatus[] memory statuses = new requestStatus[](reqs.length);

        for(uint256 i = 0;i< reqs.length;i++) {
            requestids[i] = reqs[i].reqId;
            buyerids[i] = reqs[i].buyerId;
            buyercontacts[i] = stakeholderInstance.getStakeholderPhone(reqs[i].buyerId);
            producttypes[i] = reqs[i].productType;
            statuses[i] = reqs[i].status;
        }

        emit allRequests(requestids,
        buyerids,
        buyercontacts,
        producttypes,
        statuses);
        
    }
    
    /**
    * @dev Allow insurance company reject request
    */
    function reject(uint256 requestId,uint256 companyId) private {
        require(requestId != 0, "Input valid requestId!");

        uint256 index;
        Request[] memory reqs = companies[companyId].requestLists;
        uint256 length = reqs.length;
        bool find = false;
        for (uint256 i = 0; i < length; i++) {
            if (reqs[i].reqId == requestId) {
                index = i;
                find = true;
            }
        }
        
        require(find == true, "Invalid request id!");
        if (find) {
            reqs[index].status = requestStatus.rejected;
            emit requestReject(requestId);
        }

    }

    /**
    * @dev Allow stakeholder to check request status
    */
    function checkRequestsFromStakeholder(uint256 companyId, uint256 requestId) public returns (requestStatus) {
        require(requestId != 0, "Invalid request id!");

        uint256 index;
        Request[] memory reqs = companies[companyId].requestLists;
        uint256 length = reqs.length;
        bool find = false;
        for (uint256 i = 0; i < length; i++) {
            if (reqs[i].reqId == requestId) {
                index = i;
                find = true;
            }
        }
        
        require(find == true, "You haven't requested or the request has already been approved!");
        if (find) {
            emit checkRequest(reqs[index].status);
        }
        
        return reqs[index].status;
    }
    
// =====================================================================================
// getters
// =====================================================================================

    function getCredit(uint256 companyId) public view validCompanyId(companyId) returns (uint256) {
        return companies[companyId].credit;
    }

    function getName(uint256 companyId) public view validCompanyId(companyId) returns (string memory) {
        return companies[companyId].name;
    }
    
    function getOwner(uint256 companyId) public view validCompanyId(companyId) returns (address) {
        return companies[companyId].owner;
    }
    
    // function getCompanyById(uint256 companyId) public view validCompanyId(companyId) returns (insuranceCompany memory) {
    //     return companies[companyId];
    // }

    function getNumOfCompany() public view returns (uint256) {
        return numOfCompany;
    }

}
