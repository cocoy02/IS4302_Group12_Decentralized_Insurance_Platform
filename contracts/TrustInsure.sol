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
 
    function getInsure(address recipient, uint256 weiAmt)
        public
        returns (uint256)
    {
        uint256 amt = weiAmt / (1000000000000000000/100);
        if (amt >= 200) amt += 5;
        erc20Contract.mint(recipient, amt);
        return amt; 
    }

    function checkInsure(address ad) public view returns (uint256) {
        uint256 credit = erc20Contract.balanceOf(ad);
        return credit;
    }

    function transferFromInsure(address from, address to, uint256 amt) public {
        erc20Contract.transferFrom(from, to, amt);
    }

    function transferInsure(address to, uint256 amt) public {
        erc20Contract.transferFrom(msg.sender, to, amt);
    }
}
