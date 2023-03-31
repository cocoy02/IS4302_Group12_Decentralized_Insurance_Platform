// SPDX-License-Identifier: MIT
// Source:
// https://github.com/ensdomains/ens-contracts/blob/master/contracts/ethregistrar/StringUtils.sol
pragma solidity ^0.8.12;
contract StringLength {
    /**
     * @dev Returns the length of a given string
     *
     * @param s The string to measure the length of
     * @return The length of the input string
     */
    function strlen(string calldata s) external pure returns (uint256) {
        uint256 len;
        bytes1 char = bytes(s)[0];
        if(
            !(char >= 0x41 && char <= 0x5A) && //A-Z
            !(char >= 0x61 && char <= 0x7A) //a-z
        )
        return 0;
   
        uint i=0;
        bytes memory string_rep = bytes(s);
        uint256 length = 0;
         while (i<string_rep.length)
        {
            if (string_rep[i]>>7==0)
                i+=1;
            else if (string_rep[i]>>5==bytes1(uint8(0x6)))
                i+=2;
            else if (string_rep[i]>>4==bytes1(uint8(0xE)))
                i+=3;
            else if (string_rep[i]>>3==bytes1(uint8(0x1E)))
                i+=4;
            else
                //For safety
                i+=1;

            length++;
        }

        
        return length;
    }
}