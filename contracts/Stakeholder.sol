pragma solidity ^0.8.12;
pragma experimental ABIEncoderV2;
import "./InsuranceCompany.sol";
import "./Hospital.sol";
import "./TrustInsure.sol";


contract Stakeholder {

    InsuranceCompany insuranceCompanyContract;
    Hospital hospitalContract;
    TrustInsure insureContract;
    //enum position { policyOwner, beneficiary, lifeAssured }


    constructor( InsuranceCompany insuranceCompanyAddress, 
    Hospital hospitalAddress, 
    TrustInsure insureAddress) 
    public 
    {
        insuranceCompanyContract = insuranceCompanyAddress;
        hospitalContract = hospitalAddress;
        insureContract = insureAddress;
    }

    struct stakeholder {
        uint256 ID;
        string name;
        bytes NRIC;
        address stakeholderAddress;
    }
    

    uint256 public numStakeholder = 0;
    mapping(uint256 => stakeholder) public stakeholders; //stakeholder ID to stakeholder
    mapping(address => uint256) ids; //stakeholder address to id
    mapping(uint256 => uint256[]) insuranceReqs; //stakeholder ids => insurance requests ids
    mapping(uint256 => uint256[]) mcReqs; 

    //Modifiers

    modifier validStakeholder(uint256 stakeholderId) {
        require(ids[msg.sender] == stakeholderId, "Invalid stakeholder!");
        _;
    }

// =====================================================================================
// functions
// =====================================================================================

    /** 
    * @dev create new stakeholder
    * @param name name of stakeholder
    * @param NRIC NRIC of stakeholder
    * @return uint256 id of new stakeholder
    */
    function addStakeholder(string memory name,string memory NRIC) public returns(uint256) {
        numStakeholder++;
        stakeholder storage newStakeholder = stakeholders[numStakeholder];
        newStakeholder.ID = numStakeholder;
        newStakeholder.name = name;
        newStakeholder.stakeholderAddress = msg.sender;
        newStakeholder.NRIC = abi.encodePacked(NRIC);
        ids[msg.sender] = numStakeholder;
        return numStakeholder;
    }
    
    /** 
    * @dev Record the preferred product one wants to purchase
    * @param stakeholderId the id of the stakeholder
    * @param requestId the id of the request
    * @return uint256 id of request
    */
    function addRequestIds(uint256 stakeholderId, uint256 requestId) external {
        insuranceReqs[stakeholderId].push(requestId);
    }
    
    /** 
    * @dev Request for MC
    * @param hospitalId the id of the hospital
    * @param nameAssured the name of the life assured
    * @param icAssured the NRIC of the life assured
    * @return uint256 id of request
    */
    function requestMC(uint256 hospitalId, string memory nameAssured, string memory icAssured) 
    public returns(uint256) {
        uint256 id = getStakeholderId(msg.sender);
        uint256 reqid = hospitalContract.requestMC(hospitalId, id, nameAssured, icAssured);

        mcReqs[id].push(reqid);

        return reqid;
    }
    
    /** 
    * @dev Check the insurance requests status
    * @param stakeholderId id of stakeholder
    * @param companyId id of company
    * @param requestId id of request
    * @return uint256 insurance id
    */
    function checkInsuranceRequests(uint256 stakeholderId, uint256 companyId, uint256 requestId) 
    public validStakeholder(stakeholderId) returns (uint256) {
        (InsuranceCompany.requestStatus status, uint256 insuranceId) = insuranceCompanyContract.checkRequestsFromStakeholder(companyId, requestId);
        if (status == InsuranceCompany.requestStatus.approved) return insuranceId;
        else return 0; //return 0 means no request has been rejected or pending
    }

    /** 
    * @dev Sign insurance
    * @param insuranceId id of insurance
    * @param companyId id of company
    * @param policyOwnerID id of policy owner
    * @param signature  the signature of the stakeholder.
    */
    function signInsurance(uint256 insuranceId,uint256 companyId, 
    uint256 policyOwnerID, string memory signature) 
    public validStakeholder(policyOwnerID) {
        insuranceCompanyContract.signInsurance(insuranceId, companyId, policyOwnerID);
    }

    /** 
    * @dev Pay premium for the contract
    * @param insuranceId id of insurance
    * @param amount  the sum to be paid
    * @param policyOwnerID id of policy owner
    */
    function payPremium(uint256 insuranceId, uint256 amount, uint256 policyOwnerID) 
    public validStakeholder(policyOwnerID) {     
        insuranceCompanyContract.payPremium(insuranceId, amount, policyOwnerID,stakeholders[policyOwnerID].stakeholderAddress);
    }

    /** 
    * @dev Claim insurance
    * @param insuranceID id of insurance
    * @param companyId the id of the company
    * @param mcId the id of the medical certificate
    * @param beneficiaryID the id of the policy owner
    * @param lifeAssuredName the name of the life assured
    * @param lifeAssuredNRIC the NRIC of the life assured
    */
    function claimInsurance (uint256 insuranceID,uint256 companyId, 
    uint256 mcId,uint256 beneficiaryID,
    string memory lifeAssuredName, string memory lifeAssuredNRIC)   
    public validStakeholder(beneficiaryID) {
        insuranceCompanyContract.claim(insuranceID,companyId,mcId,
         beneficiaryID, stakeholders[beneficiaryID].stakeholderAddress,
         lifeAssuredName,lifeAssuredNRIC);
    }
    
    /** 
    * @dev Check MC requests
    * @param hospitalId id of hospital
    * @param requestId the id of request
    * @param stakeholderId the id of stakeholder
    * @return uint256 mc id
    */
    function checkMCRequests(uint256 hospitalId, uint256 requestId, uint256 stakeholderId) public view
    returns(uint256)
    {
        return hospitalContract.checkMCIdFromStakeholder(hospitalId, requestId, stakeholderId);
    }

// =====================================================================================
// getters
// =====================================================================================
    // function getStakeholder(uint256 stakeholderID) public view returns(Stakeholder){
    //     return stakeholders[stakeholderID];
    // }

    // function getInvolvingInsurances(uint256 stakeholderID, uint256 insuranceID) public view returns(Insurance){
    //     return stakeholders[stakeholderID].involvingInsurances[insuranceID];
    // }
    
    function getStakeholderId(address _stakeholder) public view returns(uint256) {
        return ids[_stakeholder];
    }

    function getStakeholderAddress(uint256 stakeholderID) public view validStakeholder(stakeholderID) returns(address) {
        return stakeholders[stakeholderID].stakeholderAddress;
    }

    function getStakeholderName(uint256 stakeholderID) public view validStakeholder(stakeholderID) returns(string memory) {
        return stakeholders[stakeholderID].name;
    }

    function getStakeholderNRIC(uint256 stakeholderID) public view validStakeholder(stakeholderID) returns(bytes memory) {
        return stakeholders[stakeholderID].NRIC;
    }

    function getRequestId(uint256 stakeholderID) public view validStakeholder(stakeholderID) returns(uint256[] memory) {
        return insuranceReqs[stakeholderID];
    }

    function getInsurance(uint256 insuranceId) public view returns (Insurance.insurance memory) {
        return insuranceCompanyContract.getInsurance(insuranceId);
    }

    function getRestAmount(uint256 insuranceId) public view returns(uint256) {
        return insuranceCompanyContract.getRestAmount(insuranceId);
    }
    
}