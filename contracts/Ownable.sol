// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.8.1;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    
    address private owner_;
    
    constructor() public {
        owner_ = msg.sender;   
    }
    
    function getOwner() public view returns (address) {
       return owner_;
    }
    
    function isOwner() public view returns (bool) {
       return owner_ == msg.sender;
    }
    
    modifier onlyOwner(){
        require(owner_ == msg.sender, "Ownable: caller is not the owner");
        _;
    }
}