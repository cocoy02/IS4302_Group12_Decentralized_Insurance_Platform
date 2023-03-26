pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;
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
        mapping(uint256 => Insurance) involvingInsurances; //insurance ID to position   
        uint256[10] toBeSigned;
    }
    
    event askingCert (uint256 insuranceID);
    event claimingFromComp (uint256 insuranceID);

    uint256 public numStakeholder = 0;
    mapping(uint256 => stakeholder) public stakeholders; //stakeholder ID to stakeholder
    mapping(address => uint256) ids; //stakeholder address to id

    //Modifiers
    modifier onlyPolicyOwner(uint256 policyOwnerID) {
        require(msg.sender == stakeholders[policyOwnerID].stakeholderAddress);
        _;
    } 

    modifier validNumber(string memory s) {
        uint256 len;
        uint256 i = 0;
        uint256 bytelength = bytes(s).length;
        bytes1 char = bytes(s)[0];

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
    function signInsurance(uint256 _policyOwnerID,uint256 _insuranceID, uint256 _beneficiaryID, uint256 _lifeAssuredID,uint256 _offerPrice) public {
        // require offerPrice >= owningMoney
        // require insurance ID valid

        bool doesListContainElement = false;
        uint256 index;
        for (uint i=0; i < stakeholders[_policyOwnerID].toBeSigned.length; i++) {
            if (_insuranceID == stakeholders[_policyOwnerID].toBeSigned[i]) {
                doesListContainElement = true;
                index = i;
                break;
            }
        }
        
        require(doesListContainElement == true, "Invalid insurance id!");
        stakeholders[_policyOwnerID].toBeSigned.remove(index);


        stakeholders[_policyOwnerID].involvingInsurances[_insuranceID] = position.policyOwner;
        stakeholders[_beneficiaryID].involvingInsurances[_insuranceID] = position.beneficiary;
        stakeholders[_lifeAssuredID].involvingInsurances[_insuranceID] = position.lifeAssured;
        address companyAddress = insuranceContract.getInsuranceCompany(_insuranceID);
        marketContract.transfer(msg.sender,companyAddress,_offerPrice);


    }

    function addToSignList(uint256 _insuranceID,uint256 _policyOwnerID) public returns(bool){
        require(stakeholders[_policyOwnerID].toBeSigned[9] == 0);
        stakeholders[_policyOwnerID].toBeSigned.push(_insuranceID);
        return true;
    }

    // function payPremium(uint256 insuranceID, uint256 amount, uint256 policyOwnerID) public onlyPolicyOwner(policyOwnerID){
    //     address memory companyAddress = insuranceContract.getInsuranceCompany(insuranceID);
    //     marketContract.transfer(msg.sender,companyAddress,amount);

    //     //mark as paid
    // }

    function getMCidAndPassToComp(uint256 insuranceId,uint256 companyId,uint256 hospitalId,bytes32 mcId) public {
        // uint MDid = 
        insuranceCompanyContract.autoTransfer(insuranceId, companyId,  hospitalId, mcId);
    }

    function claim(uint256 insuranceID,uint256 companyId, byte mcId,uint256 hospitalId,uint256 policyOwnerID) public onlyPolicyOwner(policyOwnerID){
        //step1: ask for cert from hospital
        emit askingCert(insuranceID);

        //step2: tell insurance company to pay back
        insuranceCompanyContract.autoTransfer(insuranceID, companyId,  hospitalId, mcId);
        emit claimingFromComp(insuranceID,mcId);
    }

    function checkInsuranceRequests(uint256 companyId, uint256 requestId) public returns (InsuranceCompany.requestStatus) {
        return InsuranceCompany.checkRequestsFromStakeholder(companyId, requestId);
    }

    function checkMCRequests(uint256 _hospitalId, uint256 _requestId, uint256 _stakeholderId) public 
    returns(bytes32)
    {
        return hospitalContract.checkMCIdFromStakeholder(_hospitalId, _requestId,_stakeholderId);
    }

    //Getters
    function getStakeholder(uint256 stakeholderID) public view returns(Stakeholder){
        return stakeholders[stakeholderID];
    }

    function getInvolvingInsurances(uint256 stakeholderID, uint256 insuranceID) public view returns(Insurance){
        return stakeholders[stakeholderID].involvingInsurances[insuranceID];
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

    function getStakeholderAddress(Stakeholder stakeholderID) public view returns(address) {
        return stakeholderID.stakeholderAddress;
    }
    
}