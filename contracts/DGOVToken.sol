// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract DGOVToken is ERC20, ERC20Permit, ERC20Votes, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant GAME_ROLE = keccak256("GAME_ROLE");

    // Maximum supply of 10 million tokens
    uint256 public constant MAX_SUPPLY = 10_000_000 * 10**18;
    
    // Earning rates
    uint256 public stakingRate = 1 * 10**18;      // 1 DGOV per day per 1000 GOLD staked
    uint256 public questRate = 5 * 10**18;        // 5 DGOV per epic quest
    uint256 public tournamentRate = 100 * 10**18; // 100 DGOV per tournament win
    
    // Cooldowns and requirements
    mapping(address => uint256) public lastStakingReward;
    mapping(address => uint256) public stakedGold;
    uint256 public constant STAKING_COOLDOWN = 1 days;
    uint256 public constant MIN_STAKE_AMOUNT = 1000 * 10**18; // 1000 GOLD

    // Events
    event GoldStaked(address indexed user, uint256 amount);
    event GoldUnstaked(address indexed user, uint256 amount);
    event StakingRewardClaimed(address indexed user, uint256 amount);
    event QuestRewardClaimed(address indexed user, uint256 amount);
    event TournamentRewardClaimed(address indexed user, uint256 amount);

    constructor() 
        ERC20("Dungeons and DeFi Governance", "DGOV")
        ERC20Permit("Dungeons and DeFi Governance")
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        
        // Mint initial supply for development and early rewards
        _mint(msg.sender, 1_000_000 * 10**18); // 1 million initial supply
    }

    // Stake GOLD tokens to earn DGOV
    function stakeGold(uint256 amount) external {
        require(amount >= MIN_STAKE_AMOUNT, "Must stake at least 1000 GOLD");
        
        // Transfer GOLD from user (requires approval)
        // Note: This would interact with the GOLD token contract
        // goldToken.transferFrom(msg.sender, address(this), amount);
        
        stakedGold[msg.sender] += amount;
        emit GoldStaked(msg.sender, amount);
    }

    // Unstake GOLD tokens
    function unstakeGold(uint256 amount) external {
        require(stakedGold[msg.sender] >= amount, "Insufficient staked balance");
        
        stakedGold[msg.sender] -= amount;
        // Transfer GOLD back to user
        // goldToken.transfer(msg.sender, amount);
        
        emit GoldUnstaked(msg.sender, amount);
    }

    // Claim staking rewards
    function claimStakingReward() external {
        require(block.timestamp >= lastStakingReward[msg.sender] + STAKING_COOLDOWN, "Reward on cooldown");
        require(stakedGold[msg.sender] >= MIN_STAKE_AMOUNT, "No GOLD staked");
        
        uint256 reward = (stakedGold[msg.sender] * stakingRate) / (1000 * 10**18);
        require(totalSupply() + reward <= MAX_SUPPLY, "Would exceed max supply");
        
        lastStakingReward[msg.sender] = block.timestamp;
        _mint(msg.sender, reward);
        
        emit StakingRewardClaimed(msg.sender, reward);
    }

    // Claim quest reward (called by game contract)
    function claimQuestReward(address player) external onlyRole(GAME_ROLE) {
        require(totalSupply() + questRate <= MAX_SUPPLY, "Would exceed max supply");
        
        _mint(player, questRate);
        emit QuestRewardClaimed(player, questRate);
    }

    // Claim tournament reward (called by game contract)
    function claimTournamentReward(address player) external onlyRole(GAME_ROLE) {
        require(totalSupply() + tournamentRate <= MAX_SUPPLY, "Would exceed max supply");
        
        _mint(player, tournamentRate);
        emit TournamentRewardClaimed(player, tournamentRate);
    }

    // Admin functions to adjust reward rates
    function setStakingRate(uint256 newRate) external onlyRole(DEFAULT_ADMIN_ROLE) {
        stakingRate = newRate;
    }

    function setQuestRate(uint256 newRate) external onlyRole(DEFAULT_ADMIN_ROLE) {
        questRate = newRate;
    }

    function setTournamentRate(uint256 newRate) external onlyRole(DEFAULT_ADMIN_ROLE) {
        tournamentRate = newRate;
    }

    // Required overrides for ERC20Votes
    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }
}