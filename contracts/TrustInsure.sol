// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./ERC20.sol";

contract TrustInsure {
    ERC20 erc20Contract;
    address owner;

    constructor() public {
        ERC20 e = new ERC20();
        erc20Contract = e;
        owner = msg.sender;
    }

// =====================================================================================
// functions
// =====================================================================================
    
    /** 
    * @dev Mint TrustInsure tokens
    * @return uint256 amount of tokens minted and transferred to the user's address
    */
    function getInsure()
        public payable
        returns (uint256)
    {
        //uint256 amt = weiAmt / (1000000000000000000/100);
        uint256  amt = msg.value / (1000000000000000000/100);
        if (amt >= 200) amt += (amt/200) * 5;
        erc20Contract.mint(msg.sender, amt);
        return amt; 
    }

    /** 
    * @dev Check balance of tokens
    * @param ad Input the address of the user who want to check balance of
    * @return uint256 credit balance of the input address
    */
    function checkInsure(address ad) public view returns (uint256) {
        uint256 credit = erc20Contract.balanceOf(ad);
        return credit;
    }

    /** 
    * @dev Transfer tokens from one address to another
    * @param from the address of the account which TrustInsure will be transfered from
    * @param to the address of the account which TrustInsure will be transfered to
    * @param amt the amount of tokens to be transfered
    */
    function transferFromInsure(address from, address to, uint256 amt) public {
        erc20Contract.transferFrom(from, to, amt);
    }

    /** 
    * @dev Transfer tokens to others
    * @param to the address of the account which TrustInsure will be transfered to
    * @param amt the amount of tokens to be transfered
    */
    function transferInsure(address to, uint256 amt) public {
        erc20Contract.transferFrom(msg.sender, to, amt);
    }
}
