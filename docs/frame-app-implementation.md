# Dungeons and DeFi - Farcaster Frame v2 Web App Implementation

## Initial Setup

```bash
# Create Next.js app with TypeScript
yarn create next-app dungeons-and-defi
cd dungeons-and-defi

# Install required dependencies
yarn add @farcaster/frame-sdk
yarn add wagmi viem@2.x @tanstack/react-query
```

## Project Structure
```
src/
  app/
    layout.tsx         # Root layout with providers
    page.tsx          # Main game component
    providers.tsx     # Wagmi provider setup
  components/
    providers/
      WagmiProvider.tsx
    game/
      GameBoard.tsx   # Main game interface
  lib/
    connector.ts      # Farcaster wallet connector
```

## Core Components

### 1. Farcaster Wallet Connector (lib/connector.ts)
```typescript
import sdk from '@farcaster/frame-sdk';
import { createConnector } from 'wagmi';

export function frameConnector() {
  let connected = true;

  return createConnector<typeof sdk.wallet.ethProvider>((config) => ({
    id: 'farcaster',
    name: 'Farcaster Wallet',
    type: frameConnector.type,
    
    async setup() {
      this.connect({ chainId: config.chains[0].id });
    },
    
    async connect({ chainId } = {}) {
      const provider = await this.getProvider();
      const accounts = await provider.request({
        method: 'eth_requestAccounts',
      });
      // ... rest of connector implementation
    },
    
    async getProvider() {
      return sdk.wallet.ethProvider;
    },
  }));
}
```

### 2. Wagmi Provider Setup (components/providers/WagmiProvider.tsx)
```typescript
import { createConfig, WagmiProvider } from 'wagmi';
import { base } from 'wagmi/chains';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { frameConnector } from '~/lib/connector';

export const config = createConfig({
  chains: [base],
  transports: {
    [base.id]: http(),
  },
  connectors: [frameConnector()],
});

const queryClient = new QueryClient();

export default function Provider({ children }: { children: React.ReactNode }) {
  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        {children}
      </QueryClientProvider>
    </WagmiProvider>
  );
}
```

### 3. Main Game Component (app/page.tsx)
```typescript
'use client';

import { useEffect, useState } from 'react';
import sdk, { type FrameContext } from '@farcaster/frame-sdk';
import { useAccount, useConnect } from 'wagmi';
import { config } from '~/components/providers/WagmiProvider';

export default function Game() {
  const [isSDKLoaded, setIsSDKLoaded] = useState(false);
  const [context, setContext] = useState<FrameContext>();
  const { address, isConnected } = useAccount();
  const { connect } = useConnect();

  useEffect(() => {
    const load = async () => {
      setContext(await sdk.context);
      sdk.actions.ready();
    };

    if (sdk && !isSDKLoaded) {
      setIsSDKLoaded(true);
      load();
    }
  }, [isSDKLoaded]);

  // Game UI implementation
  return (
    <div className="w-full min-h-screen bg-gray-900 text-white">
      <header className="p-4">
        {!isConnected ? (
          <button
            onClick={() => connect({ connector: config.connectors[0] })}
            className="px-4 py-2 bg-blue-600 rounded"
          >
            Connect Wallet
          </button>
        ) : (
          <div>Connected: {address}</div>
        )}
      </header>

      <main className="container mx-auto p-4">
        {/* Game content */}
      </main>
    </div>
  );
}
```

## Game Actions Implementation

### 1. SDK Actions
```typescript
// Example of using SDK actions
const gameActions = {
  // Open external URL (e.g., for NFT minting)
  openMint: () => {
    sdk.actions.openUrl('https://your-mint-url.com');
  },

  // Close the frame
  closeGame: () => {
    sdk.actions.close();
  }
};
```

