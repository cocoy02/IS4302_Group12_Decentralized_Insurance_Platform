pragma solidity ^0.5.0;
import "./Stakeholder.sol";
import "./InsuranceCompany.sol";

contract Insurance {
    Stakeholder stakeholderContract;
    InsuranceCompany insuranceCompanyContract;
    
    enum insuranceType { life, accident }
    enum premiumStatus { processing, paid, unpaid }
    enum reasonType { suicide, others }

    struct insurance {
        uint256 ID;
        Stakeholder policyOwner;
        Stakeholder beneficiary;//
        Stakeholder lifeAssured;
        Stakeholder payingAccount;
        uint256 companyId;
        uint256 insuredAmount;
        insuranceType insType;
        premiumStatus status;//
        uint256 issueDate;
        uint256 expiryDate;//
        bool approved;
        reasonType reason;
        uint256 price;
    }
    
    uint256 public numInsurance = 0;
    mapping(uint256 => insurance) public insurances;

    constructor (Stakeholder stakeholderAddress, InsuranceCompany insuranceCompanyAddress) public {
        stakeholderContract = stakeholderAddress;
        insuranceCompanyContract = insuranceCompanyAddress;
    }

    //function to create a new insurance, and add to 'insurances' map. requires at least 0.01ETH to create
    function createInsurance(
        Stakeholder policyOwner,
        Stakeholder beneficiary,
        Stakeholder lifeAssured,
        Stakeholder payingAccount,
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
            price
        );
        
        uint256 newInsuranceId = numInsurance;
        insurances[newInsuranceId] = newInsurance; //commit to state variable
        return newInsuranceId;   //return new insurance Id
    }

    //modifier to ensure a function is callable only by its policy owner    
    modifier policyOwnerOnly(uint256 insuranceId) {
        //stakeholderContract.getStakeholderAddress(uint256 stakeholderID)
        require(insurances[insuranceId].policyOwner.stakeholderAddress == msg.sender);
        _;
    }

    //modifier to ensure a function is callable only by its insurance company   
    modifier companyOnly(uint256 insuranceId) {
        require(insurances[insuranceId].company == msg.sender);
        _;
    }

    // SETTERS 

    function setBeneficiary(Stakeholder s1, uint256 insuranceId) public policyOwnerOnly(insuranceId) {
        insurances[insuranceId].beneficiary = s1;
    }

    function updateStatus(premiumStatus state, uint256 insuranceId) public policyOwnerOnly(insuranceId) {
        insurances[insuranceId].status = state;
    }

    function setExpiryDate(uint256 date, uint256 insuranceId) public companyOnly(insuranceId) {
	    require(insurances[insuranceId].expiryDate != 0, "Expiry date has already been initialised");
        insurances[insuranceId].expiryDate = date;
    }

    // GETTERS

    function getInsurance(uint256 insuranceId) public returns (Insurance) {
        return insurances[insuranceId];
    }

    function getInsuranceState(uint256 insuranceId) public returns (bool) {
        return insurances[insuranceId].approved;
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
        return insurances[insuranceId].insuranceCompany;
    }

    function autoTrigger() public {
        // if not enough, after one month, check again.
        // otherwise, terminate the insurance until stakeholder could pay
    }
}