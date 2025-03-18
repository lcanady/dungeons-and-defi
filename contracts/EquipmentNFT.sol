// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract EquipmentNFT is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // Equipment types
    enum EquipmentType { Weapon, Armor, Accessory }
    
    // Equipment rarity
    enum Rarity { Common, Uncommon, Rare, Epic, Legendary }

    // Equipment stats structure
    struct EquipmentStats {
        EquipmentType equipType;
        Rarity rarity;
        uint16 attack;
        uint16 defense;
        uint16 magic;
        uint16 luck;
        uint16 defiBonus;
        string name;
        bool isStaked;
    }

    // Mapping from token ID to equipment stats
    mapping(uint256 => EquipmentStats) public equipmentStats;
    
    // Base prices for different rarities (in wei)
    mapping(Rarity => uint256) public mintPrices;

    // Events
    event EquipmentMinted(address indexed owner, uint256 indexed tokenId, EquipmentType equipType, Rarity rarity);
    event EquipmentStaked(uint256 indexed tokenId, bool isStaked);
    event EquipmentUpgraded(uint256 indexed tokenId, Rarity newRarity);

    constructor() ERC721("DungeonsAndDeFi Equipment", "DNDE") Ownable(msg.sender) {
        // Set mint prices for different rarities
        mintPrices[Rarity.Common] = 0.05 ether;
        mintPrices[Rarity.Uncommon] = 0.1 ether;
        mintPrices[Rarity.Rare] = 0.2 ether;
        mintPrices[Rarity.Epic] = 0.5 ether;
        mintPrices[Rarity.Legendary] = 1 ether;
    }

    // Mint new equipment
    function mintEquipment(
        EquipmentType _type,
        Rarity _rarity,
        string memory _name
    ) external payable {
        require(msg.value >= mintPrices[_rarity], "Insufficient payment");

        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        // Generate equipment stats based on type and rarity
        (uint16 atk, uint16 def, uint16 mag, uint16 luk, uint16 defi) = _generateStats(_type, _rarity);

        // Create equipment stats
        equipmentStats[newTokenId] = EquipmentStats({
            equipType: _type,
            rarity: _rarity,
            attack: atk,
            defense: def,
            magic: mag,
            luck: luk,
            defiBonus: defi,
            name: _name,
            isStaked: false
        });

        _safeMint(msg.sender, newTokenId);
        emit EquipmentMinted(msg.sender, newTokenId, _type, _rarity);
    }

    // Generate stats based on equipment type and rarity
    function _generateStats(EquipmentType _type, Rarity _rarity) 
        internal 
        view 
        returns (uint16, uint16, uint16, uint16, uint16) 
    {
        // Use block data for randomness (Note: In production, use a more secure randomness source)
        uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, _tokenIds.current())));
        
        // Rarity multiplier (increases stats based on rarity)
        uint16 rarityMul = uint16(10 + uint16(_rarity) * 5);

        if (_type == EquipmentType.Weapon) {
            return (
                uint16((30 + (rand % 21)) * rarityMul / 10),  // Attack
                uint16((5 + (rand % 11)) * rarityMul / 10),   // Defense
                uint16((10 + (rand % 16)) * rarityMul / 10),  // Magic
                uint16((10 + (rand % 11)) * rarityMul / 10),  // Luck
                uint16((5 + (rand % 11)) * rarityMul / 10)    // DeFi Bonus
            );
        } else if (_type == EquipmentType.Armor) {
            return (
                uint16((5 + (rand % 11)) * rarityMul / 10),   // Attack
                uint16((30 + (rand % 21)) * rarityMul / 10),  // Defense
                uint16((5 + (rand % 11)) * rarityMul / 10),   // Magic
                uint16((10 + (rand % 11)) * rarityMul / 10),  // Luck
                uint16((10 + (rand % 11)) * rarityMul / 10)   // DeFi Bonus
            );
        } else { // Accessory
            return (
                uint16((10 + (rand % 11)) * rarityMul / 10),  // Attack
                uint16((10 + (rand % 11)) * rarityMul / 10),  // Defense
                uint16((10 + (rand % 11)) * rarityMul / 10),  // Magic
                uint16((20 + (rand % 21)) * rarityMul / 10),  // Luck
                uint16((15 + (rand % 16)) * rarityMul / 10)   // DeFi Bonus
            );
        }
    }

    // Stake equipment for passive rewards
    function toggleStaking(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "Not token owner");
        
        EquipmentStats storage stats = equipmentStats[tokenId];
        stats.isStaked = !stats.isStaked;
        
        emit EquipmentStaked(tokenId, stats.isStaked);
    }

    // Upgrade equipment rarity (requires payment and might fail)
    function upgradeEquipment(uint256 tokenId) external payable {
        require(ownerOf(tokenId) == msg.sender, "Not token owner");
        
        EquipmentStats storage stats = equipmentStats[tokenId];
        require(stats.rarity != Rarity.Legendary, "Already maximum rarity");
        
        uint256 upgradeCost = mintPrices[Rarity(uint8(stats.rarity) + 1)];
        require(msg.value >= upgradeCost, "Insufficient payment");

        // 50% chance of successful upgrade
        uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, tokenId)));
        require(rand % 2 == 0, "Upgrade failed");

        // Upgrade rarity and increase stats
        stats.rarity = Rarity(uint8(stats.rarity) + 1);
        stats.attack = uint16(stats.attack * 12 / 10);    // +20%
        stats.defense = uint16(stats.defense * 12 / 10);  // +20%
        stats.magic = uint16(stats.magic * 12 / 10);      // +20%
        stats.luck = uint16(stats.luck * 12 / 10);        // +20%
        stats.defiBonus = uint16(stats.defiBonus * 12 / 10); // +20%

        emit EquipmentUpgraded(tokenId, stats.rarity);
    }

    // Override required functions
    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, value);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}