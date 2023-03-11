pragma solidity ^0.5.0;
import "./MedicalCert.sol";
import "./StringLength.sol";

contract Hospital {
    StringLength stringlen;
    MedicalCert medicalCert;

    mapping(uint => hospital) registeredHospital; //hospital id => hospital
    mapping(address => hospitalId) ids; //president => hospital id

    uint256 totalHospital = 0;
  
    struct hospital {
        address president; //owner of the hospital
        byte32 president_ic; //the identity of owner
        byte32 password; //passward needed to create MC
        uint256 hospitalId; //id
        mapping(uint256 => mapping(uint256 => medicalCert)) mcs; //hospital id => mc id => MC
    }

    
    // events
    event registered();
    event createOneMC();

    //modifiers
    modifier validIC(string _ic) {
        require(stringlen.strlen(_ic), "invalid NRIC number");
        _;
    }

    modifier onlyOwner(uint256 _hospitalId) {
        require (msg.sender == registeredHospital[ _hospitalId].president, "Unauthorized!");
        _;
    }

    modifier verifyPassword(uint256 _hospitalId, string _password) {
        require (keccak256(abi.encode(_password)) ==registeredHospital[ _hospitalId].password, "Wrong password!");
        _;
    }
    
    //functions
    function register(string memory _ic, string memory _password) validIC(_ic) returns(uint256) {
        hospital memory newHospital ({
            president: msg.sender,
            president_ic: keccak256(abi.encode(_ic)),
            password: keccak256(abi.encode(_password)),
            hospitalId: totalHospital
        }
        )
        
        uint newHospitalId = totalHospital
        registeredHospital[newHopistalId] = newHospital;
        ids[msg.sender] = newHospitalId;
        totalHospital++;
        emit registered();
        return newHospitalId;
    }

    //MC
    function createMC(uint256 memory _hospitalId, string memory _password) verifyPassword(_password) {
        emit createOneMC();
    }


    //getters
    function getHospitalId(address _president) public view returns(uint256) {
        return ids[_president];
    }

    function getPresident(uint256 _hospitalId) public view returns(address) {
        return  registeredHospital[ _hospitalId].president;
    }

    function getPassword(uint256 _hospitalId, string _password) 
        public view 
        onlyOwner(_hospitalId), verifyPassword(_hospitalId, _password) 
        returns(string) 
    {
        return abi.decode(registeredHospital[ _hospitalId].password, string);
    }

}