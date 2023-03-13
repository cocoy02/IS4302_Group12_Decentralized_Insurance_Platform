pragma solidity ^0.5.0;

import "./ERC20.sol";

contract TrustInsure {
    ERC20 erc20Contract;
    address owner;

    constructor() public {
        ERC20 e = new ERC20();
        erc20Contract = e;
        owner = msg.sender;
    }
 
    function getCredit(address recipient, uint256 weiAmt)
        public
        returns (uint256)
    {
        uint256 amt = weiAmt / (1000000000000000000/100); // Convert weiAmt to Dice Token
        erc20Contract.mint(recipient, amt);
        return amt; 
    }

    function checkCredit(address ad) public view returns (uint256) {
        uint256 credit = erc20Contract.balanceOf(ad);
        return credit;
    }

    function transferFromCredit(address from, address to, uint256 amt) public {
        erc20Contract.transferFrom(from, to, amt);
    }

    function transferCredit( address to, uint256 amt) public {
        erc20Contract.transferFrom(to, amt);
    }
}
