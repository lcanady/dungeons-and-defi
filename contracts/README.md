# Smart Contracts Documentation

This directory contains the core smart contracts for the Dungeons and DeFi game.

## Core Contracts

### CharacterNFT.sol
- ERC721 implementation for character NFTs
- Supports character classes (Warrior, Mage, Rogue)
- Includes stats system and leveling mechanics
- Equipment system integration
- Experience and level progression

### EquipmentNFT.sol
- ERC721 implementation for equipment NFTs
- Different equipment types (Weapon, Armor, Accessory)
- Rarity system with stat bonuses
- Staking mechanics for passive rewards
- Upgrade system with success chance

### GOLDToken.sol
- ERC20 implementation for the game's primary token
- Capped supply of 1 billion tokens
- Quest and dungeon reward mechanics
- Staking reward system
- Cooldown mechanics for different activities

### DGOVToken.sol
- ERC20 implementation for governance token
- Voting capabilities for game decisions
- Staking mechanics with GOLD token
- Tournament and quest reward distribution
- Maximum supply of 10 million tokens

## Token Economics

### GOLD Token
- **Max Supply**: 1,000,000,000 GOLD
- **Initial Supply**: 100,000,000 GOLD
- **Distribution**:
  - 40% Player rewards
  - 20% Treasury
  - 20% Development
  - 15% Community rewards
  - 5% Team

### DGOV Token
- **Max Supply**: 10,000,000 DGOV
- **Initial Supply**: 1,000,000 DGOV
- **Earning Methods**:
  - Staking GOLD
  - Completing epic quests
  - Winning tournaments
  - Governance participation

## Game Mechanics

### Character System
- Three character classes
- Stat-based progression
- Equipment slots
- Experience and leveling

### Equipment System
- Three equipment types
- Five rarity levels
- Upgrade mechanics
- Staking for rewards

### Reward System
- Quest rewards
- Dungeon completion
- Tournament prizes
- Staking yields

## Security Features

### Access Control
- Role-based permissions
- Admin functions for adjustments
- Emergency pause capabilities
- Upgrade mechanics

### Economic Balance
- Cooldown periods
- Reward rate adjustments
- Supply caps
- Staking requirements

## Integration Guide

### Character Creation
```solidity
// Mint a new character
characterNFT.mintCharacter{value: 0.1 ether}(0); // 0 for Warrior

// Equip items
characterNFT.equipItems(tokenId, weaponId, armorId, accessoryId);
```

### Equipment Management
```solidity
// Mint new equipment
equipmentNFT.mintEquipment{value: 0.05 ether}(
    EquipmentType.Weapon,
    Rarity.Common,
    "Training Sword"
);

// Upgrade equipment
equipmentNFT.upgradeEquipment{value: 0.1 ether}(tokenId);
```

### Token Integration
```solidity
// Claim quest reward
goldToken.claimQuestReward();

// Stake GOLD for DGOV
dgovToken.stakeGold(1000 * 10**18); // Stake 1000 GOLD
```

## Deployment

1. Deploy GOLDToken
2. Deploy DGOVToken
3. Deploy CharacterNFT
4. Deploy EquipmentNFT
5. Set up roles and permissions
6. Initialize game parameters

## Testing

Run tests using Foundry:
```bash
forge test
```

## Auditing

The contracts have been designed with security best practices:
- Access control
- Reentrancy protection
- Integer overflow protection
- Gas optimization
- Event emission for tracking