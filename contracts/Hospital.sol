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
        bytes mcid;
    }
    
    uint256 numOfReqs = 0;

    // events
    event registered();
    event createOneMC();
    event presidentChanged();
    event requestSolve(uint256 requestId);
    event requestMade(uint256 reqeustId);
    event liveRequest(uint256[] requestids,
        uint256[] stakeholderids,
        string[] names,
        string[] ics);

    //modifiers
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
        require(bytes(s).length == 8, "Invalid date!");
        _;
    }

    
    //since below function already check validity no need here
    // modifier validRequest(uint256  _hospitalId, uint256 _stakeholderId, uint256 _requestId) {
    //    require(registeredHospital[_hospitalId].requests[_stakeholderId] > 0, "You didn't make request!");
    //     _;
    // }
    
    //functions


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
        
        emit registered();
        return totalHospital;
    }

    function createPersonalInfo (uint256 hospitalId, string memory password, 
    string memory name, string memory NRIC, string memory sex, 
                string memory birthdateYYYYMMDD, string memory race_nationality) 
    public validHospital(hospitalId) verifyPassword(hospitalId,password)  validDate(birthdateYYYYMMDD)
    override returns (uint256) {
        numOfPeople++;
        personalInfo storage person = infos[numOfPeople];
        person.name = name;
        person.NRIC = NRIC;
        person.sex = sex;
        person.birthdate = birthdateYYYYMMDD;
        person.race_nationality = race_nationality;

        return numOfPeople;
    }

    function addMC(uint256 hospital, string memory password, uint256 personId,
    certCategory incidentType, string memory incidentYYYYMMDDHHMM, 
    string memory certifierName
    ) 
    public validHospital(hospital) verifyPassword(hospital,password) validDate(incidentYYYYMMDDHHMM)
    override returns(bytes memory) {
        counter = counter + 1;
        bytes memory id = abi.encodePacked(counter, personId);


        medicalCert memory mc = MC[keccak256(id)];
        mc.ID = id;
        mc.HospitalID = hospital;
        mc.personal_info = infos[personId];
        mc.incident = incidentType;
        mc.dateTimeIncident = incidentYYYYMMDDHHMM;
        mc.titleOfCertifier = certifierName;

        emit mcCreated(counter);

        return id;    
    }
    
    function solveRequest(uint256 hospitalId, string memory password, bytes memory mcId,
    uint256 requestId, uint256 stakeholderId) 
    public validHospital(hospitalId) verifyPassword(hospitalId,password) 
    returns(bytes memory)
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
                reqs[index].mcid = mcId;
                emit requestSolve(requestId);
            }
        }        
        

    }

    //  /** 
    // * @dev stakeholder request to create MC
    // * @param hospitalId the hospital id 
    // * @param stakeholderId the stakeholder Id
    // * @param nameAssured the assured person's name
    // * @param icAssured the assured person's NRIC
    // * @return uint256 number of requests
    // */
    function requestMC(uint256 hospitalId, uint256 stakeholderId, string memory nameAssured, string memory icAssured) 
    public validHospital(hospitalId) returns(uint256) {
        //require(stakeholderContract.getStakeholderId(msg.sender) == stakeholderId, "Invalid stakeholder!");
  
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

    // /** 
    // * @dev check requests from hospital
    // * @param _hospitalId the hospital id 
    // * @param _password password to register
    // */
    function checkRequestFromHospital (uint256 _hospitalId, string memory _password) 
    public validHospital(_hospitalId) verifyPassword(_hospitalId,_password) 
    {
        uint256[] memory requestids = new uint256[](numOfReqs);
        uint256[] memory stakeholderids = new uint256[](numOfReqs);
        string[] memory names = new string[](numOfReqs);
        string[]memory ics = new string[](numOfReqs);

        uint256[] memory requestedstakeholders = stakeholders[_hospitalId];

        uint256 total_reqs = 0;

        for (uint256 i = 0; i < requestedstakeholders.length; i++) {
            uint256 stakeholderId = requestedstakeholders[i];
            Request[] memory reqs = registeredHospital[_hospitalId].requests[stakeholderId];
            for(uint256 j = 0; j < reqs.length; j++) {
                Request memory req = reqs[j];
                
                if (keccak256(abi.encodePacked(req.mcid)) != keccak256(abi.encodePacked(bytes("0x")))) {
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

    // /** 
    // * @dev check mc Ids from stakeholder
    // * @param _hospitalId hospital id
    // * @param _requestId whether the MC is for some request
    // * @param _stakeholderId if it's a request, what's the stakeholder id
    // * @return  byte32 mcId
    // */
    function checkMCIdFromStakeholder(uint256 _hospitalId, uint256 _requestId, uint256 _stakeholderId)
      public view validHospital(_hospitalId) //validRequest(_hospitalId, _stakeholderId,_requestId) 
      returns(bytes memory)
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
    * @param password password to register
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
        registeredHospital[ hospitalId].password = abi.encode(newpassword,"password");
    }


    //getters
    function getHospitalId(address president) public view returns(uint256) {
        return ids[president];
    }

    function getPresident(uint256 hospitalId) public view returns(address) {
        return  registeredHospital[ hospitalId].president;
    }

    function getPassword(uint256 hospitalId) 
        public view 
        onlyOwner(hospitalId) 
        returns(string memory) 
    {
        (string memory password, string memory s) = abi.decode(registeredHospital[hospitalId].password, (string,string));
        return password;
    }

    // function getMC(uint256 _hospitalId, bytes memory  _mcId) 
    //     public view 
    //     validMCId(_hospitalId,_mcId)
    //     returns (uint256, string memory, string memory, uint256, uint256, string memory, string memory, MedicalCertificate.certCategory, string memory, string memory, string memory, string memory, string memory)
    // {
    //     return medicalCert.getMC(_mcId);
    // }

}