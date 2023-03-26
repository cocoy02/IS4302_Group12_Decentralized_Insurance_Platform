pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;
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

    mapping (uint256 => Product[]) productList;//company ids => product list
    uint256 numofProds = 0;

    uint256[] companyIds;

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
    event viewAvailableProducts(uint256[] companyids,string[] companynames,uint256[] companycredits,productType[] producttypes,uint256[] productassured);
    event requestSucceed();
    event requestFail();


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
        companyIds.push(companyId);
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
    * @dev Allow stakeholders to check every company's products
    */
    function viewProducts() public {
        uint256[] memory companyids;
        string[] memory companynames;
        uint256[] memory companycredits;

        productType[] memory producttypes;
        uint256[] memory productassured;

        for (uint256 i  = 0; i < companyIds.length; i++) {
           
            Product[] memory products = productList[companyIds[i]];
            for (uint256 j = 0; j < products.length; j++) {
                companyids.push(companyIds[i]);
                companynames.push(companyContract.getName(companyIds[i]));
                companycredits.push(companyContract.getCredit(companyIds[i]));

                producttypes.push(products[j].prodType);
                productassured.push(products[j].sumAssured);
            }
        }
        
        emit viewAvailableProducts(companyids, companynames, companycredits, producttypes, productassured);
    }

    /**
    * @dev stakeholder could initiate buying
    * @return the request id for stakeholders to track its status if return 0 indicated unsuccessful
    */
    function wantToBuy(uint256 companyId, uint256 productId) public returns(uint256) {
        uint256 buyerId = stakeholderContract.getStakeholderId(msg.sender);
        require(buyerId != 0, "Not registered!");

        Product[] memory products = productList[companyId];
        require(products.length <= 10, "The company are experiencing high volume of requests, please come back later!");

        uint256 length = products.length;
        string memory typeProduct = "life";
        uint256 id;
        productType prodtype;
        bool succeed;
        uint256 requestId;

        for (uint256 i = 0; i < length; i++) {
            id = products[i].productid;
            prodtype = products[i].prodType;

            if (id == productId) {
                if (prodtype == productType.accident) typeProduct = "accident";
                (succeed, requestId) = companyContract.addRequestLists(buyerId, companyId, typeProduct);
                if (succeed) {
                    emit requestSucceed();
                    return requestId;
                } else {
                    emit requestFail();
                    return 0;
                }
            }
        }
        
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
}