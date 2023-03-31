pragma solidity ^0.8.12;
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
        string name;
        bytes NRIC;
        address stakeholderAddress;
        bytes phonenum;
        mapping(uint256 => position) involvingInsurances; //insurance ID to position   
        uint256[] toBeSigned;
    }
    
    event askingCert (uint256 insuranceID);
    event claimingFromComp (uint256 insuranceID, bytes mcId);

    uint256 public numStakeholder = 0;
    mapping(uint256 => stakeholder) public stakeholders; //stakeholder ID to stakeholder
    mapping(address => uint256) ids; //stakeholder address to id

    //Modifiers
    modifier onlyPolicyOwner(uint256 policyOwnerID) {
        require(msg.sender == stakeholders[policyOwnerID].stakeholderAddress);
        _;
    } 

    modifier validNumber(string memory s) {
        require(bytes(s).length == 8, "Invalid length of phone number!");
        _;
    }


    //Functions
    // /** 
    // * @dev create new stakeholder
    // * @return uint256 id of new stakeholder
    // */
    function addStakeholder(string memory _phonenum,string memory name,string memory NRIC) public validNumber(_phonenum) returns(uint256) {
       
        stakeholder storage newStakeholder = stakeholders[numStakeholder++];
        newStakeholder.ID = numStakeholder;
        newStakeholder.name = name;
        newStakeholder.stakeholderAddress = msg.sender;
        newStakeholder.NRIC = abi.encodePacked(NRIC);
        newStakeholder.phonenum = abi.encodePacked(_phonenum);
        newStakeholder.toBeSigned = new uint256[](10);

        ids[msg.sender] = numStakeholder;
        return numStakeholder;
    }

    // /** 
    // * @dev sign insurance from tobesigned list and pay for insurance
    // */
    function signInsurance(uint256 _policyOwnerID,uint256 _insuranceID, uint256 _beneficiaryID, uint256 _lifeAssuredID,uint256 _offerPrice) public {
        // require offerPrice >= owningMoney
        // require insurance ID valid

        bool doesListContainElement = false;
        uint256 index;
        uint256 signedlength = stakeholders[_policyOwnerID].toBeSigned.length;
        for (uint i=0; i < signedlength; i++) {
            if (_insuranceID == stakeholders[_policyOwnerID].toBeSigned[i]) {
                doesListContainElement = true;
                index = i;
                break;
            }
        }
        
        require(doesListContainElement == true, "Invalid insurance id!");
        
        stakeholders[_policyOwnerID].toBeSigned[index] = stakeholders[_policyOwnerID].toBeSigned[signedlength - 1];
        stakeholders[_policyOwnerID].toBeSigned.pop();

        stakeholders[_policyOwnerID].involvingInsurances[_insuranceID] = position.policyOwner;
        stakeholders[_beneficiaryID].involvingInsurances[_insuranceID] = position.beneficiary;
        stakeholders[_lifeAssuredID].involvingInsurances[_insuranceID] = position.lifeAssured;
        uint256 companyAddress = insuranceContract.getInsuranceCompany(_insuranceID); // this returns id not address
        //whats this doing ah?!
        //marketContract.transfer(msg.sender,companyAddress,_offerPrice);

        insuranceCompanyContract.signInsurance(_insuranceID, insuranceContract.getInsuranceCompany(_insuranceID));

    }

    // /** 
    // * @dev add the insurance pass from company to sign list of stakeholder
    // * @return bool indicating sign successfully
    // */
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

    // /** 
    // * @dev get MC id and pass to company
    // Call auto transfer in company contract to claim the money
    // */
    function getMCidAndPassToComp(uint256 insuranceId,uint256 companyId,uint256 hospitalId,bytes memory mcId) public {
        // uint MDid = 
        insuranceCompanyContract.autoTransfer(insuranceId, companyId,  hospitalId, mcId);
    }
    
    // /** 
    // * @dev Stakeholder ask hospital for mc and call company to claim money
    // */
    function claim(uint256 insuranceID,uint256 companyId, bytes memory mcId,uint256 hospitalId,uint256 policyOwnerID) public onlyPolicyOwner(policyOwnerID){
        //step1: ask for cert from hospital
        emit askingCert(insuranceID);

        //step2: tell insurance company to pay back
        insuranceCompanyContract.autoTransfer(insuranceID, companyId,  hospitalId, mcId);
        emit claimingFromComp(insuranceID,mcId);
    }

    function checkInsuranceRequests(uint256 companyId, uint256 requestId) public returns (InsuranceCompany.requestStatus) {
        return insuranceCompanyContract.checkRequestsFromStakeholder(companyId, requestId);
    }

    function checkMCRequests(uint256 _hospitalId, uint256 _requestId, uint256 _stakeholderId) public 
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
    
    //need to restrict access for this. cannot anyone could get the phonenumber.
    //company check request => get stakeholder phone
    //how to restrict so that only checkrequest function could access this
    function getStakeholderPhone(uint256 stakeholderID) public view returns(string memory num) {
        (num) = abi.decode(stakeholders[stakeholderID].phonenum, (string));
        return num;
    }

    function getStakeholderAddress(uint256 stakeholderID) public view returns(address) {
        return stakeholders[stakeholderID].stakeholderAddress;
    }

    function getStakeholderName(uint256 stakeholderID) public view returns(string memory) {
        return stakeholders[stakeholderID].name;
    }

    function getStakeholderNRIC(uint256 stakeholderID) public view returns(bytes memory) {
        return stakeholders[stakeholderID].NRIC;
    }
    
}