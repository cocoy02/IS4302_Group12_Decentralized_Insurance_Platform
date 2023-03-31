pragma solidity ^0.8.12;
pragma experimental ABIEncoderV2;

contract MedicalCertificate {
    uint256 counter = 0;

    enum certCategory{
        incident,
        death,
        suicide
    }

    // struct medicalCert{
    //     bytes ID;
    //     uint256 HospitalID;
    //     string name;
    //     string NRIC;
    //     string sex;
    //     uint256 birthdate; //YYYYMMDD
    //     string race_nationality;
    //     certCategory incident;
    //     string dateTimeIncident; //YYYYMMDDHHMM
    //     string placeIncident;
    //     string causeIncident;
    //     string titleOfCertifier;
    //     //stakeholder Stakeholder;
    //     //[]insuranceCompany access;
    // }
    struct medicalCert{
        bytes ID;
        uint256 HospitalID;
        string name;
        string NRIC;
        bytes personal_info;
        certCategory incident;
        string dateTimeIncident; //YYYYMMDDHHMM
        string titleOfCertifier;
        //stakeholder Stakeholder;
        //[]insuranceCompany access;
    }

    mapping(bytes32 => medicalCert) public MC;

    event mcCreated(uint256 numMC);

    //  /** 
    // * @dev create new mc with relevant information
    // * @return  bytes new mc id
    // */
    // string memory name, string memory NRIC, uint256 sex, 
    //             uint256 birthdate, string memory race, string memory nationality, 
    //             string incidentType, string memory incidentYYYYMMDDHHMM, 
    //             string memory place, string memory cause, string memory titleNname, string memory institution
    // function add(uint256 hospital, medicalCert memory info) public returns(bytes memory) {
    //     bytes memory id = abi.encodePacked(counter, info.name, info.NRIC);
    //     medicalCert memory mc = medicalCert(
    //         id, 
    //         hospital,
    //         info.name,
    //         info.NRIC,
    //         info.sex,
    //         info.birthdate,
    //         info.race,
    //         info.nationality,
    //         info.incident,
    //         info.dateTimeIncident,
    //         info.placeIncident,
    //         info.causeIncident,
    //         info.titleOfCertifier,
    //         info.Institution
    //         // stakeholder,
    //         //[]insuranceCompany
    //         );
        
        
    //     MC[keccak256(id)] = mc;

    //     emit mcCreated(counter);

    //     counter = counter + 1;

    //     return id;
        
    // // }
    // function add(uint256 hospital, string memory name, string memory NRIC, string memory sex, 
    //             uint256 birthdate, string memory race_nationality,
    //             certCategory incidentType, string memory incidentYYYYMMDDHHMM, 
    //             string memory place, string memory cause, string memory titleNname) public returns(bytes memory) {
    //     bytes memory id = abi.encodePacked(counter, name, NRIC);
    //     medicalCert memory mc = medicalCert(
    //         id, 
    //         hospital,
    //         name,
    //         NRIC,
    //         sex,
    //         birthdate,
    //         race_nationality,
    //         incidentType,
    //         incidentYYYYMMDDHHMM,
    //         place,
    //         cause,
    //         titleNname
    //         // stakeholder,
    //         //[]insuranceCompany
    //         );
        
        
    //     MC[keccak256(id)] = mc;

    //     emit mcCreated(counter);

    //     counter = counter + 1;

    //     return id;
        
    // }

    function add(uint256 hospital, string memory name, string memory NRIC, string memory sex, 
                uint256 birthdate, string memory race_nationality,
                certCategory incidentType, string memory incidentYYYYMMDDHHMM, 
                string memory place, string memory cause, string memory titleNname) public returns(bytes memory) {
        bytes memory id = abi.encodePacked(counter, name, NRIC);
        bytes memory info = abi.encodePacked(sex, birthdate, race_nationality, place, cause);
        medicalCert memory mc = medicalCert(
            id, 
            hospital,
            name,
            NRIC,
            info,
            incidentType,
            incidentYYYYMMDDHHMM,
            titleNname
            // stakeholder,
            //[]insuranceCompany
            );
        
        
        MC[keccak256(id)] = mc;

        emit mcCreated(counter);

        counter = counter + 1;

        return id;
        
    }
    //giveAccess(byte32 ID, insuranceCompany company){
        //require(msg.sender==MC[ID].stakeholder.address)
        //MC[ID].access.push(company);
    //}

    //  /** 
    // * @dev get mc information by id
    // * @param  bytes id
    // * @return tuple of information
    // */
    function getMCName(bytes memory id) public view returns(string memory) {
        return MC[keccak256(id)].name;
    }

    function getMCNRIC(bytes memory id) public view returns(string memory) {
        return MC[keccak256(id)].NRIC;
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