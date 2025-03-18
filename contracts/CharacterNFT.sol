// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract CharacterNFT is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // Character stats structure
    struct CharacterStats {
        uint8 characterClass; // 0: Warrior, 1: Mage, 2: Rogue
        uint16 level;
        uint16 attack;
        uint16 defense;
        uint16 magic;
        uint16 luck;
        uint16 defiBonus; // Percentage boost for DeFi activities
        uint256 experience;
        uint256 lastActionTimestamp;
    }

    // Equipment slots structure
    struct Equipment {
        uint256 weaponId;
        uint256 armorId;
        uint256 accessoryId;
    }

    // Mapping from token ID to character stats
    mapping(uint256 => CharacterStats) public characterStats;
    
    // Mapping from token ID to equipment
    mapping(uint256 => Equipment) public characterEquipment;

    // Base minting price
    uint256 public constant MINT_PRICE = 0.1 ether;

    // Events
    event CharacterMinted(address indexed owner, uint256 indexed tokenId, uint8 characterClass);
    event CharacterLevelUp(uint256 indexed tokenId, uint16 newLevel);
    event EquipmentChanged(uint256 indexed tokenId, uint256 weaponId, uint256 armorId, uint256 accessoryId);
    event ExperienceGained(uint256 indexed tokenId, uint256 amount);

    constructor() ERC721("DungeonsAndDeFi Character", "DNDC") Ownable(msg.sender) {}

    // Mint new character
    function mintCharacter(uint8 _class) external payable {
        require(msg.value >= MINT_PRICE, "Insufficient payment");
        require(_class <= 2, "Invalid character class");

        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        // Generate random stats based on class
        (uint16 atk, uint16 def, uint16 mag, uint16 luk, uint16 defi) = _generateBaseStats(_class);

        // Create character stats
        characterStats[newTokenId] = CharacterStats({
            characterClass: _class,
            level: 1,
            attack: atk,
            defense: def,
            magic: mag,
            luck: luk,
            defiBonus: defi,
            experience: 0,
            lastActionTimestamp: block.timestamp
        });

        _safeMint(msg.sender, newTokenId);
        emit CharacterMinted(msg.sender, newTokenId, _class);
    }

    // Generate base stats based on character class
    function _generateBaseStats(uint8 _class) internal view returns (uint16, uint16, uint16, uint16, uint16) {
        // Use block data for randomness (Note: In production, use a more secure randomness source)
        uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, _tokenIds.current())));
        
        if (_class == 0) { // Warrior
            return (
                uint16(50 + (rand % 21)),  // Attack: 50-70
                uint16(40 + (rand % 31)),  // Defense: 40-70
                uint16(10 + (rand % 21)),  // Magic: 10-30
                uint16(20 + (rand % 21)),  // Luck: 20-40
                uint16(10 + (rand % 16))   // DeFi Bonus: 10-25
            );
        } else if (_class == 1) { // Mage
            return (
                uint16(20 + (rand % 21)),  // Attack: 20-40
                uint16(20 + (rand % 21)),  // Defense: 20-40
                uint16(50 + (rand % 31)),  // Magic: 50-80
                uint16(30 + (rand % 21)),  // Luck: 30-50
                uint16(15 + (rand % 16))   // DeFi Bonus: 15-30
            );
        } else { // Rogue
            return (
                uint16(35 + (rand % 26)),  // Attack: 35-60
                uint16(25 + (rand % 26)),  // Defense: 25-50
                uint16(20 + (rand % 21)),  // Magic: 20-40
                uint16(40 + (rand % 31)),  // Luck: 40-70
                uint16(20 + (rand % 16))   // DeFi Bonus: 20-35
            );
        }
    }

    // Equip items to character
    function equipItems(uint256 tokenId, uint256 weaponId, uint256 armorId, uint256 accessoryId) external {
        require(ownerOf(tokenId) == msg.sender, "Not token owner");
        
        // Add equipment validation here
        characterEquipment[tokenId] = Equipment(weaponId, armorId, accessoryId);
        emit EquipmentChanged(tokenId, weaponId, armorId, accessoryId);
    }

    // Gain experience
    function gainExperience(uint256 tokenId, uint256 amount) external {
        require(ownerOf(tokenId) == msg.sender, "Not token owner");
        
        CharacterStats storage stats = characterStats[tokenId];
        stats.experience += amount;
        
        // Check for level up
        uint256 requiredExp = stats.level * 1000;
        if (stats.experience >= requiredExp) {
            stats.level += 1;
            emit CharacterLevelUp(tokenId, stats.level);
        }
        
        emit ExperienceGained(tokenId, amount);
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