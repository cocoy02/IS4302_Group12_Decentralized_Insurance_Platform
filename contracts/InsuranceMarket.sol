pragma solidity ^0.8.12;
pragma experimental ABIEncoderV2;
import "./InsuranceCompany.sol";
import "./Stakeholder.sol";
import "./TrustInsure.sol";

contract InsuranceMarket {

    InsuranceCompany companyContract;
    Stakeholder stakeholderContract;
    TrustInsure insureContract;

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

    mapping (uint256 => Product[]) productList;//company ids => product list
    uint256 numofProds = 0;

    uint256[] companyIds;

    constructor (InsuranceCompany companyAddress, Stakeholder stakeholderAddress, TrustInsure insureAddress) public {
        companyContract = companyAddress;
        stakeholderContract = stakeholderAddress;
        insureContract = insureAddress;
    }

// =====================================================================================
// modifiers
// =====================================================================================

    /*check company owner*/
    modifier companyOwnerOnly(uint256 companyId) {
        require(companyContract.getOwner(companyId) == msg.sender, "You are not allowed to list the product!");
        _;
    }
    
    /*check product type whether has misspelling or not valid*/
    modifier validProduct(string memory _productType) {
        //require(_productType == "accident" || _productType == "life", "You should input valid product type, eg. accident or life!");
        require(keccak256(abi.encode(_productType)) == keccak256(abi.encode("accident")) ||
        keccak256(abi.encode(_productType)) == keccak256(abi.encode("life")), "You should input valid product type, eg. accident or life!");
      
        _;
    }

    modifier validStakeholder(uint stakeholderId) {
        require(stakeholderContract.getStakeholderId(msg.sender) != 0, "Not registered stakeholder!");
        require(stakeholderContract.getStakeholderId(msg.sender) == stakeholderId, "Invalid stakeholder id!");
        _;
    }


    modifier validNumber(string memory s) {
        require(bytes(s).length == 8, "Invalid length of phone number!");
        _;
    }

// =====================================================================================
// events
// =====================================================================================

    event productPublished();
    event productWithdrawedSucceed();
    event productWithdrawedFail();
    event viewAvailableProducts(uint256[] companyids,string[] companynames,uint256[] companycredits,uint256[] productids,productType[] producttypes,uint256[] productpremium, uint256[] productassured);
    event requestSucceed();
    event requestFail();

// =====================================================================================
// functions
// =====================================================================================
    
    // /**
    // * @dev Allow insurance company list product on the market
    // * @param _premium The amount that should be paid yearly
    // * @param _sumAssured Total amount to claim the insurance
    // * @return uint256 productId
    // */
    function publishProduct(uint256 companyId, string memory productCategory, uint256 premium, uint256 sumOfClaim) 
    public companyOwnerOnly(companyId) validProduct(productCategory)
    returns(uint256)
    {
        require(insureContract.checkInsure(msg.sender) > 1, 
        "Do not have enough TrustInsure to publish products!");
        
        //Add in product list of the company
        Product storage newProduct =  productList[companyId].push();
        numofProds++;
        if (keccak256(abi.encode(productCategory)) == keccak256(abi.encode("accident"))) {
            newProduct.productid = numofProds;
            newProduct.premium = premium;
            newProduct.sumAssured = sumOfClaim;
            newProduct.prodType = productType.accident;    
        } else {
            newProduct.productid = numofProds;
            newProduct.premium = premium;
            newProduct.sumAssured = sumOfClaim;
            newProduct.prodType = productType.life;
        }

        
        emit productPublished();
        companyIds.push(companyId);
        
        //transfer comission fee to the platform
        insureContract.transferFromInsure(msg.sender, address(this), 1);

        return numofProds;
    }

    // /**
    // * @dev Allow insurance company unlist product on the market
    // * @return bool whether successfully withdraw the product
    // */
    function withdrawProduct(uint256 companyId, uint256 productId)
    public companyOwnerOnly(companyId)
    returns(bool)
    {
        require(insureContract.checkInsure(msg.sender) > 1, 
        "Do not have enough TrustInsure to withdraw products!");


        //find product index in the list
        uint256 index;
        uint256 length = productList[companyId].length;
        bool find = false;
        for (uint256 i = 0; i < length; i++) {
            if (productList[companyId][i].productid == productId) {
                index = i;
                find = true;
            }
        }
        
        //If product exist, delete the product in the list
        require(find == true, "Please ensure the input product id is valid!");
        if (find) {
            productList[companyId][index] = productList[companyId][length - 1];
            productList[companyId].pop();
            emit productWithdrawedSucceed();
            numofProds--;
            //transfer comission fee to the platform
            insureContract.transferFromInsure(msg.sender, address(this), 1);
        } else {
            emit productWithdrawedFail();
        }
       
        numofProds--;
        return find;
    }

    // /**
    // * @dev Allow stakeholders to check every company's products
    // */
    function viewProducts() public {
        uint256[] memory companyids = new uint256[](numofProds);
        string[] memory companynames = new string[](numofProds);
        uint256[] memory companycredits = new uint256[](numofProds);
        uint256[] memory productids = new uint256[](numofProds);
        uint256[] memory productpremium = new uint256[](numofProds);
        productType[] memory producttypes = new productType[](numofProds);
        uint256[] memory productassured = new uint256[](numofProds);
        uint256[] memory companyidentified = new uint256[](numofProds);
        uint256 total_products = 0;

        //add product id 

        //loop every company and their products
        for (uint256 i  = 0; i < companyIds.length; i++) {
            bool checked = false;
            for (uint k = 0; k < companyidentified.length; k++){
                if(companyIds[i] == companyidentified[k]){
                    checked = true;
                    break;
                }
            }           
            if (checked == true){
                continue;
            }
            Product[] memory products = productList[companyIds[i]];
            for (uint256 j = 0; j < products.length; j++) {
                companyids[total_products] = companyIds[i];
                companynames[total_products] = companyContract.getName(companyIds[i]);
                companycredits[total_products] = companyContract.getCredit(companyIds[i]);
                productids[total_products] = products[j].productid;
                productpremium[total_products] = products[j].premium;
                producttypes[total_products] = products[j].prodType;
                productassured[total_products] = products[j].sumAssured;
                total_products++;
            }
            companyidentified[i]=companyIds[i];
        }
        
        emit viewAvailableProducts(companyids, companynames, companycredits, productids,producttypes, productpremium, productassured);
    }

    /**
    * @dev stakeholder could initiate buying
    * @return uint256 the request id for stakeholders to track its status if return 0 indicated unsuccessful
    */
    function wantToBuy(uint256 stakeholderId, uint256 companyId, uint256 productId, string memory contact) 
    public validNumber(contact) validStakeholder(stakeholderId)
    returns(uint256) 
    {

        Product[] memory products = productList[companyId];
        

        string memory typeProduct = "life";
        uint256 id;
        bool succeed;
        uint256 requestId;
        
        //check whether could find the product and add request to the company
        for (uint256 i = 0; i < products.length; i++) {
            id = products[i].productid;

            if (id == productId) {
                if (products[i].prodType == productType.accident) typeProduct = "accident";
                (succeed, requestId) = companyContract.addRequestLists(stakeholderId, companyId, contact, typeProduct);
                if (succeed) {
                    emit requestSucceed();
                    stakeholderContract.addRequestIds(stakeholderId, requestId);
                    return requestId;
                } 
            }
        }
        
        emit requestFail();
        return 0;
    }

    // then the company need to verify their requests within 7 days
    // but usually they will check once a day so its quite fast
    // then the company will approach to buyers to discuss the details of insurance - offline stuff
    // then create contract in insuranceConpany contract
    // then send it to policy owners to verify
    // once the verification is done, the insurance is issued successfully
    function getProductInfo(Product memory _product) internal view returns(uint256, uint256,uint256, productType) {
        return (_product.productid, _product.premium, _product.sumAssured, _product.prodType);
    }

    function getNumProd() public view returns (uint256) {
        return numofProds;
    }
}