pragma solidity ^0.8.12;
pragma experimental ABIEncoderV2;

contract MedicalCertificate {
    uint256 counter = 0;

    enum certCategory{
        incident,
        death,
        suicide
    }

    struct personalInfo {
        uint256 personId;
        string name;
        string NRIC;
        string sex;
        uint256 birthdate; //YYYYMMDD
        string race_nationality;
    }

    struct medicalCert{
        bytes ID;
        uint256 HospitalID;
        personalInfo personal_info;
        certCategory incident;
        string dateTimeIncident; //YYYYMMDDHHMM
        string titleOfCertifier;
    }

    mapping(bytes32 => medicalCert) public MC;
    mapping(uint256 => personalInfo) public infos;

    uint256 numOfPeople = 0;
    event mcCreated(uint256 numMC);


    function createPersonalInfo (string memory name, string memory NRIC, string memory sex, 
                uint256 birthdateYYYYMMDD, string memory race_nationality) public  returns (uint256) {
        numOfPeople++;
        personalInfo storage person = infos[numOfPeople];
        person.name = name;
        person.NRIC = NRIC;
        person.sex = sex;
        person.birthdate = birthdateYYYYMMDD;
        person.race_nationality = race_nationality;

        return numOfPeople;
    }

    function add(uint256 hospital, uint256 personId,
                certCategory incidentType, string memory incidentYYYYMMDDHHMM, string memory certifierName
                ) public returns(bytes memory) {
        bytes memory id = abi.encodePacked(counter, personId);
        medicalCert memory mc = medicalCert(
            id, 
            hospital,
            infos[personId],
            incidentType,
            incidentYYYYMMDDHHMM,
            certifierName
            );
        
        
        MC[keccak256(id)] = mc;

        emit mcCreated(counter);

        counter = counter + 1;

        return id;
        
    }

    function getMCName(bytes memory id) public view returns(string memory) {
        return MC[keccak256(id)].personal_info.name;
    }

    function getMCNRIC(bytes memory id) public view returns(string memory) {
        return MC[keccak256(id)].personal_info.NRIC;
    }

    function getMCCategory(bytes memory id) public view returns(certCategory) {
        return MC[keccak256(id)].incident;
    }

    // function getMC(bytes memory id) public view returns(uint256, string memory, string memory, uint256, uint256, string memory, string memory, certCategory, string memory, string memory, string memory, string memory, string memory) {
    //     return(MC[id].HospitalID, MC[id].name, MC[id].NRIC, MC[id].sex, MC[id].birthdate, MC[id].race, MC[id].nationality, MC[id].incident, MC[id].dateTimeIncident, MC[id].placeIncident, MC[id].causeIncident, MC[id].titleOfCertifier, MC[id].Institution);
    // }
}
// Return argument type 
// tuple(uint256,string storage ref,string storage ref,string storage ref,uint256,string storage ref,string storage ref,enum MedicalCertificate.certCategory,string storage ref,string storage ref,string storage ref,string storage ref,string storage ref) 
// is not implicitly convertible to expected type 
// tuple(uint256,string memory,string memory,uint256,uint256,string memory,string memory,enum MedicalCertificate.certCategory,string memory,string memory,string memory,string memory,string memory).