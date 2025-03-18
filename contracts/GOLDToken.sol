// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract GOLDToken is ERC20, ERC20Burnable, ERC20Capped, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant GAME_ROLE = keccak256("GAME_ROLE");
    
    // Reward rates
    uint256 public questRewardRate = 100 * 10**18;    // 100 GOLD per quest
    uint256 public dungeonRewardRate = 500 * 10**18;  // 500 GOLD per dungeon
    uint256 public stakingRewardRate = 10 * 10**18;   // 10 GOLD per day per NFT staked
    
    // Cooldowns
    mapping(address => uint256) public lastQuestTimestamp;
    mapping(address => uint256) public lastDungeonTimestamp;
    mapping(address => uint256) public lastStakingClaim;
    
    // Quest cooldown: 1 hour
    uint256 public constant QUEST_COOLDOWN = 1 hours;
    // Dungeon cooldown: 4 hours
    uint256 public constant DUNGEON_COOLDOWN = 4 hours;
    // Staking claim cooldown: 1 day
    uint256 public constant STAKING_COOLDOWN = 1 days;

    constructor() 
        ERC20("Dungeons and DeFi Gold", "GOLD")
        ERC20Capped(1000000000 * 10**18)  // 1 billion max supply
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        
        // Mint initial supply
        _mint(msg.sender, 100000000 * 10**18); // 100 million initial supply
    }

    // Quest reward
    function claimQuestReward() external {
        require(hasRole(GAME_ROLE, msg.sender), "Must be called by game contract");
        require(block.timestamp >= lastQuestTimestamp[msg.sender] + QUEST_COOLDOWN, "Quest on cooldown");
        
        lastQuestTimestamp[msg.sender] = block.timestamp;
        _mint(msg.sender, questRewardRate);
    }

    // Dungeon reward
    function claimDungeonReward() external {
        require(hasRole(GAME_ROLE, msg.sender), "Must be called by game contract");
        require(block.timestamp >= lastDungeonTimestamp[msg.sender] + DUNGEON_COOLDOWN, "Dungeon on cooldown");
        
        lastDungeonTimestamp[msg.sender] = block.timestamp;
        _mint(msg.sender, dungeonRewardRate);
    }

    // Staking reward
    function claimStakingReward(uint256 numNFTsStaked) external {
        require(hasRole(GAME_ROLE, msg.sender), "Must be called by game contract");
        require(block.timestamp >= lastStakingClaim[msg.sender] + STAKING_COOLDOWN, "Staking reward on cooldown");
        require(numNFTsStaked > 0, "No NFTs staked");
        
        lastStakingClaim[msg.sender] = block.timestamp;
        _mint(msg.sender, stakingRewardRate * numNFTsStaked);
    }

    // Admin functions to adjust reward rates
    function setQuestRewardRate(uint256 newRate) external onlyRole(DEFAULT_ADMIN_ROLE) {
        questRewardRate = newRate;
    }

    function setDungeonRewardRate(uint256 newRate) external onlyRole(DEFAULT_ADMIN_ROLE) {
        dungeonRewardRate = newRate;
    }

    function setStakingRewardRate(uint256 newRate) external onlyRole(DEFAULT_ADMIN_ROLE) {
        stakingRewardRate = newRate;
    }

    // Required overrides
    function _mint(address account, uint256 amount)
        internal
        override(ERC20, ERC20Capped)
    {
        super._mint(account, amount);
    }
}