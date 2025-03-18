# Dungeons and DeFi - Farcaster Frame UI Guide

## Frame Constraints & Requirements

### Technical Limitations
- Maximum 4 buttons per frame
- Single image per frame
- Image dimensions: 1200x630px (recommended)
- Limited state management through frame actions
- No client-side JavaScript
- Each interaction requires a new frame render

### User Context
- Users interact through Warpcast or other Farcaster clients
- Each frame is a new state
- Session management through frame metadata
- Connected wallet information available through frame context

## Core Game Screens

### 1. Welcome Screen
```typescript
interface WelcomeFrame {
  image: {
    url: string; // 1200x630 welcome image
    alt: "Welcome to Dungeons and DeFi"
  };
  buttons: [
    { text: "Start New Game", action: "START_GAME" },
    { text: "Load Character", action: "LOAD_GAME" },
    { text: "How to Play", action: "SHOW_TUTORIAL" }
  ]
}
```

#### Visual Elements
- Game logo
- Background artwork
- Character preview (if existing)
- Simple animation effects

### 2. Character Creation
```typescript
interface CharacterFrame {
  // Split across multiple frames due to button limitation
  frames: {
    race: {
      image: string; // Race selection visual
      buttons: [
        { text: "Human", action: "SELECT_RACE_HUMAN" },
        { text: "Elf", action: "SELECT_RACE_ELF" },
        { text: "Dwarf", action: "SELECT_RACE_DWARF" },
        { text: "More →", action: "NEXT_RACE_PAGE" }
      ]
    },
    class: {
      image: string; // Class selection visual
      buttons: [
        { text: "Yield Sage", action: "SELECT_CLASS_SAGE" },
        { text: "Chain Walker", action: "SELECT_CLASS_WALKER" },
        { text: "Oracle Knight", action: "SELECT_CLASS_KNIGHT" },
        { text: "More →", action: "NEXT_CLASS_PAGE" }
      ]
    }
  }
}
```

### 3. Quest Board
```typescript
interface QuestFrame {
  image: {
    url: string; // Dynamic quest board image
    elements: [
      { type: "quest_title", position: [x, y] },
      { type: "quest_reward", position: [x, y] },
      { type: "difficulty_indicator", position: [x, y] }
    ]
  };
  buttons: [
    { text: "Accept Quest", action: "ACCEPT_QUEST" },
    { text: "Next Quest", action: "NEXT_QUEST" },
    { text: "View Details", action: "QUEST_DETAILS" },
    { text: "Back", action: "RETURN_MENU" }
  ]
}
```

### 4. Adventure View
```typescript
interface AdventureFrame {
  image: {
    url: string; // Dynamic adventure scene
    elements: [
      { type: "player_status", position: [x, y] },
      { type: "current_objective", position: [x, y] },
      { type: "resources", position: [x, y] }
    ]
  };
  buttons: [
    { text: "Take Action", action: "PERFORM_ACTION" },
    { text: "Use Item", action: "USE_ITEM" },
    { text: "Check Status", action: "VIEW_STATUS" },
    { text: "Retreat", action: "RETREAT" }
  ]
}
```

### 5. Combat Frame
```typescript
interface CombatFrame {
  image: {
    url: string; // Dynamic combat scene
    elements: [
      { type: "player_health", position: [x, y] },
      { type: "enemy_health", position: [x, y] },
      { type: "combat_log", position: [x, y] }
    ]
  };
  buttons: [
    { text: "Attack", action: "COMBAT_ATTACK" },
    { text: "Use Ability", action: "COMBAT_ABILITY" },
    { text: "Use Item", action: "COMBAT_ITEM" },
    { text: "Flee", action: "COMBAT_FLEE" }
  ]
}
```

## State Management

### 1. Game State
```typescript
interface GameState {
  playerId: string;      // Farcaster user ID
  characterId?: string;  // On-chain character NFT ID
  currentFrame: string;  // Current frame identifier
  inventory: string[];   // Array of item IDs
  questProgress: {
    currentQuest?: string;
    objectives: string[];
    progress: number;
  }
}
```

### 2. Frame Flow
```typescript
type FrameFlow = {
  current: string;
  previous: string[];
  available_actions: string[];
  state_data: Record<string, any>;
}
```

## Image Generation

### 1. Dynamic Image Components
```typescript
interface ImageComponents {
  backgrounds: {
    town: string;
    dungeon: string;
    combat: string;
    quest_board: string;
  };
  characters: {
    races: Record<string, string>;
    classes: Record<string, string>;
    equipment: Record<string, string>;
  };
  ui_elements: {
    health_bar: string;
    resource_bar: string;
    inventory_slot: string;
  }
}
```

### 2. Image Generation Rules
- Pre-generate common backgrounds
- Layer dynamic elements on demand
- Use consistent positioning for UI elements
- Ensure text is readable at frame size
- Optimize for quick loading

## Frame Transitions

### 1. Navigation Flow
```typescript
interface NavigationFlow {
  main_menu: string[];
  character_creation: string[];
  questing: string[];
  combat: string[];
  inventory: string[];
}
```

### 2. State Preservation
- Use frame metadata for state
- Store critical data on-chain
- Cache common elements
- Handle interruptions gracefully

## Integration Points

### 1. Smart Contract Calls
```typescript
interface ContractIntegration {
  character_creation: string;
  quest_progress: string;
  inventory_management: string;
  combat_resolution: string;
}
```

### 2. Farcaster Frame Actions
```typescript
type FrameAction = {
  type: string;
  payload: Record<string, any>;
  metadata: {
    user: string;
    timestamp: number;
    frame_id: string;
  }
}
```

## Best Practices

### 1. Performance
- Pre-generate common images
- Cache frame responses
- Optimize state transitions
- Minimize contract calls

### 2. User Experience
- Clear action buttons
- Consistent navigation
- Visual feedback
- Error handling

### 3. Design Guidelines
- High contrast text
- Clear action indicators
- Consistent UI elements
- Readable font sizes

## Error Handling

### 1. Common Errors
```typescript
interface ErrorFrames {
  transaction_failed: FrameData;
  invalid_action: FrameData;
  timeout: FrameData;
  network_error: FrameData;
}
```

### 2. Recovery Flows
- Clear error messages
- Retry options
- Alternative actions
- State recovery

## Testing Checklist

### 1. Frame Validation
- Image dimensions
- Button functionality
- State preservation
- Error handling

### 2. Integration Testing
- Contract interactions
- Frame transitions
- State management
- Error recovery

## Implementation Notes

### 1. Frame Generation
```typescript
interface FrameGenerator {
  template: string;
  dynamic_elements: {
    position: [number, number];
    content: string;
    style: Record<string, string>;
  }[];
  buttons: Button[];
}
```

### 2. State Updates
```typescript
interface StateUpdate {
  action: string;
  previous_state: GameState;
  new_state: GameState;
  frame_response: FrameData;
}
```

### 3. Response Times
- Generate frames < 2s
- Contract calls < 5s
- Image generation < 3s
- Total response < 5s

## Security Considerations

### 1. Frame Security
- Validate all inputs
- Sanitize displayed data
- Verify frame signatures
- Check user permissions

### 2. Contract Security
- Validate transactions
- Check allowances
- Verify ownership
- Handle failures