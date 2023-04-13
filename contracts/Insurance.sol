// SPDX-License-Identifier: MIT
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
        uint256 stakeholders;
        uint256 premium;
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

// =====================================================================================
// functions
// =====================================================================================
    
    /** 
    * @dev Create related stakeholders profile for the insurance
    * @param policyOwner the id of the stakeholder who want to purchase the insurance policy
    * @param beneficiary the id of the stakeholder who will be benefited when the insurance is claimed
    * @param lifeAssured the id of the stakeholder being assured
    * @param payingAccount the id of the stakeholder who will receive the payment
    */
    function createStakeholderInfo (uint256 policyOwner,
        uint256  beneficiary,
        uint256 lifeAssured,
        uint256 payingAccount) 
    public virtual returns(uint256) {}

    /** 
    * @dev Create the insurance
    * @param stakeholderInfoId the id of the stakeholder info that created before
    * @param companyId the id of the company
    * @param premium the total amount of premium fee that stakeholder should pay before claim
    * @param insuredAmount the total amount of payment when the insurnace is claimed
    * @param insType0life1accident the type of insurance, 0 for life or 1 for accident insurance
    * @param issueDateYYYYMMDD The date of the insurance being created
    * @param expiryDateYYYYMMDD The date of the insurance will be expired
    */
    function createInsurance(
        uint256 stakeholderInfoId,
        uint256 companyId,
        uint256 premium,
        uint256 insuredAmount,
        insuranceType insType0life1accident,
        uint256 issueDateYYYYMMDD,
        uint256 expiryDateYYYYMMDD
    ) 
    public virtual returns(uint256) {}


// =====================================================================================
// setters
// =====================================================================================
    function setBeneficiary(uint256 newBeneficiary, uint256 insuranceId) public {//policyOwnerOnly(insuranceId) {
        stakeholderinfos[insurances[insuranceId].stakeholders].beneficiary = newBeneficiary;
    }

    function updateStatus(status state, uint256 insuranceId) public { //policyOwnerOnly(insuranceId) {
        insurances[insuranceId].status = state;
    }

    function setExpiryDate(uint256 date, uint256 insuranceId) public {//companyOnly(insuranceId) {
	    require(insurances[insuranceId].expiryDate != 0, "Expiry date has already been initialised");
        insurances[insuranceId].expiryDate = date;

    }

// =====================================================================================
// getters
// =====================================================================================

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
        return stakeholderinfos[insurances[insuranceId].stakeholders].beneficiary;
    }

    function getPolicyOwner(uint256 stakeholderinfoId) public view returns (uint256) {
        return stakeholderinfos[stakeholderinfoId].policyOwner;
    }

    function getRestAmount(uint256 insuranceId) public view returns(uint256) {
        return insurances[insuranceId].premium - insurances[insuranceId].currentAmount;
    }

    function getNumberOfInsurance() public view returns(uint256) {
        return numInsurance;
    }

}