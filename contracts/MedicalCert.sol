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
        string birthdate; //YYYYMMDD
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


    function createPersonalInfo (uint256 hospitalId, string memory password,
    string memory name, string memory NRIC, string memory sex, 
    string memory birthdateYYYYMMDD, string memory race_nationality) public virtual returns (uint256) {}

    function addMC(uint256 hospital, string memory password, uint256 personId,
                certCategory incidentType, string memory incidentYYYYMMDDHHMM, string memory certifierName
                ) public virtual returns(bytes memory) {
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
}