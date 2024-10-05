// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StakeHunt {
    mapping(address => uint256) public stakes;
    uint256 public totalStakes;

    event Staked(address indexed user, uint256 amount);

    function stake() public payable {
        require(msg.value > 0, "Amount must be greater than zero.");
        stakes[msg.sender] += msg.value;
        totalStakes += msg.value;
        emit Staked(msg.sender, msg.value);
    }

    // Optionally, implement withdraw or claim rewards here.
}