### 2. Transaction Handling
```typescript
import { useSendTransaction } from 'wagmi';

function GameTransactions() {
  const { sendTransaction } = useSendTransaction();

  const handleGameAction = async () => {
    try {
      const tx = await sendTransaction({
        to: 'CONTRACT_ADDRESS',
        data: 'FUNCTION_DATA'
      });
      // Handle transaction response
    } catch (error) {
      console.error('Transaction failed:', error);
    }
  };
}
```

### 3. Message Signing
```typescript
import { useSignMessage } from 'wagmi';

function SignatureActions() {
  const { signMessage } = useSignMessage();

  const handleSign = async () => {
    try {
      await signMessage({ message: 'Game action verification' });
      // Handle signature response
    } catch (error) {
      console.error('Signing failed:', error);
    }
  };
}
```

## Game State Management

```typescript
import { create } from 'zustand';

interface GameState {
  currentScene: string;
  character: {
    id: string;
    level: number;
    experience: number;
  } | null;
  inventory: Item[];
  quests: Quest[];
}

const useGameStore = create<GameState>((set) => ({
  currentScene: 'MAIN_MENU',
  character: null,
  inventory: [],
  quests: [],
  
  setScene: (scene: string) => set({ currentScene: scene }),
  updateCharacter: (updates: Partial<Character>) => 
    set((state) => ({
      character: { ...state.character, ...updates }
    })),
  // Additional state management functions
}));
```

## Error Handling

```typescript
function ErrorBoundary({ children }: { children: React.ReactNode }) {
  const [hasError, setHasError] = useState(false);

  if (hasError) {
    return (
      <div className="error-container">
        <h2>Something went wrong</h2>
        <button onClick={() => window.location.reload()}>
          Retry
        </button>
      </div>
    );
  }

  return children;
}
```

## Game Scenes Implementation

### 1. Character Creation
```typescript
function CharacterCreation() {
  const { address } = useAccount();
  const [characterData, setCharacterData] = useState({
    name: '',
    class: '',
  });

  const handleCreate = async () => {
    // Implement character creation logic
    // This could involve minting an NFT or calling a contract
  };

  return (
    <div className="character-creation">
      {/* Character creation form */}
    </div>
  );
}
```

### 2. Quest Board
```typescript
function QuestBoard() {
  const [quests, setQuests] = useState([]);
  const { character } = useGameStore();

  useEffect(() => {
    // Fetch available quests
    // This could be from a contract or API
  }, []);

  return (
    <div className="quest-board">
      {/* Quest list and interactions */}
    </div>
  );
}
```

### 3. Combat Scene
```typescript
function CombatScene() {
  const { character } = useGameStore();
  const [combatState, setCombatState] = useState({
    playerHealth: character?.health || 0,
    enemyHealth: 100,
    turn: 'player'
  });

  const handleAction = async (action: string) => {
    // Implement combat logic
    // This could involve contract calls for randomness
  };

  return (
    <div className="combat-scene">
      {/* Combat UI and controls */}
    </div>
  );
}
```

## Testing

```typescript
import { render, screen } from '@testing-library/react';
import { describe, it, expect } from 'vitest';

describe('Game Component', () => {
  it('should initialize with SDK', async () => {
    render(<Game />);
    expect(await screen.findByText('Connect Wallet')).toBeInTheDocument();
  });

  it('should handle wallet connection', async () => {
    // Test wallet connection flow
  });

  it('should handle game actions', async () => {
    // Test game action flows
  });
});
```

## Deployment Considerations

1. **Environment Setup**
```typescript
// next.config.js
module.exports = {
  env: {
    NEXT_PUBLIC_CHAIN_ID: process.env.NEXT_PUBLIC_CHAIN_ID,
    NEXT_PUBLIC_CONTRACT_ADDRESS: process.env.NEXT_PUBLIC_CONTRACT_ADDRESS,
  }
};
```

2. **Performance Optimization**
- Implement proper loading states
- Use dynamic imports for large components
- Optimize asset loading
- Implement proper caching strategies

3. **Security**
- Validate all user inputs
- Implement proper error boundaries
- Secure contract interactions
- Handle wallet connections safely