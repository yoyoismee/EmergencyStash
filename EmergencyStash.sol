// SPDX-License-Identifier: MIT
// author: yoyoismee.eth -- it's opensource but also feel free to send me coffee/beer.

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


/// @notice EmergencyStash is what the name suggest. you can keep some amount of money here for emergency. 
/// It should be safe enough for it intended use but not as safe as others storage option.
/// stash is password protected vault. with commit reveal and time delay to prevent front running.
/// you can create the vault and lock with a key. keccak256(password) (it will automatically renouceOwnership)
/// later you can unlock (claim ownership) in 2 step. 
/// one is commit a hash. keccak256(password + salt)
/// then after a time delay reveal password to the vault and salt for the commit.
/// Owner can withdraw ETH or ERC20. 
/// GLHF 
contract EmergencyStash is Ownable {
    uint256 timedelay = 10 minutes;
    bytes32 private lock;
    mapping(bytes32 => address) commiters;
    mapping(bytes32 => uint256) commitsTime;


    /// @notice lock and renouce ownership. _lock = keccak256(password). 
    /// @dev can't unlock if ya f this up LOL
    function hideStash(bytes32 _lock) public onlyOwner{
        lock = _lock;
        renounceOwnership();
    }

    /// @notice commit with keccak256(password,salt)
    function insertKey(bytes32 _commit) public {
        require(commiters[_commit] == address(0), "taken");
        commiters[_commit] = msg.sender;
        commitsTime[_commit] = block.timestamp;
    }

    /// @notice reclaim ownership
    function open(string calldata password, string calldata salt) public {
        bytes32 check = keccak256(abi.encodePacked(password, salt));
        require(commiters[check] == msg.sender, "pls commit");
        require(block.timestamp - commitsTime[check] > timedelay, "too soon");

        bytes32 keyHash = keccak256(abi.encodePacked(password));
        if (keyHash == lock) {
            _transferOwnership(msg.sender);
        }
    }

    /// @notice withdraw your mooney!
    function withdraw(address tokenAddress) public onlyOwner {
        if (tokenAddress == address(0)) {
            payable(msg.sender).transfer(address(this).balance);
        } else {
            IERC20 token = IERC20(tokenAddress);
            token.transfer(msg.sender, token.balanceOf(address(this)));
        }
    }

    /// @notice should be use for debug. reveal your password over internet is a bad idea
    function debug1(string calldata txt) public pure returns(bytes32){
        return keccak256(abi.encodePacked(txt));
    }

    /// @notice should be use for debug. reveal your password over internet is a bad idea
    function debug2(string calldata txt, string calldata peper) public pure returns(bytes32){
        return keccak256(abi.encodePacked(txt,peper));
    }
}
