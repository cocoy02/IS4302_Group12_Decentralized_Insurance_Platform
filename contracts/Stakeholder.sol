pragma solidity ^0.8.12;
pragma experimental ABIEncoderV2;
import "./InsuranceCompany.sol";
import "./Hospital.sol";
import "./TrustInsure.sol";


contract Stakeholder {

    InsuranceCompany insuranceCompanyContract;
    Hospital hospitalContract;
    TrustInsure insureContract;
    enum position { policyOwner, beneficiary, lifeAssured }


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
        mapping(uint256 => position) involvingInsurances; //insurance ID to position   
    }
    

    uint256 public numStakeholder = 0;
    mapping(uint256 => stakeholder) public stakeholders; //stakeholder ID to stakeholder
    mapping(address => uint256) ids; //stakeholder address to id
    mapping(uint256 => uint256[]) insuranceReqs; //stakeholder ids => insurance requests ids
    mapping(uint256 => uint256[]) mcReqs; 

    //Modifiers
    modifier onlyPolicyOwner(uint256 policyOwnerID) {
        require(msg.sender == stakeholders[policyOwnerID].stakeholderAddress);
        _;
    } 

    modifier validStakeholder(uint256 stakeholderId) {
        require(ids[msg.sender] == stakeholderId, "Invalid stakeholder!");
        _;
    }


    //Functions
    // /** 
    // * @dev create new stakeholder
    // * @return uint256 id of new stakeholder
    // */
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

    function addRequestIds(uint256 stakeholderId, uint256 requestId) public {
        insuranceReqs[stakeholderId].push(requestId);
    }
    
    function requestMC(uint256 hospitalId, string memory nameAssured, string memory icAssured) 
    public returns(uint256) {
        uint256 id = getStakeholderId(msg.sender);
        uint256 reqid = hospitalContract.requestMC(hospitalId, id, nameAssured, icAssured);

        mcReqs[id].push(reqid);

        return reqid;
    }
    
    // /** 
    // * @dev Stakeholder ask hospital for mc and call company to claim money
    // */
    function checkInsuranceRequests(uint256 stakeholderId, uint256 companyId, uint256 requestId) 
    public validStakeholder(stakeholderId) returns (uint256) {
        (InsuranceCompany.requestStatus status, uint256 insuranceId) = insuranceCompanyContract.checkRequestsFromStakeholder(companyId, requestId);
        if (status == InsuranceCompany.requestStatus.approved) return insuranceId;
        else return 0; //return 0 means no request has been rejected or pending
    }

    function signInsurance(uint256 insuranceId,uint256 companyId, 
    uint256 policyOwnerID, string memory signature) 
    public validStakeholder(policyOwnerID) {
        insuranceCompanyContract.signInsurance(insuranceId, companyId, policyOwnerID);
    }

    function payPremium(uint256 insuranceId, uint256 amount, uint256 policyOwnerID) 
    public validStakeholder(policyOwnerID) {
        insuranceCompanyContract.payPremium(insuranceId, amount, policyOwnerID);
    }

    function claimInsurance (uint256 insuranceID,uint256 companyId, bytes memory mcId,
    uint256 hospitalId,uint256 policyOwnerID,
    string memory name, string memory NRIC) 
    public validStakeholder(policyOwnerID) {
        insuranceCompanyContract.claim(insuranceID,companyId,mcId,
         hospitalId, policyOwnerID,
         name, NRIC);
    }

    function checkMCRequests(uint256 _hospitalId, uint256 _requestId, uint256 _stakeholderId) public view
    returns(bytes memory)
    {
        return hospitalContract.checkMCIdFromStakeholder(_hospitalId, _requestId,_stakeholderId);
    }

    //Getters
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
    
}