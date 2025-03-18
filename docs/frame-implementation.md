# Dungeons and DeFi - Farcaster Frame v2 Implementation Guide

## Project Setup

### Dependencies
```bash
yarn create next-app dungeons-and-defi
yarn add @farcaster/frame-sdk
yarn add wagmi viem@2.x @tanstack/react-query
```

### Core Components Structure

```typescript
// Project structure
src/
  app/
    layout.tsx      // Root layout with providers
    page.tsx        // Main game frame
    providers.tsx   // Wagmi and other providers
  components/
    providers/
      WagmiProvider.tsx
    game/
      QuestBoard.tsx
      Combat.tsx
      Character.tsx
  lib/
    connector.ts    // Farcaster wallet connector
```

## Frame Implementation

### Base Layout (app/layout.tsx)
```typescript
import { Providers } from '~/app/providers';

export const metadata = {
  title: 'Dungeons and DeFi',
  description: 'Web3 RPG in Farcaster Frames'
};

export default function RootLayout({
  children
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
```

### Main Game Component (app/page.tsx)
```typescript
'use client';

import { useEffect, useState } from 'react';
import sdk, { type FrameContext } from '@farcaster/frame-sdk';

export default function GameFrame() {
  const [isSDKLoaded, setIsSDKLoaded] = useState(false);
  const [context, setContext] = useState<FrameContext>();
  
  useEffect(() => {
    const initializeFrame = async () => {
      setContext(await sdk.context);
      sdk.actions.ready();
    };

    if (sdk && !isSDKLoaded) {
      setIsSDKLoaded(true);
      initializeFrame();
    }
  }, [isSDKLoaded]);

  // Frame rendering based on game state
  return (
    <div className="w-[1200px] h-[630px]">
      {/* Dynamic game content */}
    </div>
  );
}
```

## Game State Management

### Frame Context
```typescript
interface GameState {
  currentScene: 'CHARACTER_CREATE' | 'QUEST_BOARD' | 'COMBAT' | 'INVENTORY';
  character?: {
    id: string;
    class: string;
    level: number;
    experience: number;
  };
  currentQuest?: {
    id: string;
    progress: number;
  };
}
```

### Frame Actions
```typescript
const gameActions = {
  // Character Creation
  createCharacter: () => {
    sdk.actions.openUrl('/mint-character');
  },

  // Quest Interaction
  startQuest: (questId: string) => {
    sdk.actions.openUrl(`/quest/${questId}`);
  },

  // Combat Actions
  performAction: (actionType: string) => {
    // Handle combat actions through frame transitions
  }
};
```

## Frame Transitions

### Character Creation Flow
```typescript
interface CharacterCreationFrame {
  image: {
    url: string; // 1200x630 character creation screen
  };
  buttons: [
    { text: "Select Class", action: "select_class" },
    { text: "Customize", action: "customize" },
    { text: "Confirm", action: "confirm" },
    { text: "Back", action: "back" }
  ];
}
```

### Quest Board Flow
```typescript
interface QuestBoardFrame {
  image: {
    url: string; // 1200x630 quest board
  };
  buttons: [
    { text: "Accept Quest", action: "accept_quest" },
    { text: "View Details", action: "view_details" },
    { text: "Next Quest", action: "next_quest" },
    { text: "Character", action: "view_character" }
  ];
}
```

## Smart Contract Integration

### Wallet Connection
```typescript
import { useAccount, useConnect } from 'wagmi';
import { config } from '~/components/providers/WagmiProvider';

function WalletConnection() {
  const { address, isConnected } = useAccount();
  const { connect } = useConnect();

  return (
    <button onClick={() => connect({ connector: config.connectors[0] })}>
      {isConnected ? truncateAddress(address) : 'Connect Wallet'}
    </button>
  );
}
```

### Transaction Handling
```typescript
import { useSendTransaction } from 'wagmi';

function GameActions() {
  const { sendTransaction } = useSendTransaction();

  const mintCharacter = async () => {
    sendTransaction({
      to: CONTRACT_ADDRESS,
      data: 'MINT_FUNCTION_SIGNATURE',
    });
  };
}
```

## Image Generation

### Frame Image Requirements
- Dimensions: 1200x630px
- Format: PNG/JPEG
- Max size: 10MB
- Content: Clear visual hierarchy

### Dynamic Image Generation
```typescript
interface FrameImage {
  background: string;
  character?: string;
  ui_elements: {
    health_bar?: string;
    mana_bar?: string;
    inventory_slots?: string[];
  };
  effects?: string[];
}
```

## Error Handling

### Frame Error States
```typescript
interface ErrorFrame {
  image: {
    url: string; // Error state image
  };
  buttons: [
    { text: "Retry", action: "retry" },
    { text: "Back", action: "back_to_main" }
  ];
}
```

## Performance Optimization

### Image Optimization
- Pre-generate common backgrounds
- Cache frequently used UI elements
- Use efficient image formats
- Implement lazy loading

### State Management
- Minimize state transitions
- Cache frame responses
- Optimize contract calls
- Handle network latency

## Security Considerations

### Transaction Safety
```typescript
interface TransactionFrame {
  image: {
    url: string; // Transaction confirmation screen
  };
  buttons: [
    { text: "Confirm", action: "confirm_tx" },
    { text: "Cancel", action: "cancel_tx" }
  ];
}
```

### Data Validation
- Validate all user inputs
- Verify frame signatures
- Check transaction parameters
- Implement rate limiting

## Testing Guidelines

### Frame Testing
```typescript
interface FrameTest {
  description: string;
  setup: () => void;
  actions: {
    input: any;
    expectedOutput: any;
  }[];
  cleanup: () => void;
}
```

### Integration Testing
- Test wallet connections
- Verify frame transitions
- Check image generation
- Validate contract interactions