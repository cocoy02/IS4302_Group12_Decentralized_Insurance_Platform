pragma solidity ^0.8.12;
pragma experimental ABIEncoderV2;
import "./MedicalCert.sol";

contract Hospital is MedicalCertificate  {

    mapping(uint256 => hospital) registeredHospital; //hospital id => hospital
    mapping(address => uint256) ids; //president => hospital id
    mapping(uint256 => uint256[]) stakeholders; //hospital id => requested stakeholder;

    uint256 totalHospital = 0;
  
    struct hospital {
        address president; //owner of the hospital
        bytes president_ic; //the identity of owner
        bytes password; //passward needed to create MC
        uint256 hospitalId; //id
        mapping(bytes => address) mcs; // mc id => who create the mc
        mapping(uint256 => Request[]) requests; //stakeholderId -> requests
    }

    struct Request {
        uint256 reqId;
        uint256 stakeholderId;
        string nameAssured;
        string icAssured;
        uint256 mcid;
    }
    
    uint256 hospitalCounter = 0;
    uint256 numOfReqs = 0;

    uint256 numOfPeople = 0;

    // events
    event registered(uint256 hospitalId);
    event createOneMC();
    event presidentChanged();
    event requestSolve(uint256 requestId);
    event requestMade(uint256 reqeustId);
    event liveRequest(uint256[] requestids,
        uint256[] stakeholderids,
        string[] names,
        string[] ics);

// =====================================================================================
// modifiers
// =====================================================================================

    modifier validHospital(uint256 _hospitalId) {
        require(registeredHospital[_hospitalId].hospitalId > 0, "Invalid hospital id!");
        _;
    }
    modifier validIC(string memory _ic) {
        require(bytes(_ic).length == 9, "invalid NRIC number");
        _;
    }

    modifier onlyOwner(uint256 _hospitalId) {
        require (msg.sender == registeredHospital[ _hospitalId].president, "Unauthorized!");
        _;
    }

    modifier verifyPassword(uint256 _hospitalId, string memory _password) {
        require (keccak256(abi.encode(_password,"password")) == keccak256(registeredHospital[ _hospitalId].password), "Wrong password!");
        _;
    }

    modifier validMCId(uint256 _hospitalId, bytes memory  _mcId) {
        require(registeredHospital[_hospitalId].mcs[_mcId] != address(0), "Wrong hospitalId or MCId!");
        _;
    }

    modifier validDate(string memory s) {
        require(bytes(s).length == 8, "Invalid birth date!");
        _;
    }
    modifier validIncidentDate(string memory s) {
        require(bytes(s).length == 12, "Invalid incident date!");
        _;
    }
    
// =====================================================================================
// functions
// =====================================================================================

     /** 
    * @dev register the hospital on chain
    * @param NRIC president NRIC
    * @param password password to register
    * @return uint256 registered hospital id
    */
    function register(string memory NRIC, string memory password) public payable validIC(NRIC) returns(uint256) {
        require(msg.value >= 0.01 ether, "0.01 ETH is needed to register your hospital");

        totalHospital++;
        hospital storage newHospital = registeredHospital[totalHospital];

        newHospital.president =  msg.sender;
        newHospital.president_ic = abi.encode(NRIC,"ic");
        newHospital.password =  abi.encode(password,"password");
        newHospital.hospitalId =  totalHospital;
        
        
        ids[msg.sender] = totalHospital;
        
        emit registered(totalHospital);
        return totalHospital;
    }

    /**
    * @dev Create information profile for the assured person
    * @param hospitalId hospital id
    * @param password password for hospital
    * @param name the name of the person who has accident
    * @param NRIC the NRIC of the person who has accident
    * @param sex the sexof the person who has accident
    * @param birthdateYYYYMMDD the birthdate of the person who has accident
    * @param race_nationality the race and nationality of the person who has accident
    * @return uint256 number of people
     */
    function createPersonalInfo (
        uint256 hospitalId, string memory password, 
        string memory name, string memory NRIC, string memory sex, 
        string memory birthdateYYYYMMDD, string memory race_nationality) 
    public validHospital(hospitalId) verifyPassword(hospitalId,password) validDate(birthdateYYYYMMDD)
    override returns (uint256) {
        numOfPeople++;
        personalInfo storage person = infos[numOfPeople];
        person.personId = numOfPeople;
        person.name = name;
        person.NRIC = NRIC;
        person.sex = sex;
        person.birthdate = birthdateYYYYMMDD;
        person.race_nationality = race_nationality;

        return numOfPeople;
    }

    /**
    * @dev Create the medical certificate for the injured or dead person
    * @param hospital the id of the hospital
    * @param password password for hospital
    * @param personId the id of the person who has accident
    * @param incidentType0incident1death2suicide the incident type of accident where 0 is incident 1 is death and 2 is suicide
    * @param incidentYYYYMMDDHHMM the incident date and time of the incident
    * @param certifierName the certifier of the MC of the accident
    * @return uint256 MC id in bytes
     */
    function addMC(
        uint256 hospital, string memory password, uint256 personId,
        certCategory incidentType0incident1death2suicide, string memory incidentYYYYMMDDHHMM, 
        string memory certifierName
    ) 
    public validHospital(hospital) verifyPassword(hospital,password) validIncidentDate(incidentYYYYMMDDHHMM)
    override returns(uint256) {
        hospitalCounter++;

        medicalCert storage mc = MC[hospitalCounter];
        
        mc.ID = hospitalCounter;
        mc.HospitalID = hospital;
        mc.personal_info = personId;
        mc.incident = incidentType0incident1death2suicide;
        mc.dateTimeIncident = incidentYYYYMMDDHHMM;
        mc.titleOfCertifier = certifierName;

        emit mcCreated(hospitalCounter);

        return hospitalCounter;    
    }

    /**
    * @dev Create the medical certificate for the injured or dead person
    * @param hospitalId the id of the hospital
    * @param password password for hospital
    * @param mcId the mc id of the request
    * @param requestId the id of the request
    * @param stakeholderId the id of the stakeholder
     */
    function solveRequest(
        uint256 hospitalId, string memory password, uint256 mcId,
        uint256 requestId, uint256 stakeholderId) 
    public validHospital(hospitalId) verifyPassword(hospitalId,password) 
    {

        if (requestId != 0) {
            require(registeredHospital[hospitalId].requests[stakeholderId].length > 0, "Not request yet!");
            
            Request[] memory reqs = registeredHospital[hospitalId].requests[stakeholderId];
            uint256 length = reqs.length;
            bool find = false;
            uint256 index;
            for (uint256 i = 0; i < length; i++) {
                if (reqs[i].reqId == requestId) {
                    index = i;
                    find = true;
                }
            }
            
            require(find == true, "Invalid request id!");
            if (find) {
                registeredHospital[hospitalId].requests[stakeholderId][index].mcid = mcId;
                emit requestSolve(requestId);
            }
        }        
    
    }

    /** 
    * @dev stakeholder request to create MC
    * @param hospitalId the hospital id 
    * @param stakeholderId the stakeholder Id
    * @param nameAssured the assured person's name
    * @param icAssured the assured person's NRIC
    * @return uint256 number of requests
    */
    function requestMC(
        uint256 hospitalId, uint256 stakeholderId, 
        string memory nameAssured, string memory icAssured) 
    external validHospital(hospitalId) returns(uint256) 
    {     
        numOfReqs++;
        Request storage req =  registeredHospital[hospitalId].requests[stakeholderId].push();
        req.reqId = numOfReqs;
        req.stakeholderId = stakeholderId;
        req.nameAssured = nameAssured;
        req.icAssured = icAssured;
        
        stakeholders[hospitalId].push(stakeholderId);
        emit requestMade(numOfReqs);
        return numOfReqs;
    }

    /** 
    * @dev check requests from hospital
    * @param hospitalId the hospital id 
    * @param password password to register
    */
    function checkRequestFromHospital (uint256 hospitalId, string memory password) 
    public validHospital(hospitalId) verifyPassword(hospitalId,password) 
    {
        uint256[] memory requestids = new uint256[](numOfReqs);
        uint256[] memory stakeholderids = new uint256[](numOfReqs);
        string[] memory names = new string[](numOfReqs);
        string[]memory ics = new string[](numOfReqs);

        uint256[] memory requestedstakeholders = stakeholders[hospitalId];

        uint256 total_reqs = 0;

        for (uint256 i = 0; i < requestedstakeholders.length; i++) {
            uint256 stakeholderId = requestedstakeholders[i];
            Request[] memory reqs = registeredHospital[hospitalId].requests[stakeholderId];
            for(uint256 j = 0; j < reqs.length; j++) {
                Request memory req = reqs[j];
                
                if (req.mcid == 0) {
                //if (keccak256(abi.encodePacked(req.mcid)) != keccak256(abi.encodePacked(bytes("0x")))) {
                    requestids[total_reqs] = req.reqId;
                    stakeholderids[total_reqs] = req.stakeholderId;
                    names[total_reqs] = req.nameAssured;
                    ics[total_reqs] = req.icAssured;
                    total_reqs++;
                }
            }            
        }

        emit liveRequest(requestids,stakeholderids, names,ics);
    }

    /** 
    * @dev check mc Ids from stakeholder
    * @param _hospitalId hospital id
    * @param _requestId whether the MC is for some request
    * @param _stakeholderId if it's a request, what's the stakeholder id
    * @return uint256 mcId
    */
    function checkMCIdFromStakeholder(uint256 _hospitalId, uint256 _requestId, uint256 _stakeholderId)
      external view validHospital(_hospitalId) 
      returns(uint256)
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
    * @param NRIC president NRIC
    * @param password password of hospital
    * @param hospitalId hospital id
    */
    function changePresident(uint256 hospitalId, string memory password, string memory NRIC)
    public verifyPassword(hospitalId,password) validIC(NRIC)
    {
        registeredHospital[ hospitalId].president = msg.sender;
        registeredHospital[ hospitalId].president_ic = abi.encode(NRIC,"ic");
        emit presidentChanged();
    }

    /** 
    * @dev change password of hospital
    * @param oldpassword old password needed to change
    * @param newpassword the new password
    */
    function changePassword(uint256 hospitalId, string memory oldpassword, string memory newpassword)
    public onlyOwner(hospitalId) verifyPassword(hospitalId,oldpassword)
    {
        registeredHospital[hospitalId].password = abi.encode(newpassword,"password");
    }


// =====================================================================================
// getters
// =====================================================================================
    
    /** 
    * @dev Get the hospital Id
    * @param president president of hospital
    * @return uint256 hospital id
    */
    function getHospitalId(address president) public view returns(uint256) {
        return ids[president];
    }

    /** 
    * @dev Get the president of hospital
    * @param hospitalId id of hospital
    * @return address president
    */
    function getPresident(uint256 hospitalId) public view returns(address) {
        return  registeredHospital[ hospitalId].president;
    }

    /** 
    * @dev Get the password of hospital
    * @param hospitalId id of hospital
    * @return string password
    */
    function getPassword(uint256 hospitalId) 
        public view 
        onlyOwner(hospitalId) 
        returns(string memory) 
    {
        (string memory password, string memory s) = abi.decode(registeredHospital[hospitalId].password, (string,string));
        return password;
    }

    /** 
    * @dev Get number of requests
    * @return uint256 number of requests
    */
    function getNumOfReqs() public view returns(uint256) {
        return numOfReqs;
    }

    /** 
    * @dev Get number of people
    * @return uint256 number of people
    */
    function getNumOfPeople() public view returns(uint256) {
        return numOfPeople;
    }

    /** 
    * @dev Get number of hospital
    * @return uint256 number of hospital
    */
    function getHospitalCounter() public view returns(uint256) {
        return hospitalCounter;
    }
}