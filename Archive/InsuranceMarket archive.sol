pragma solidity ^0.5.0;
//pragma experimental ABIEncoderV2;
import "./InsuranceCompany.sol";
//import "./Insurance.sol";
import "./Stakeholder.sol";

contract InsuranceMarket {

    InsuranceCompany companyContract;
    Stakeholder stakeholderContract;

    // ---------------
    // Product related
    // ---------------
    enum productType {accident,life}

    struct Product {
        uint256 productid;
        uint256 premium;
        uint256 sumAssured;
        productType prodType;
    }

    mapping (uint256 => Product[]) productList;
    uint256 numofProds = 0;


    constructor (InsuranceCompany companyAddress, Stakeholder stakeholderAddress) public {
        companyContract = companyAddress;
        stakeholderContract = stakeholderAddress;
    }

    // ---------
    // modifiers
    // ---------
    /*check company owner*/
    modifier companyOwnerOnly(uint256 companyId) {
        require(companyContract.getOwner(companyId) == msg.sender, "You are not allowed to list the product!");
        _;
    }
    
    /*check product type whether has misspelling or not valid*/
    modifier validProduct(string memory _productType) {
        require(_productType == "accident" | _productType == "life", "You should input valid product type, eg. accident or life!");
        _;
    }

    // ------
    // events
    // ------
    event productPublished();
    event productWithdrawedSucceed();
    event productWithdrawedFail();

    // ---------
    // functions
    // ---------


    /**
    * @dev Allow insurance company list product on the market
    * @param _premium The amount that should be paid yearly
    * @param _sumAssured Total amount to buy the insurance
    * @return productId
    */
    function publishProduct(uint256 companyId, string memory _productType, uint256 _premium, uint256 _sumAssured) 
    public companyOwnerOnly(companyId) validProduct(_productType)
    returns(uint256)
    {
        Product memory newProduct;
        if (_productType == "accident") {
            newProduct = Product(
                numofProds++,
                _premium,
                _sumAssured,
                productType.accident
            );
        } else {
            newProduct = Product(
                numofProds++,
                _premium,
                _sumAssured,
                productType.life
            );
        }

        productList[companyId].push(newProduct);
        emit productPublished();
        return numofProds;
    }

    /**
    * @dev Allow insurance company unlist product on the market
    * @return whether successfully withdraw the product
    */
    function withdrawProduct(uint256 companyId, uint256 productId)
    public companyOwnerOnly(companyId)
    returns(bool)
    {

        uint256 index;
        uint256 length = productList[companyId].length;
        bool find = false;
        for (uint256 i = 0; i < length; i++) {
            if (productList[companyId][i].id == productId) {
                index = i;
                find = true;
            }
        }
        
        if (find) {
            productList[companyId][index] = productList[companyId][length - 1];
            productList[companyId].pop();
            emit productWithdrawedSucceed();
        } else {
            emit productWithdrawedFail();
        }
        
        return find;
    }


    /**
    * @dev stakeholder could initiate buying
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    // returns the request _id for stakeholders to track its status
    function wantToBuy(uint256 companyId, uint256 productId) public returns(string memory) {
        uint256 buyerId = stakeholderContract.getStakeholderId(msg.sender);
        require(buyerId != 0, "Not registered!");

        Product[] memory products = productList[companyId];
        uint256 length = products.length;
        bool valid = false;
        string memory typeProduct = "life";
        for (uint256 i = 0; i < length; i++) {
            (id,,,prodtype) = getProductInfo(products[i]);
            if (id == productId) {
                if (prodtype == productType.accident) typeProduct = "accident";
                return companyContract.addRequestLists(buyerId, companyId, typeProduct);
            }
        }
        
    }

    // then the company need to verify their requests within 7 days
    // but usually they will check once a day so its quite fast
    // then the company will approach to buyers to discuss the details of insurance - offline stuff
    // then create contract in insuranceConpany contract
    // then send it to policy owners to verify
    // once the verification is done, the insurance is issued successfully


    // getters
    //customer view product list
    // function getProductInfo() public view returns(string[] memory) {
    //     string[] info;
    //     uint256 numOfCompanies = companyContract.getNumOfCompanies();
    //     for (uint256 i = 0; i < numOfCompanies; i++){
    //         uint356 comID = i;
    //         InsuranceCompany com = companyContract.getCompany(comID);
    //         Insurance[] products = companyContract.getProducts(comId);
    //         // 上面加一句话
    //         // all the insurance can be paid yearly or monthly
    //         // 再加一个title给
    //         string[] com_info;
    //         string id_str = uint2str(comID);
    //         com_info.push(id_str);
    //         com_info.push(" ");
    //         com_info.push(com.name);
    //         com_info.push("(");
    //         com_info.push(com.credit);
    //         com_info.push("): ");
    //         // company info - "0 XXXCompany(100): "
    //         com_str = concat(com_info);

    //         // prod_arr: ["accident $200, ", "life $20000"]
    //         string[] prod_arr;
    //         for (uint256 j = 0; j < products.length; j++) {
    //             string[] prof_info;
    //             prod = products[j];
    //             prod_info.push(prod.insType);
    //             prod_info.push(" $");
    //             string price = uint2str(prod.price);
    //             prod_info.push(price);
    //             if (j != products.length - 1) {
    //                 prof_info.push(", ");
    //             }
    //             prod_info_str = concat(prod.info);
    //             prod_arr.push(prod_info_str);
    //         }

    //         string prod_str = concat(prod_arr);
    //         info.push(com_str);
    //         info.push(prod_str);
    //         info.push(" | ");
    //     }

    //     string info_str = concat(info);
    //     return info_str;

    // }


    
    function getProductInfo(Product memory _product) internal view returns(uint256, uint256,uint256, productType) {
        return (_product.productid, _product.premium, _product.sumAssured, _product.prodType);
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

    // // other helping functions
    // function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
    //     if (_i == 0) {
    //         return "0";
    //     }
    //     uint j = _i;
    //     uint len;
    //     while (j != 0) {
    //         len++;
    //         j /= 10;
    //     }
    //     bytes memory bstr = new bytes(len);
    //     uint k = len - 1;
    //     while (_i != 0) {
    //         bstr[k--] = byte(uint8(48 + _i % 10));
    //         _i /= 10;
    //     }
    //     return string(bstr);
    // }

    // function concat(string[] calldata words) external pure returns (string memory) {
    //     bytes memory output;
    //     for (uint256 i = 0; i < words.length; i++) {
    //         output = abi.encodePacked(output, words[i]);
    //     }
    //     return string(output);
    // }

}