pragma solidity ^0.5.0;
import "./InsuranceMarket.sol";
import "./Insurance.sol";
import "./InsuranceCompany.sol";


contract Stakeholder {

    InsuranceMarket marketContract;
    Insurance insuranceContract;
    InsuranceCompany insuranceCompanyContract;
    enum position { policyOwner, beneficiary, lifeAssured }

    constructor(InsuranceMarket marketAddress, Insurance insuranceAddress) public {
        marketContract = marketAddress;
        insuranceContract = insuranceAddress;
    }

    struct stakeholder {
        uint256 ID;
        address stakeholderAddress;
        mapping(uint256 => position) involvingInsurances; //insurance ID to position   
        uint256[10] toBeSigned;
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

    // sign insurance and pay
    function signInsurance(uint256 policyOwnerID,uint256 insuranceID, uint256 beneficiaryID, uint256 lifeAssuredID,uint256 offerPrice) public {
        // require offerPrice >= owningMoney
        // require insurance ID valid

        bool doesListContainElement = false;
        uint256 memory index;
        for (uint i=0; i < stakeholders[policyOwnerID].toBeSigned.length; i++) {
            if (elementToLookFor == stakeholders[policyOwnerID].toBeSigned[i]) {
                doesListContainElement = true;
                index = i;
                break;
            }
        }

        require(doesListContainElement == True);
        stakeholders[policyOwnerID].toBeSigned.remove(index);


        stakeholders[policyOwnerID].involvingInsurances[insuranceID] = position.policyOwner;
        stakeholders[beneficiaryID].involvingInsurances[insuranceID] = position.beneficiary;
        stakeholders[lifeAssuredID].involvingInsurances[insuranceID] = position.lifeAssured;
        address memory companyAddress = insuranceContract.getInsuranceCompany(insuranceID);
        marketContract.transfer(msg.sender,companyAddress,offerPrice);


    }

    function addToSignList(uint256 insuraneID,uint256 policyOwnerID) public {
        require(stakeholders[policyOwnerID].toBeSigned[9] == 0);
        stakeholders[policyOwnerID].toBeSigned.push(insuranceID);
    }

    // function payPremium(uint256 insuranceID, uint256 amount, uint256 policyOwnerID) public onlyPolicyOwner(policyOwnerID){
    //     address memory companyAddress = insuranceContract.getInsuranceCompany(insuranceID);
    //     marketContract.transfer(msg.sender,companyAddress,amount);

    //     //mark as paid
    // }

    function getMCidAndPassToComp(uint256 insuranceID) {
        // uint MDid = 
        uint256 memory company = insuranceContract.getInsuranceCompany(insuranceID);
        insuranceCompanyContract.autoTransfer(insuranceID, company, MCid);

    }

    function claim(uint256 insuranceID,byte mcId) public onlyPolicyOwner(policyOwnerID){
        //step1: ask for cert from hospital
        emit askingCert(insuranceID);

        //step2: tell insurance company to pay back
        company = insuranceContract.getInsuranceCompany(insuranceID);
        insuranceCompanyContract.autoTransfer(insuranceID,company,mcId);
        emit claimingFromComp(insuranceID,mcId);
    }

    //Getters
    function getStakeholder(uint256 stakeholderID) public view returns(Stakeholder){
        return stakeholders[stakeholderID];
    }

    function getInvolvingInsurances(uint256 stakeholderID) public view returns(mapping(uint256 => position)){
        return stakeholders[stakeholderID].involvingInsurances;
    }

    
}