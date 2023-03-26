pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;
import "./MedicalCert.sol";
import "./StringLength.sol";
import "./Stakeholder.sol";

contract Hospital {
    StringLength stringlen;
    MedicalCertificate medicalCert;
    Stakeholder stakeholderContract;

    mapping(uint256 => hospital) registeredHospital; //hospital id => hospital
    mapping(address => uint256) ids; //president => hospital id
    mapping(uint256 => uint256[]) stakeholders; //hospital id => requested stakeholder;

    uint256 totalHospital = 0;

    constructor (MedicalCertificate mcAddress, Stakeholder stakeholderAddress) public  {
        medicalCert = mcAddress;
        stakeholderContract = stakeholderAddress;
    }
  
    struct hospital {
        address president; //owner of the hospital
        bytes32 president_ic; //the identity of owner
        bytes32 password; //passward needed to create MC
        uint256 hospitalId; //id
        mapping(bytes32 => address) mcs; // mc id => who create the mc
        mapping(uint256 => Request[]) requests; //stakeholderId -> requests
    }

    struct Request {
        uint256 reqId;
        uint256 stakeholderId;
        string nameAssured;
        string icAssured;
        bytes32 mcid;
    }
    
    uint256 numOfReqs = 0;

    // events
    event registered();
    event createOneMC();
    event presidentChanged();
    event requestSolve(uint256 requestId, bytes32 mcId);
    event requestMade(uint256 reqeustId);
    event liveRequest(uint256[] requestids,
        uint256[] stakeholderids,
        string[] names,
        string[] ics);

    //modifiers
    modifier validHospital(uint256 _hospitalId) {
        require(registeredHospital[_hospitalId] != hospital(0), "Invalid hospital id!");
        _;
    }
    modifier validIC(string memory _ic) {
        require(stringlen.strlen(_ic), "invalid NRIC number");
        _;
    }

    modifier onlyOwner(uint256 _hospitalId) {
        require (msg.sender == registeredHospital[ _hospitalId].president, "Unauthorized!");
        _;
    }

    modifier verifyPassword(uint256 _hospitalId, string memory _password) {
        require (keccak256(abi.encode(_password)) == registeredHospital[ _hospitalId].password, "Wrong password!");
        _;
    }

    modifier validMCId(uint256 _hospitalId, bytes32 _mcId) {
        require(registeredHospital[_hospitalId].mcs[_mcId] != address(0), "Wrong hospitalId or MCId!");
        _;
    }

    modifier validRequest(uint256  _hospitalId, uint256 _stakeholderId) {
       require(registeredHospital[_hospitalId].requests[_stakeholderId] != 0, "You didn't make request!");
        _;
    }
    
    //functions


     /** 
    * @dev register the hospital on chain
    * @return uint256 registered hospital id
    */
    function register(string memory _ic, string memory _password) public validIC(_ic) returns(uint256) {
        hospital memory newHospital = hospital({
            predisent:msg.sender,
            predisent_ic:keccak256(abi.encode(_ic)),
            password: keccak256(abi.encode(_password)),
            hospitalId: totalHospital
        });
        
        uint newHospitalId = totalHospital;
        registeredHospital[newHospitalId] = newHospital;
        ids[msg.sender] = newHospitalId;
        totalHospital++;
        emit registered();
        return newHospitalId;
    }

    //MC
     /** 
    * @dev create MC with required information
    * @return  byte32 mc Id
    */
    function createMC(uint256 _hospitalId, string memory _password, uint256 _requestId, uint256 _stakeholderId,
                string memory name, string memory NRIC, uint256 sex, 
                uint256 birthdate, string memory race, string memory nationality, 
                MedicalCertificate.certCategory incidentType, string memory incidentYYYYMMDDHHMM, 
                string memory place, string memory cause, string memory titleName, string memory institution) 
                public validHospital(_hospitalId) verifyPassword(_password) 
                returns(bytes32)
    {
        bytes32 mcId = medicalCert.add(
                _hospitalId,
                name,
                NRIC,
                sex,
                birthdate,
                race,
                nationality,
                incidentType,
                //incidentYYYYMMDDHHMM,
                place,
                cause,
                titleName,
                institution);
            registeredHospital[_hospitalId].mcs[mcId] = msg.sender;
        emit createOneMC();

        if (_requestId != 0) {
            require(registeredHospital[_hospitalId].requests[_stakeholderId] != 0, "Invalid request id!");
            
            Request[] memory reqs = registeredHospital[_hospitalId].requests[_stakeholderId];
            uint256 length = reqs.length;
            bool find = false;
            uint256 index;
            for (uint256 i = 0; i < length; i++) {
                if (reqs[i].reqId == _requestId) {
                    index = i;
                    find = true;
                }
            }
            
            require(find == true, "Invalid request id!");
            if (find) {
                reqs[index].mcid = mcId;
                emit requestSolve(_requestId,mcId);
            }
        }        
        
        return mcId;
    }

     /** 
    * @dev stakeholder request to create MC
    * @return uint256 number of requests
    */
    function requestMC(uint256 hospitalId, uint256 stakeholderId, string memory nameAssured, string memory icAssured) 
    public validHospital(hospitalId) returns(uint256) {
        require(stakeholderContract.getStakeholderId(msg.sender) == stakeholderId, "Invalid stakeholder!");

        Request memory req = Request(
            numOfReqs++,
            stakeholderId,
            nameAssured,
            icAssured,
            bytes(0)
        );
        
        registeredHospital[hospitalId].requests[stakeholderId].push(req);
        stakeholders[hospitalId].push(stakeholderId);
        emit requestMade(numOfReqs);
        return numOfReqs;
    }

    /** 
    * @dev check requests from hospital
    */
    function checkRequestFromHospital (uint256 _hospitalId, string memory _password) 
    public validHospital(_hospitalId) verifyPassword(_password) 
    {
        uint256[] memory requestids;
        uint256[] memory stakeholderids;
        string[] memory names;
        string[]memory ics;

        uint256[] memory requestedstakeholders = stakeholders[_hospitalId];

        for (uint256 i = 0; i < requestedstakeholders.length; i++) {
            uint256 stakeholderId = requestedstakeholders[i];
            Request[] memory reqs = registeredHospital[_hospitalId].requests[stakeholderId];
            for(uint256 j = 0; j < reqs.length; j++) {
                Request memory req = reqs[j];
                
                if (req.mcid != bytes(0)) {
                    requestids.push(req.reqId);
                    stakeholderids.push(req.stakeholderId);
                    names.push(req.nameAssured);
                    ics.push(req.icAssured);
                }
            }            
        }

        emit liveRequest(requestids,stakeholderids, names,ics);
    }

    /** 
    * @dev check mc Ids from stakeholder
    * @return  byte32 mcId
    */
    function checkMCIdFromStakeholder(uint256 _hospitalId, uint256 _requestId, uint256 _stakeholderId)
      public validHospital(_hospitalId) validRequest(_hospitalId, _stakeholderId) 
      returns(bytes32)
    {
        Request[] memory reqs = registeredHospital[_hospitalId].requests[_stakeholderId];
        uint256 length = reqs.length;
        bool find = false;
        uint256 index;
        for (uint256 i = 0; i < length; i++) {
            if (reqs[i].reqId == _requestId) {
                index = i;
                find = true;
            }
        }
        
        require(find == true, "Invalid request id!");
        if (find) {
            return reqs[index].mcid;
        }         
    }
    /** 
    * @dev change president of hospital
    */
    function changePresident(uint256 _hospitalId, string memory _password, string memory _ic) 
    public verifyPassword(_password) validIC(_ic)
    {
        registeredHospital[ _hospitalId].president = msg.sender;
        registeredHospital[ _hospitalId].president_ic = keccak256(abi.encode(_ic));
        emit presidentChanged();
    }

    /** 
    * @dev change password of hospital
    */
    function changePassword(uint256 _hospitalId, string memory oldpassword, string memory newpassword)
    public onlyOwner(_hospitalId) verifyPassword(oldpassword)
    {
        registeredHospital[ _hospitalId].password = keccak256(abi.encode(newpassword));
    }


    //getters
    function getHospitalId(address _president) public view returns(uint256) {
        return ids[_president];
    }

    function getPresident(uint256 _hospitalId) public view returns(address) {
        return  registeredHospital[ _hospitalId].president;
    }

    function getPassword(uint256 _hospitalId, string memory _password) 
        public view 
        onlyOwner(_hospitalId) 
        returns(string memory) 
    {
        return abi.decode(registeredHospital[ _hospitalId].password, string);
    }

    function getMC(uint256 _hospitalId, bytes32 _mcId) 
        public view 
        validMCId(_hospitalId,_mcId)
        returns (uint256, string memory, string memory, uint256, uint256, string memory, string memory, MedicalCertificate.certCategory, string memory, string memory, string memory, string memory, string memory)
    {
        return medicalCert.getMC(_mcId);
    }

}