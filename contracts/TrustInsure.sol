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
 
    //function getInsure(address recipient, uint256 weiAmt)
    function getInsure()
        public payable
        returns (uint256)
    {
        //uint256 amt = weiAmt / (1000000000000000000/100);
        uint256  amt = msg.value;
        if (amt >= 200) amt += (amt/200) * 5;
        erc20Contract.mint(msg.sender, amt);
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
