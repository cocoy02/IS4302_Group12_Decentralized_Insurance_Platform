pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;
import "./Stakeholder.sol";
import "./InsuranceCompany.sol";

contract Insurance {
    Stakeholder stakeholderContract;
    InsuranceCompany insuranceCompanyContract;
    
    enum insuranceType { life, accident }
    enum premiumStatus { processing, paid, unpaid }
    enum claimStatus { claimed, unclaimed }
    enum reasonType { suicide, others }

    struct insurance {
        uint256 ID;
        uint256 policyOwner;
        uint256  beneficiary;//
        uint256 lifeAssured;
        uint256  payingAccount;
        uint256 companyId;
        uint256 insuredAmount;
        insuranceType insType;
        premiumStatus status;//
        uint256 issueDate;
        uint256 expiryDate;//
        bool approved;
        reasonType reason;
        uint256 price;
        claimStatus claimstatus;
    }
    
    uint256 public numInsurance = 0;
    mapping(uint256 => insurance) public insurances;

    constructor (Stakeholder stakeholderAddress, InsuranceCompany insuranceCompanyAddress) public {
        stakeholderContract = stakeholderAddress;
        insuranceCompanyContract = insuranceCompanyAddress;
    }

     /** 
    * @dev function to create a new insurance, and add to 'insurances' map. requires at least 0.01ETH to create
    * @return uint256 new insurance id
    */
    function createInsurance(
        uint256  policyOwner,
        uint256  beneficiary,
        uint256 lifeAssured,
        uint256 payingAccount,
        uint256 companyId,
        uint256 insuredAmount,
        insuranceType insType,
        uint256 issueDate,
        reasonType reason,
        uint256 price
    ) public payable returns(uint256) {
        require(msg.value == 0.01 ether, "0.01 ETH is needed to initialise a new insurance"); // registering fee for insurance, not the payment for the actual insurance
        
        //new insurance object
        insurance memory newInsurance = insurance(
            numInsurance++,
            policyOwner,
            beneficiary,
            lifeAssured,
            payingAccount,
            companyId,
            insuredAmount,
            insType,
            premiumStatus.unpaid, // initialise premium status to unpaid
            issueDate,
            issueDate+0, // initialise expiry date to 0
            false,
            reason,
            price,
            claimStatus.unclaimed
        );
        
        uint256 newInsuranceId = numInsurance;
        insurances[newInsuranceId] = newInsurance; //commit to state variable
        return newInsuranceId;   //return new insurance Id
    }

    //modifier to ensure a function is callable only by its policy owner    
    modifier policyOwnerOnly(uint256 insuranceId) {
        //stakeholderContract.getStakeholderAddress(uint256 stakeholderID)
        require(stakeholderContract.getStakeholderAddress(insurances[insuranceId].policyOwner) == msg.sender);
        _;
    }

    //modifier to ensure a function is callable only by its insurance company   
    // modifier companyOnly(uint256 insuranceId) {
    //     require(insurances[insuranceId].company == msg.sender);
    //     _;
    // }

    // SETTERS 

    function setBeneficiary(uint256 s1, uint256 insuranceId) public policyOwnerOnly(insuranceId) {
        insurances[insuranceId].beneficiary = s1;
    }

    function updatePremiumStatus(premiumStatus state, uint256 insuranceId) public { //policyOwnerOnly(insuranceId) {
        insurances[insuranceId].status = state;
    }

    function updateClaimStatus(claimStatus claimstate, uint256 insuranceId) public { 
        insurances[insuranceId].claimstatus = claimstate;
    }

    function setExpiryDate(uint256 date, uint256 insuranceId) public {//companyOnly(insuranceId) {
	    require(insurances[insuranceId].expiryDate != 0, "Expiry date has already been initialised");
        insurances[insuranceId].expiryDate = date;

    }
    // GETTERS

    function getInsurance(uint256 insuranceId) public returns (insurance memory) {
        return insurances[insuranceId];
    }

    function getInsuranceState(uint256 insuranceId) public returns (bool) {
        return insurances[insuranceId].approved;
    }

    function getInsuredAmount(uint256 insuranceId) public returns (uint256) {
        return insurances[insuranceId].insuredAmount;
    }

    function getReason(uint256 insuranceId) public returns (reasonType) {
        return insurances[insuranceId].reason;
    }

    function getIssueDate(uint256 insuranceId) public returns (uint256) {
        return insurances[insuranceId].issueDate;
    }

    function getExpiryDate(uint256 insuranceId) public returns (uint256) {
        return insurances[insuranceId].expiryDate;
    }

    function getInsuranceCompany(uint256 insuranceId) public returns (uint256) {
        return insurances[insuranceId].companyId;
    }

    function getPremiumStatus(uint256 insuranceId) public returns (premiumStatus) {
        return insurances[insuranceId].status;
    }

    function getBeneficiary(uint256 insuranceId) public returns (uint256) {
        return insurances[insuranceId].beneficiary;
    }

    function autoTrigger() public {
        // if not enough, after one month, check again.
        // otherwise, terminate the insurance until stakeholder could pay
    }
}