pragma solidity ^0.8.12;
pragma experimental ABIEncoderV2;

contract Insurance {


    
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
        uint256 currentAmount;
        insuranceType insType;
        status status;//
        uint256 issueDate;
        uint256 expiryDate;//
    }
    
    uint256 public numInsurance = 0;
    mapping(uint256 => insurance) public insurances;

    uint256 public numStakeholder = 0;
    mapping(uint256 => stakeholderInfo) public stakeholderinfos;


    function createStakeholderInfo (uint256 policyOwner,
        uint256  beneficiary,
        uint256 lifeAssured,
        uint256 payingAccount) 
    public virtual returns(uint256) {}

    //  /** 
    // * @dev function to create a new insurance, and add to 'insurances' map. requires at least 0.01ETH to create
    // * @return uint256 new insurance id
    // */
    function createInsurance(
        uint256 stakeholderInfoId,
        uint256 companyId,
        uint256 insuredAmount,
        insuranceType insType,
        uint256 issueDateYYYYMMDD,
        uint256 expiryDateYYYYMMDD
    ) 
    public virtual returns(uint256) {}

    //modifier to ensure a function is callable only by its policy owner    
    // modifier policyOwnerOnly(uint256 insuranceId) {
    //     //stakeholderContract.getStakeholderAddress(uint256 stakeholderID)
    //     require(stakeholderContract.getStakeholderAddress(insurances[insuranceId].stakeholders.policyOwner) ==  msg.sender);
    //     _;
    // }

    //modifier to ensure a function is callable only by its insurance company   
    // modifier companyOnly(uint256 insuranceId) {
    //     require(insurances[insuranceId].company == msg.sender);
    //     _;
    // }

    // SETTERS 

    function setBeneficiary(uint256 newBeneficiary, uint256 insuranceId) public {//policyOwnerOnly(insuranceId) {
        insurances[insuranceId].stakeholders.beneficiary = newBeneficiary;
    }

    function updateStatus(status state, uint256 insuranceId) public { //policyOwnerOnly(insuranceId) {
        insurances[insuranceId].status = state;
    }

    function setExpiryDate(uint256 date, uint256 insuranceId) public {//companyOnly(insuranceId) {
	    require(insurances[insuranceId].expiryDate != 0, "Expiry date has already been initialised");
        insurances[insuranceId].expiryDate = date;

    }
    
    //return whether insured amount all paid
    // function updateAmount(uint256 insuranceId, uint256 amount) public returns(bool) {
    //     insurances[insuranceId].currentAmount += amount;
    //     if (insurances[insuranceId].currentAmount == insurances[insuranceId].insuredAmount) {
    //         insurances[insuranceId].status = status.paid;
    //         return true;
    //     }

    //     return false;
    // }
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

    function getRestAmount(uint256 insuranceId) public view returns(uint256) {
        return insurances[insuranceId].insuredAmount - insurances[insuranceId].currentAmount;
    }

    function autoTrigger() public {
        // if not enough, after one month, check again.
        // otherwise, terminate the insurance until stakeholder could pay
    }
}