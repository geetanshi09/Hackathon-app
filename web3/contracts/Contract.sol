// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StakeHunt is ERC721URIStorage, Ownable {
    IERC20 public stakingToken;
    uint256 public nftCounter;
    uint256 public rewardAmount;
    
    struct Hunt {
        uint256 id;
        address participant;
        string location;
        bool completed;
        string rewardURI;
    }
    
    mapping(uint256 => Hunt) public hunts;
    mapping(address => uint256) public stakes;

    event Staked(address indexed participant, uint256 amount, string location);
    event HuntCompleted(address indexed participant, uint256 huntId, string rewardURI);

    constructor(address _stakingToken, uint256 _rewardAmount) ERC721("StakeHuntNFT", "SHN") {
        stakingToken = IERC20(_stakingToken);
        rewardAmount = _rewardAmount;
        nftCounter = 1; // Start NFT ID counter
    }

    // Stake tokens to join the treasure hunt
    function stakeTokens(uint256 _amount, string memory _location) public {
        require(_amount > 0, "You need to stake tokens");

        // Transfer tokens from the participant to the contract
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        stakes[msg.sender] += _amount;

        // Create a new hunt entry
        hunts[nftCounter] = Hunt({
            id: nftCounter,
            participant: msg.sender,
            location: _location,
            completed: false,
            rewardURI: ""
        });

        emit Staked(msg.sender, _amount, _location);

        nftCounter++;
    }

    // Complete the treasure hunt and get rewards
    function completeHunt(uint256 _huntId, string memory _rewardURI) public onlyOwner {
        Hunt storage hunt = hunts[_huntId];
        require(hunt.participant != address(0), "Hunt not found");
        require(!hunt.completed, "Hunt already completed");

        // Mark the hunt as completed
        hunt.completed = true;
        hunt.rewardURI = _rewardURI;

        // Mint an NFT as a reward
        _safeMint(hunt.participant, _huntId);
        _setTokenURI(_huntId, _rewardURI);

        // Optionally, transfer a crypto reward
        stakingToken.transfer(hunt.participant, rewardAmount);

        emit HuntCompleted(hunt.participant, _huntId, _rewardURI);
    }

    // Withdraw tokens by the owner (to claim rewards)
    function withdrawTokens(uint256 _amount) public onlyOwner {
        stakingToken.transfer(owner(), _amount);
    }

    // View participant's stake
    function getStake(address _participant) public view returns (uint256) {
        return stakes[_participant];
    }
}
