pragma solidity ^0.8.12;
pragma experimental ABIEncoderV2;
import "./Stakeholder.sol";
import "./InsuranceCompany.sol";

contract Insurance {
    Stakeholder stakeholderContract;
    InsuranceCompany insuranceCompanyContract;
    
    enum insuranceType { life, accident }
    enum status { unapproved, processing,  unpaid, paid, claimed, unclaimed}
    enum reasonType { suicide, others }

    struct stakeholderInfo {
        uint256 policyOwner;
        uint256 beneficiary;
        uint256 lifeAssured;
        uint256 payingAccount;

    }

    struct insurance {
        uint256 ID;
        uint256 companyId;
        stakeholderInfo stakeholders;
        uint256 insuredAmount;
        insuranceType insType;
        status status;//
        uint256 issueDate;
        uint256 expiryDate;//
    }
    
    uint256 public numInsurance = 0;
    mapping(uint256 => insurance) public insurances;

    uint256 public numStakeholder = 0;
    mapping(uint256 => stakeholderInfo) public stakeholderinfos;

    constructor (Stakeholder stakeholderAddress, InsuranceCompany insuranceCompanyAddress) public {
        stakeholderContract = stakeholderAddress;
        insuranceCompanyContract = insuranceCompanyAddress;
    }

    function createStakeholderInfo (uint256 policyOwner,
        uint256  beneficiary,
        uint256 lifeAssured,
        uint256 payingAccount) 
    public returns(uint256) {
        numStakeholder++;
        stakeholderInfo storage newInfo = stakeholderinfos[numStakeholder];
        
        newInfo.policyOwner = policyOwner;
        newInfo.beneficiary = beneficiary;
        newInfo.lifeAssured = lifeAssured;
        newInfo.payingAccount = payingAccount;
        
        return numStakeholder;
    }

    //  /** 
    // * @dev function to create a new insurance, and add to 'insurances' map. requires at least 0.01ETH to create
    // * @return uint256 new insurance id
    // */
    function createInsurance(
        uint stakeholderInfoId,
        uint256 companyId,
        uint256 insuredAmount,
        insuranceType insType,
        uint256 issueDateYYYYMMDD,
        uint256 expiryDateYYYYMMDD
    ) public payable returns(uint256) {
        require(msg.value == 0.01 ether, "0.01 ETH is needed to initialise a new insurance"); // registering fee for insurance, not the payment for the actual insurance
        
        numInsurance++;
        //new insurance object
        insurance storage newInsurance = insurances[numInsurance];
        newInsurance.stakeholders = stakeholderinfos[stakeholderInfoId];
        newInsurance.companyId = companyId;
        newInsurance.insuredAmount = insuredAmount;
        newInsurance.insType = insType;
        newInsurance.status = status.unapproved; // initialise  status to unapproved
        newInsurance.issueDate = issueDateYYYYMMDD;
        newInsurance.expiryDate = expiryDateYYYYMMDD; // initialise expiry date to 0
        
        return numInsurance;   //return new insurance Id
    }

    //modifier to ensure a function is callable only by its policy owner    
    modifier policyOwnerOnly(uint256 insuranceId) {
        //stakeholderContract.getStakeholderAddress(uint256 stakeholderID)
        require(stakeholderContract.getStakeholderAddress(insurances[insuranceId].stakeholders.policyOwner) ==  msg.sender);
        _;
    }

    //modifier to ensure a function is callable only by its insurance company   
    // modifier companyOnly(uint256 insuranceId) {
    //     require(insurances[insuranceId].company == msg.sender);
    //     _;
    // }

    // SETTERS 

    function setBeneficiary(uint256 newBeneficiary, uint256 insuranceId) public policyOwnerOnly(insuranceId) {
        insurances[insuranceId].stakeholders.beneficiary = newBeneficiary;
    }

    function updateStatus(status state, uint256 insuranceId) public { //policyOwnerOnly(insuranceId) {
        insurances[insuranceId].status = state;
    }

    function setExpiryDate(uint256 date, uint256 insuranceId) public {//companyOnly(insuranceId) {
	    require(insurances[insuranceId].expiryDate != 0, "Expiry date has already been initialised");
        insurances[insuranceId].expiryDate = date;

    }
    // GETTERS

    function getInsurance(uint256 insuranceId) public view returns (insurance memory) {
        return insurances[insuranceId];
    }

    function getInsuredAmount(uint256 insuranceId) public view  returns (uint256) {
        return insurances[insuranceId].insuredAmount;
    }

    function getIssueDate(uint256 insuranceId) public  view returns (uint256) {
        return insurances[insuranceId].issueDate;
    }

    function getExpiryDate(uint256 insuranceId) public  view returns (uint256) {
        return insurances[insuranceId].expiryDate;
    }

    function getInsuranceCompany(uint256 insuranceId) public view returns (uint256) {
        return insurances[insuranceId].companyId;
    }

    function getStatus(uint256 insuranceId) public view returns (status) {
        return insurances[insuranceId].status;
    }

    function getBeneficiary(uint256 insuranceId) public view returns (uint256) {
        return insurances[insuranceId].stakeholders.beneficiary;
    }

    function getPolicyOwner(uint256 stakeholderinfoId) public view returns (uint256) {
        return stakeholderinfos[stakeholderinfoId].policyOwner;
    }

    function autoTrigger() public {
        // if not enough, after one month, check again.
        // otherwise, terminate the insurance until stakeholder could pay
    }
}