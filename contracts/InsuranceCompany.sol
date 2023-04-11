pragma solidity ^0.8.12;
pragma experimental ABIEncoderV2;
import "./Insurance.sol";
import "./Hospital.sol";
import "./TrustInsure.sol";

contract InsuranceCompany is Insurance {
    TrustInsure trustinsureInstance;
    Hospital hospitalInstance;
    enum requestStatus {approved, rejected, pending}

    struct insuranceCompany {
        uint256 companyId;
        uint256 credit;
        string name;
        address owner;
        uint256 completed; //number range to stars
        mapping(uint256 => insurance) insuranceIds;
        Request[] requestLists;
    }

    struct Request {
        uint256 reqId;
        uint256 buyerId;
        string contact;
        string productType;
        requestStatus status;
        uint256 insuranceId;
    }

    constructor(Hospital hospitalInstanceAddress, 
                TrustInsure trustinsureInstanceAddress) 
    public 
    {
        hospitalInstance = hospitalInstanceAddress;  
        trustinsureInstance = trustinsureInstanceAddress;    
    }

    uint256 numOfReq = 0;
    uint256 numOfCompany = 0;
    mapping(uint256 => insuranceCompany) public companies;
    mapping(address => uint256) public ids;
    

    event create (uint256 insuranceId);
    event transfer (address beneficiary, uint256 amount);
    event allRequests(uint256[] requestids,
        uint256[] buyerids,
        string[] buyercontacts,
        string[] producttypes);
    event requestSolve(uint256 requestId,uint256 insuranceId);
    event requestReject(uint256 requestId);
    event checkRequest(requestStatus status);
    event allPaid(uint256 insuranceID);
    event askingCert (uint256 insuranceID);
    event claimingFromComp (uint256 insuranceID, uint256 mcId);


// =====================================================================================
// modifiers
// =====================================================================================
   
    modifier ownerOnly(uint256 companyId) {
        require(companies[companyId].owner == msg.sender, "You are not the owner!");
        _;
    }
    
    modifier validCompanyId(uint256 companyId) {
        require(companyId <= numOfCompany && companyId != 0, "Invalid company id!");
        _;
    }

    modifier validBeneficiary(uint256 insuranceId, uint256 beneficiaryID) {
        require(stakeholderinfos[insurances[insuranceId].stakeholders].beneficiary == beneficiaryID, "Invalid beneficiary!");
        _;
    }

    modifier validPolicyOwner(uint256 insuranceId, uint256 policyOwnerID) {
        require(stakeholderinfos[insurances[insuranceId].stakeholders].policyOwner == policyOwnerID, "Invalid policy owner!");
        _;
    }

    modifier onlyCompanyOwner() {
        require(ids[msg.sender] != 0, "You are not authorized!");
        _;
    }

// =====================================================================================
// functions
// =====================================================================================


    /**
    * @dev Register an insurance company
    * @param name (string): the name of the new insurance company
    * @return uint256 id of the company
    */
    function registerCompany(string memory name) public payable returns(uint256) {
        require(msg.value > 0.01 ether, "at least 0.01 ETH is needed to create a company");
        
        numOfCompany++;
        insuranceCompany storage newCompany = companies[numOfCompany];
        
        newCompany.companyId = numOfCompany;
        newCompany.credit = 0;
        newCompany.name = name;
        newCompany.owner = msg.sender;
        newCompany.completed = 0;

        ids[msg.sender] = numOfCompany;
        
        return numOfCompany; 
    }

    /**
    * @dev Create related stakeholders profile for the insurance
    * @param policyOwner the id of the stakeholder who want to purchase the insurance policy
    * @param beneficiary the id of the stakeholder who will be benefited when the insurance is claimed
    * @param lifeAssured the id of the stakeholder being assured
    * @param payingAccount the id of the stakeholder who will receive the payment
    * @return uint256 number of stakeholder
    */
    function createStakeholderInfo (uint256 policyOwner,
        uint256  beneficiary,
        uint256 lifeAssured,
        uint256 payingAccount) 
    public onlyCompanyOwner
    override returns(uint256) 
    {
        numStakeholder++;
        stakeholderInfo storage newInfo = stakeholderinfos[numStakeholder];
        
        newInfo.policyOwner = policyOwner;
        newInfo.beneficiary = beneficiary;
        newInfo.lifeAssured = lifeAssured;
        newInfo.payingAccount = payingAccount;
        
        return numStakeholder;
    }

    /**
    * @dev Create the insurance
    * @param stakeholderInfoId the id of the stakeholder info that created before
    * @param companyId the id of the company
    * @param premium the total amount of premium fee that stakeholder should pay before claim
    * @param insuredAmount the total amount of payment when the insurnace is claimed
    * @param insType0life1accident the type of insurance, 0 for life or 1 for accident insurance
    * @param issueDateYYYYMMDD The date of the insurance being created
    * @param expiryDateYYYYMMDD The date of the insurance will be expired
    * @return uint256 insurance id
    */
    function createInsurance (
        uint256 stakeholderInfoId,
        uint256 companyId,
        uint256 premium,
        uint256 insuredAmount,
        Insurance.insuranceType insType0life1accident,
        uint256 issueDateYYYYMMDD,
        uint256 expiryDateYYYYMMDD
    ) 
    public validCompanyId(companyId) ownerOnly(companyId)
    override returns(uint256) 
    {
        require(trustinsureInstance.checkInsure(msg.sender) > 1, "1 TrustInsure is needed to create a new insurance"); 
        require(issueDateYYYYMMDD > 10000000, "Invalid issue date!");
        require(expiryDateYYYYMMDD > 10000000, "Invalid expiry date!");
        require(issueDateYYYYMMDD < expiryDateYYYYMMDD, "Invalid expiry date!");
        numInsurance++;
        //new insurance object
        insurance storage newInsurance = insurances[numInsurance];
        newInsurance.stakeholders = stakeholderInfoId;
        newInsurance.companyId = companyId;
        newInsurance.premium = premium;
        newInsurance.insuredAmount = insuredAmount;
        newInsurance.currentAmount = 0;
        newInsurance.insType = insType0life1accident;
        newInsurance.status = status.unapproved; // initialise  status to unapproved
        newInsurance.issueDate = issueDateYYYYMMDD;
        newInsurance.expiryDate = expiryDateYYYYMMDD; 
        
        return numInsurance;   //return new insurance Id
    }

    /**
    * @dev Update request status and related insurance information
    * @param companyId the id of the company
    * @param requestId which request the company want to update and address
    * @param insuranceId the id of the insurance that the company created specific for the request
    */
    function solveRequest(uint256 companyId, uint256 requestId, uint256 insuranceId) 
    public  onlyCompanyOwner
    {
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
                companies[companyId].requestLists[index].insuranceId = insuranceId;
                companies[companyId].requestLists[index].status = requestStatus.approved;
                emit requestSolve(requestId, insuranceId);
            }
        }        
    }

    /** 
    * @dev Allow the policyowner to verify the insurance contract information and sign
    * @param insuranceId the id of the insurance
    * @param companyId the id of the company
    * @param policyOwnerID the id of the policy owner
    */
    //stakeholder call this function to sign the insurance
    function signInsurance(uint256 insuranceId,uint256 companyId, uint256 policyOwnerID) 
    external
    validCompanyId(companyId) validPolicyOwner(insuranceId, policyOwnerID)
    {
        insurances[insuranceId].status = Insurance.status.processing;

        companies[companyId].insuranceIds[insuranceId] = insurances[insuranceId];
        companies[companyId].completed++;
        updateCredit(companyId);
    }

    /** 
    * @dev function to update the credit of company once a insurance is signed
    * @param companyId the id of the company
    */
    function updateCredit(uint256 companyId) private validCompanyId(companyId) {
        insuranceCompany storage company = companies[companyId];
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
    * @dev Allow the policy owner to pay the premium
    * @param insuranceId the id of the insurance
    * @param amount the id of the insurance
    * @param policyOwnerID the id of the policy owner
    * @param policyOwner the address of policyowner
    */
    function payPremium(uint256 insuranceId, uint256 amount, uint256 policyOwnerID, address policyOwner) external validPolicyOwner(insuranceId, policyOwnerID){
        address companyAddress = companies[insurances[insuranceId].companyId].owner;
        trustinsureInstance.transferFromInsure(policyOwner,companyAddress,amount);

        //mark as paid      
        insurances[insuranceId].currentAmount += amount;
        if (insurances[insuranceId].currentAmount == insurances[insuranceId].premium) {
            insurances[insuranceId].status = status.paid;
        }
        
        emit allPaid(insuranceId);
    }

    /** 
    * @dev Claim insurance
    * @param insuranceID the id of the insurance
    * @param companyId the id of the company
    * @param mcId the id of the medical certificate
    * @param beneficiaryID the id of beneficiary
    * @param beneficiaryAddress the address of beneficiary
    * @param name the name of the life assured
    * @param NRIC the NRIC of the life assured
    */
    function claim(uint256 insuranceID,uint256 companyId, 
    uint256 mcId,uint256 beneficiaryID,
    address beneficiaryAddress,
    string memory name, string memory NRIC) 
    external validBeneficiary(insuranceID, beneficiaryID)
    {
        //step1: ask for cert from hospital
        emit askingCert(insuranceID);

        //step2: tell insurance company to pay back
        autoTransfer(insuranceID, companyId, mcId, beneficiaryAddress, name, NRIC);
        emit claimingFromComp(insuranceID,mcId);
    }

    //  /** 
    // * @dev check stakeholder details and mc details, if correct auto transfer money
    // * @param  {uint256} insuranceId, {uint256} companyId,{uint256} _hospitalId,{bytes} mcId
    // */
    function autoTransfer(uint256 insuranceId,uint256 companyId,uint256 mcId,
    address beneficiaryAddress,string memory name, string memory NRIC) private {
        // Insurance memory insurance = insuranceInstance.getInsurance(insuranceId);
        require(insurances[insuranceId].status == Insurance.status.paid, "Stakeholder haven't paid the insurance!");
        //insurance valid from date 
        require(insurances[insuranceId].issueDate * 100 + 90 days >= block.timestamp, "Haven't take effect!");

        require(keccak256(abi.encodePacked(hospitalInstance.getMCName(mcId))) == keccak256(abi.encodePacked(name)) && 
        keccak256(abi.encodePacked(hospitalInstance.getMCNRIC(mcId))) ==  keccak256(abi.encodePacked(NRIC)), 
        "Invalid life assured name and NRIC!");
        //cert if its suicide
        if(hospitalInstance.getMCCategory(mcId) == MedicalCertificate.certCategory.suicide) {  
            require(insurances[insuranceId].issueDate * 100 + 2*365 days >= block.timestamp, "If suicide cannot claim within 2 years!");
        }

        uint256 value = insurances[insuranceId].insuredAmount;
        insuranceCompany storage company = companies[companyId];

        address companyOwner  = address(company.owner);
        require(trustinsureInstance.checkInsure(companyOwner) >= value,"not enough TrustInsure to pay!");
        
        trustinsureInstance.transferFromInsure(companyOwner, beneficiaryAddress, value);
        insurances[insuranceId].status = Insurance.status.claimed;
        emit transfer(beneficiaryAddress, value);
    }

    // /**
    // * @dev Allow insurance market to update requests
    // * @return bool whether added successfullly
    // * @return uint256 numOfReq request id
    // */
    function addRequestLists(uint256 _buyerId, uint256 _companyId, string memory contact, string memory _typeProduct) 
    external 
    returns(bool, uint256) 
    {
        Request storage req =  companies[_companyId].requestLists.push();
        
        numOfReq++;
        req.reqId = numOfReq;
        req.buyerId =  _buyerId;
        req.contact = contact;
        req.productType = _typeProduct;
        req.status = requestStatus.pending;
        return (true, numOfReq);
    }

    // /**
    // * @dev Allow insurance company check all requests
    // */
    function checkRequestsFromCompany(uint256 companyId) 
    public validCompanyId(companyId) ownerOnly(companyId) 
    {
        Request[] memory reqs = companies[companyId].requestLists;
        uint256[] memory requestids = new uint256[](reqs.length);
        uint256[] memory buyerids = new uint256[](reqs.length);
        string[] memory buyercontacts= new string[](reqs.length);
        string[] memory producttypes = new string[](reqs.length);

        //only show those pending requests
        for(uint256 i = 0;i< reqs.length;i++) {
            if (reqs[i].status == requestStatus.pending) {
                requestids[i] = reqs[i].reqId;
                buyerids[i] = reqs[i].buyerId;
                buyercontacts[i] = reqs[i].contact;
                producttypes[i] = reqs[i].productType;
            }
        }

        emit allRequests(requestids,
        buyerids,
        buyercontacts,
        producttypes);
       
    }
    
    // /**
    // * @dev Allow insurance company reject request
    // */
    function rejectRequest(uint256 requestId,uint256 companyId) public
    validCompanyId(companyId) ownerOnly(companyId)  
    {
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

    // /**
    // * @dev Allow stakeholder to check request status
    // */
    function checkRequestsFromStakeholder(uint256 companyId, uint256 requestId) external returns (requestStatus, uint256) {
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
        
        require(find == true, "You haven't requested!");
        if (find) {
            emit checkRequest(reqs[index].status);
        }
        
        return (reqs[index].status, reqs[index].insuranceId);
    }
    
// =====================================================================================
// getters
// =====================================================================================
    
    //get the company credit
    function getCredit(uint256 companyId) public view validCompanyId(companyId) returns (uint256) {
        return companies[companyId].credit;
    }

    function getName(uint256 companyId) public view validCompanyId(companyId) returns (string memory) {
        return companies[companyId].name;
    }
    
    function getOwner(uint256 companyId) public view validCompanyId(companyId) returns (address) {
        return companies[companyId].owner;
    }
    
    function getCompanyId() public view returns(uint256) {
        return ids[msg.sender];
    }
    

    function getNumOfCompany() public view returns (uint256) {
        return numOfCompany;
    }

}
