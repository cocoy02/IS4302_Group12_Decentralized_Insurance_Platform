// SPDX-License-Identifier: MIT
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
        uint256 ID;
        uint256 HospitalID;
        uint256 personal_info;
        certCategory incident;
        string dateTimeIncident; //YYYYMMDDHHMM
        string titleOfCertifier;
    }


    mapping(uint256 => medicalCert) MC;
    mapping(uint256 => personalInfo) infos;

// =====================================================================================
// events
// =====================================================================================

    event mcCreated(uint256 numMC);

// =====================================================================================
// functions
// =====================================================================================
    /**
    * @dev Create information profile for the assured person
    * @param hospitalId the id of the hospital
    * @param password the password of the hospital
    * @param name the name of the person who has accident
    * @param NRIC the NRIC of the person who has accident
    * @param sex the sex of the person who has accident
    * @param birthdateYYYYMMDD the birthdate of the person who has accident
    * @param race_nationality the race and nationality of the person who has accident
    */
    function createPersonalInfo (uint256 hospitalId, string memory password,
    string memory name, string memory NRIC, string memory sex, 
    string memory birthdateYYYYMMDD, string memory race_nationality) public virtual returns (uint256) {}

    /**
    * @dev Create the medical certificate for the injured or dead person
    * @param hospital the id of the hospital
    * @param password the password of the hosptial
    * @param personId  the id of the person who has accident
    * @param incidentType0incident1death2suicide the incident type of accident where 0 is incident 1 is death and 2 is suicide
    * @param incidentYYYYMMDDHHMM the incident date and time of the incident
    * @param certifierName the certifier of the MC of the accident
    */
    function addMC(uint256 hospital, string memory password, uint256 personId,
                certCategory incidentType0incident1death2suicide, string memory incidentYYYYMMDDHHMM, 
                string memory certifierName
                ) public virtual returns(uint256) {
    }

// =====================================================================================
// getters
// =====================================================================================
    // get name of MC
    function getMCName(uint256 id) public view returns(string memory) {
        return infos[MC[id].personal_info].name;
    }

    // get NRIC of MC
    function getMCNRIC(uint256 id) public view returns(string memory) {
        return infos[MC[id].personal_info].NRIC;
    }

    // get category of MC
    function getMCCategory(uint256 id) public view returns(certCategory) {
        return MC[id].incident;
    }
}