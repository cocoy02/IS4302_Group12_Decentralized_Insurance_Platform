pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;
import "./InsuranceCompany.sol";

contract InsuranceMarket {
    // others contract instnaces
    // attributes
    InsuranceCompany companyContract;
    struct Request {
        address buyer;
        string insuType;
        string status; // {approved, rejected, pending}
    }
    uint256 numOfRequests;
    mapping (string => uint256) premium;
    mapping (string => uint256) sumAssured;
    mapping (uint256 => Request) requests;
    uint256[] requestsID;
    string accidentDesc = "accident insurance description";
    string lifeDesc = "life insurance description";
    string[] types = ["accident", "life"];

    // ---------------------------------------------------
    // must initiate a company and token contract instance
    // ---------------------------------------------------
    constructor (InsuranceCompany insuCompany) public {
        companyContract = insuCompany;
        premium["life"] = 2000; // 2k per year
        premium["accident"] = 200; // 200 per year
        sumAssured["life"] = 500000;
        sumAssured["accident"] = 2000; // the highest amount that stakeholders can declare within one year
    }

    // ------
    // events
    // ------

    // functions

    // returns the request _id for stakeholders to track its status
    function wantToBuy(uint256 id, string memory InsuType) public returns(string memory) {
        // stakeholders declare their willing to buy insurance
        address _buyer = msg.sender;
        Request memory req = Request(_buyer, InsuType, "pending");
        uint256 id = numOfRequests;
        requests[id] = req;
        requestsID.push(id);
        numOfRequests = numOfRequests + 1;
        // --------------------------------
        // why it doesnt print out
        // print(uint2str(id));
        // --------------------------------
        return uint2str(id);
    }

    // then the company need to verify their requests within 7 days
    // but usually they will check once a day so its quite fast
    // then the company will approach to buyers to discuss the details of insurance - offline stuff
    // then create contract in insuranceConpany contract
    // then send it to policy owners to verify
    // once the verification is done, the insurance is issued successfully


    // getters

    function getInsuranceTypes() public view returns(string[] memory) {
        return types;
    }

    function getBasicInfo (string memory InsuType) public view returns (string memory) {
        string memory message;
        if (keccak256(abi.encodePacked(InsuType)) == keccak256(abi.encodePacked("accident"))) {
            message = accidentDesc;
        } else if (keccak256(abi.encodePacked(InsuType)) == keccak256(abi.encodePacked("life"))) {
            message = lifeDesc;
        } else {
            message = "This insurance type is currently unavailable";
        }
        return message;
    }

    function getTotalPremium (string memory InsuType) public view returns (uint256) {
        if (keccak256(abi.encodePacked(InsuType)) == keccak256(abi.encodePacked("accident"))) {
            return premium["accident"];
        } else if (keccak256(abi.encodePacked(InsuType)) == keccak256(abi.encodePacked("life"))) {
            return premium["life"];
        } else {
            return 0;
        }
    }

    function getSubPremium (string memory InsuType) public view returns (uint256) {
        if (keccak256(abi.encodePacked(InsuType)) == keccak256(abi.encodePacked("accident"))) {
            return premium["accident"] / 10; 
            // totalPrice * 1.2 / 12  => they pay 1.2*price in total and this calculates the monthly payment
        } else if (keccak256(abi.encodePacked(InsuType)) == keccak256(abi.encodePacked("life"))) {
            return premium["life"] / 10;
        } else {
            return 0;
        }
    }

    function getSumAssured(string memory InsuType) public view returns (uint256) {
        if (keccak256(abi.encodePacked(InsuType)) == keccak256(abi.encodePacked("accident"))) {
            return sumAssured["accident"]; 
        } else if (keccak256(abi.encodePacked(InsuType)) == keccak256(abi.encodePacked("life"))) {
            return sumAssured["life"];
        } else {
            return 0;
        }
    }

    function getRequestStatus(uint256 id) public view returns(string memory) {
        address owner = requests[id].buyer;
        require(msg.sender == owner || msg.sender == Company);
        if (id < numOfRequests && id >= 0) {
            return requests[id].status;
        } else {
            return "Request does not exist";
        }
    }


    // other helping functions
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

}