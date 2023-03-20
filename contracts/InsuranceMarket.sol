pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;
import "./InsuranceCompany.sol";
import "./Insurance.sol";

contract InsuranceMarket {
    // others contract instnaces
    // attributes
    InsuranceCompany companyContract;
    Insurance insuContract;
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
    constructor () public {
        // companyContract = insuCompany;
        // insu = insu;
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
    function wantToBuy(uint256 buyerID, uint256 comID, Insurance product) public returns(string memory) {
        companyContract.addRequestLists(buyerID, comID, product);
    }

    // then the company need to verify their requests within 7 days
    // but usually they will check once a day so its quite fast
    // then the company will approach to buyers to discuss the details of insurance - offline stuff
    // then create contract in insuranceConpany contract
    // then send it to policy owners to verify
    // once the verification is done, the insurance is issued successfully


    // getters

    function getInfo() public view returns(string[] memory) {
        string[] info;
        uint256 numOfCompanies = companyContract.getNumOfCompanies();
        for (uint256 i = 0; i < numOfCompanies; i++){
            uint356 comID = i;
            InsuranceCompany com = companyContract.getCompany(comID);
            Insurance[] products = companyContract.getProducts(comId);
            // 上面加一句话
            // all the insurance can be paid yearly or monthly
            // 再加一个title给
            string[] com_info;
            string id_str = uint2str(comID);
            com_info.push(id_str);
            com_info.push(" ");
            com_info.push(com.name);
            com_info.push("(");
            com_info.push(com.credit);
            com_info.push("): ");
            // company info - "0 XXXCompany(100): "
            com_str = concat(com_info);

            // prod_arr: ["accident $200, ", "life $20000"]
            string[] prod_arr;
            for (uint256 j = 0; j < products.length; j++) {
                string[] prof_info;
                prod = products[j];
                prod_info.push(prod.insType);
                prod_info.push(" $");
                string price = uint2str(prod.price);
                prod_info.push(price);
                if (j != products.length - 1) {
                    prof_info.push(", ");
                }
                prod_info_str = concat(prod.info);
                prod_arr.push(prod_info_str);
            }

            string prod_str = concat(prod_arr);
            info.push(com_str);
            info.push(prod_str);
            info.push(" | ");
        }

        string info_str = concat(info);
        return info_str;

    }

    // function getInsuranceTypes() public view returns(string[] memory) {
    //     return types;
    // }

    // function getBasicInfo (string memory InsuType) public view returns (string memory) {
    //     string memory message;
    //     if (keccak256(abi.encodePacked(InsuType)) == keccak256(abi.encodePacked("accident"))) {
    //         message = accidentDesc;
    //     } else if (keccak256(abi.encodePacked(InsuType)) == keccak256(abi.encodePacked("life"))) {
    //         message = lifeDesc;
    //     } else {
    //         message = "This insurance type is currently unavailable";
    //     }
    //     return message;
    // }

    // function getTotalPremium (string memory InsuType) public view returns (uint256) {
    //     if (keccak256(abi.encodePacked(InsuType)) == keccak256(abi.encodePacked("accident"))) {
    //         return premium["accident"];
    //     } else if (keccak256(abi.encodePacked(InsuType)) == keccak256(abi.encodePacked("life"))) {
    //         return premium["life"];
    //     } else {
    //         return 0;
    //     }
    // }

    // function getSubPremium (string memory InsuType) public view returns (uint256) {
    //     if (keccak256(abi.encodePacked(InsuType)) == keccak256(abi.encodePacked("accident"))) {
    //         return premium["accident"] / 10; 
    //         // totalPrice * 1.2 / 12  => they pay 1.2*price in total and this calculates the monthly payment
    //     } else if (keccak256(abi.encodePacked(InsuType)) == keccak256(abi.encodePacked("life"))) {
    //         return premium["life"] / 10;
    //     } else {
    //         return 0;
    //     }
    // }

    // function getSumAssured(string memory InsuType) public view returns (uint256) {
    //     if (keccak256(abi.encodePacked(InsuType)) == keccak256(abi.encodePacked("accident"))) {
    //         return sumAssured["accident"]; 
    //     } else if (keccak256(abi.encodePacked(InsuType)) == keccak256(abi.encodePacked("life"))) {
    //         return sumAssured["life"];
    //     } else {
    //         return 0;
    //     }
    // }

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

    function concat(string[] calldata words) external pure returns (string memory) {
        bytes memory output;
        for (uint256 i = 0; i < words.length; i++) {
            output = abi.encodePacked(output, words[i]);
        }
        return string(output);
    }

}