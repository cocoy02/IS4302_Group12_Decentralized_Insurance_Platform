pragma solidity ^0.5.0;
import "./InsuranceMarket.sol";
import "./Insurance.sol";


contract Stakeholder {

    InsuranceMarket marketContract;
    Insurance insuranceContract;
    enum position { policyOwner, beneficiary, lifeAssured }

    constructor(InsuranceMarket marketAddress, Insurance insuranceAddress) public {
        marketContract = marketAddress;
        insuranceContract = insuranceAddress;
    }

    struct stakeholder {
        uint256 ID;
        address stakeholderAddress;
        mapping(uint256 => position) involvingInsurances; //insurance ID to position   
    }
    
    event askingCert (uint256 insuranceID);
    event claimingFromComp (uint256 insuranceID);

    uint256 public numStakeholder = 0;
    mapping(uint256 => stakeholder) public stakeholders; //stakeholder ID to stakeholder

    //Modifiers
    modifier onlyPolicyOwner(policyOwnerID) {
        require(msg.sender == stakeholders[policyOwnerID].stakeholderAddress);
        _;
    } 


    //Functions
    function addStakeholder() public returns(int256) {
        uint256 newID = numStakeholder++;
        stakeholder memory newStakeholder = stakeholder(
            newID,
            msg.sender
        );
        stakeholders[newID] = newStakeholder;
    }

    function buyInsurance(uint256 policyOwnerID,uint256 insuranceID, uint256 beneficiaryID, uint256 lifeAssuredID,uint256 offerPrice) public {
        // require offerPrice >= owningMoney
        // require insurance ID valid
        stakeholders[policyOwnerID].involvingInsurances[insuranceID] = position.policyOwner;
        stakeholders[beneficiaryID].involvingInsurances[insuranceID] = position.beneficiary;
        stakeholders[lifeAssuredID].involvingInsurances[insuranceID] = position.lifeAssured;
        address memory companyAddress = insuranceContract.getInsuranceCompany(insuranceID);
        marketContract.transfer(msg.sender,companyAddress,offerPrice);
    }

    function payPremium(uint256 insuranceID, uint256 amount, uint256 policyOwnerID) public onlyPolicyOwner(policyOwnerID){
        address memory companyAddress = insuranceContract.getInsuranceCompany(insuranceID);
        marketContract.transfer(msg.sender,companyAddress,amount);

        //mark as paid
    }

    function claim(uint256 insuranceID) public onlyPolicyOwner(policyOwnerID){
        //step1: ask for cert from hospital
        emit askingCert(insuranceID);

        //step2: tell insurance company to pay back
        emit claimingFromComp(insuranceID);
    }

    //Getters
    function getStakeholder(uint256 stakeholderID) public view returns(Stakeholder){
        return stakeholders[stakeholderID];
    }

    function getInvolvingInsurances(uint256 stakeholderID) public view returns(mapping(uint256 => position)){
        return stakeholders[stakeholderID].involvingInsurances;
    }

    
}