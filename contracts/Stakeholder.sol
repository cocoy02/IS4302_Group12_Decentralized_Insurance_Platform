pragma solidity ^0.5.0;
import "./InsuranceMarket.sol";
import "./Insurance.sol";
import "./InsuranceCompany.sol";
import "./Hospital.sol";


contract Stakeholder {

    InsuranceMarket marketContract;
    Insurance insuranceContract;
    InsuranceCompany insuranceCompanyContract;
    Hospital hospitalContract;
    enum position { policyOwner, beneficiary, lifeAssured }

    constructor(InsuranceMarket marketAddress, Insurance insuranceAddress, Hospital hospitalAddress) public {
        marketContract = marketAddress;
        insuranceContract = insuranceAddress;
        hospitalContract = hospitalAddress;
    }

    struct stakeholder {
        uint256 ID;
        address stakeholderAddress;
        bytes32 phonenum;
        mapping(uint256 => position) involvingInsurances; //insurance ID to position   
        uint256[10] toBeSigned;
    }
    
    event askingCert (uint256 insuranceID);
    event claimingFromComp (uint256 insuranceID);

    uint256 public numStakeholder = 0;
    mapping(uint256 => stakeholder) public stakeholders; //stakeholder ID to stakeholder
    mapping(address => uint256) ids; //stakeholder address to id

    //Modifiers
    modifier onlyPolicyOwner(policyOwnerID) {
        require(msg.sender == stakeholders[policyOwnerID].stakeholderAddress);
        _;
    } 

    modifier validNumber(string memory s) {
        uint256 len;
        uint256 i = 0;
        uint256 bytelength = bytes(s).length;
        bytes1 char = b[0];

        for (len = 0; i < bytelength; len++) {
            bytes1 b = bytes(s)[i];
            if (b < 0x80) {
                i += 1;
            } else if (b < 0xE0) {
                i += 2;
            } else if (b < 0xF0) {
                i += 3;
            } else if (b < 0xF8) {
                i += 4;
            } else if (b < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }

        require(len == 8, "Invalid length of phone number!");
        _;
    }


    //Functions
    function addStakeholder(string memory _phonenum) public validNumber(_phonenum) returns(int256) {
        uint256 newID = numStakeholder++;
        stakeholder memory newStakeholder = stakeholder(
            newID,
            msg.sender,
            keccak256(abi.encode(_phonenum))
        );
        stakeholders[newID] = newStakeholder;
        ids[msg.sender] = newID;
        return newID;
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

    function addToSignList(uint256 insuraneID,uint256 policyOwnerID) public returns(bool){
        require(stakeholders[policyOwnerID].toBeSigned[9] == 0);
        stakeholders[policyOwnerID].toBeSigned.push(insuranceID);
        return true;
    }

    // function payPremium(uint256 insuranceID, uint256 amount, uint256 policyOwnerID) public onlyPolicyOwner(policyOwnerID){
    //     address memory companyAddress = insuranceContract.getInsuranceCompany(insuranceID);
    //     marketContract.transfer(msg.sender,companyAddress,amount);

    //     //mark as paid
    // }

    function getMCidAndPassToComp(uint256 insuranceID) public {
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

    function checkInsuranceRequests(uint256 companyId, uint256 requestId) public returns (InsuranceCompany.requestStatus) {
        return InsuranceCompany.checkRequestsFromStakeholder(companyId, requestId);
    }

    function checkMCRequests(uint256 memory _hospitalId, uint256 _requestId, uint256 _stakeholderId) public 
    returns(bytes32)
    {
        return hospitalContract.checkMCIdFromStakeholder(_hospitalId, _requestId,_stakeholderId);
    }

    //Getters
    function getStakeholder(uint256 stakeholderID) public view returns(Stakeholder){
        return stakeholders[stakeholderID];
    }

    function getInvolvingInsurances(uint256 stakeholderID) public view returns(mapping(uint256 => position)){
        return stakeholders[stakeholderID].involvingInsurances;
    }
    
    function getStakeholderId(address _stakeholder) public view returns(uint256) {
        return ids[_stakeholder];
    }
    
    //need to restrict access for this. cannot anyone could get the phonenumber.
    //company check request => get stakeholder phone
    //how to restrict so that only checkrequest function could access this
    function getStakeholderPhone(uint256 stakeholderID) public view returns(string memory) {
        return abi.decode(stakeholders[stakeholderID].phonenum);
    }
    
}