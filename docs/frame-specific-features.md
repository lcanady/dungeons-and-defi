# Dungeons and DeFi - Frame-Specific Features

## Frame Context Integration

```typescript
// hooks/useFrameContext.ts
import { useEffect, useState } from 'react';
import sdk, { type FrameContext } from '@farcaster/frame-sdk';

export function useFrameContext() {
  const [context, setContext] = useState<FrameContext>();
  const [isReady, setIsReady] = useState(false);

  useEffect(() => {
    const initializeFrame = async () => {
      try {
        const ctx = await sdk.context;
        setContext(ctx);
        sdk.actions.ready();
        setIsReady(true);
      } catch (error) {
        console.error('Failed to initialize frame:', error);
      }
    };

    initializeFrame();
  }, []);

  return { context, isReady };
}
```

## Frame-Optimized Components

### 1. Frame Layout
```typescript
// components/layout/FrameLayout.tsx
export function FrameLayout({ children }: { children: React.ReactNode }) {
  const { isReady } = useFrameContext();

  if (!isReady) {
    return <LoadingState message="Initializing game..." />;
  }

  return (
    <div className="frame-layout">
      {/* Frame dimensions: 1200x630 */}
      <div className="frame-content">
        {children}
      </div>
      <FrameNavigation />
    </div>
  );
}
```

### 2. Frame Navigation
```typescript
// components/navigation/FrameNavigation.tsx
export function FrameNavigation() {
  const { setScene } = useGameStore();
  const { character } = useCharacter();

  // Maximum 4 buttons per frame
  return (
    <div className="frame-navigation">
      {character ? (
        <>
          <GameButton onClick={() => setScene('QUEST_BOARD')}>
            Quests
          </GameButton>
          <GameButton onClick={() => setScene('CHARACTER')}>
            Character
          </GameButton>
          <GameButton onClick={() => setScene('INVENTORY')}>
            Inventory
          </GameButton>
          <GameButton onClick={() => sdk.actions.close()}>
            Exit
          </GameButton>
        </>
      ) : (
        <>
          <GameButton onClick={() => setScene('CHARACTER_CREATION')}>
            New Game
          </GameButton>
          <GameButton onClick={() => sdk.actions.close()}>
            Exit
          </GameButton>
        </>
      )}
    </div>
  );
}
```

## Frame-Specific Actions

```typescript
// lib/frameActions.ts
export const frameActions = {
  // Open external URL (e.g., for NFT minting)
  openMint: () => {
    sdk.actions.openUrl('https://your-mint-url.com');
  },

  // Close the frame
  closeGame: () => {
    sdk.actions.close();
  },

  // Handle wallet connection
  connectWallet: async () => {
    try {
      const { connect } = useConnect();
      await connect({ connector: config.connectors[0] });
    } catch (error) {
      console.error('Wallet connection failed:', error);
    }
  }
};
```

## Frame-Optimized Game Scenes

### 1. Character Creation Frame
```typescript
// components/frames/CharacterCreationFrame.tsx
export function CharacterCreationFrame() {
  const [step, setStep] = useState(0);
  const steps = ['class', 'appearance', 'name', 'confirm'];

  // Only show relevant buttons for current step
  const getButtons = () => {
    switch (step) {
      case 0:
        return [
          { text: 'Warrior', action: () => selectClass('warrior') },
          { text: 'Mage', action: () => selectClass('mage') },
          { text: 'Rogue', action: () => selectClass('rogue') },
          { text: 'Next', action: () => setStep(1) }
        ];
      // ... other steps
    }
  };

  return (
    <FrameLayout>
      <div className="character-creation-frame">
        {/* Frame content */}
        <FrameNavigation buttons={getButtons()} />
      </div>
    </FrameLayout>
  );
}
```

### 2. Quest Board Frame
```typescript
// components/frames/QuestBoardFrame.tsx
export function QuestBoardFrame() {
  const [selectedQuest, setSelectedQuest] = useState<Quest | null>(null);
  const { quests } = useQuests();

  const getButtons = () => {
    if (selectedQuest) {
      return [
        { text: 'Accept', action: () => acceptQuest(selectedQuest.id) },
        { text: 'Details', action: () => viewQuestDetails(selectedQuest.id) },
        { text: 'Back', action: () => setSelectedQuest(null) }
      ];
    }

    return [
      { text: 'Next', action: () => cycleQuests('next') },
      { text: 'Previous', action: () => cycleQuests('prev') },
      { text: 'Select', action: () => setSelectedQuest(currentQuest) },
      { text: 'Menu', action: () => setScene('MAIN_MENU') }
    ];
  };

  return (
    <FrameLayout>
      <div className="quest-board-frame">
        {/* Quest display */}
        <FrameNavigation buttons={getButtons()} />
      </div>
    </FrameLayout>
  );
}
```

## Frame-Optimized State Management

```typescript
// store/frameStore.ts
interface FrameState extends GameState {
  currentFrame: string;
  frameHistory: string[];
  buttonActions: {
    [key: string]: () => void;
  };
}

export const useFrameStore = create<FrameState>()(
  persist(
    (set) => ({
      // ... game state
      currentFrame: 'MAIN_MENU',
      frameHistory: [],
      buttonActions: {},

      setFrame: (frame: string) => 
        set((state) => ({
          currentFrame: frame,
          frameHistory: [...state.frameHistory, state.currentFrame]
        })),

      goBack: () =>
        set((state) => ({
          currentFrame: state.frameHistory.pop() || 'MAIN_MENU',
          frameHistory: state.frameHistory.slice(0, -1)
        })),

      setButtonActions: (actions: Record<string, () => void>) =>
        set({ buttonActions: actions })
    }),
    {
      name: 'dungeons-and-defi-frame-storage'
    }
  )
);
```

## Frame-Specific Utilities

### 1. Image Generation
```typescript
// utils/frameImage.ts
interface FrameImageOptions {
  scene: string;
  character?: Character;
  quest?: Quest;
  combat?: CombatState;
}

export async function generateFrameImage(options: FrameImageOptions) {
  // Generate a 1200x630 image for the current frame
  const canvas = createCanvas(1200, 630);
  const ctx = canvas.getContext('2d');

  // Draw background
  await drawBackground(ctx, options.scene);

  // Draw scene-specific elements
  switch (options.scene) {
    case 'CHARACTER':
      await drawCharacter(ctx, options.character);
      break;
    case 'QUEST':
      await drawQuest(ctx, options.quest);
      break;
    case 'COMBAT':
      await drawCombat(ctx, options.combat);
      break;
  }

  // Add UI elements
  await drawUI(ctx, options);

  return canvas.toBuffer('image/png');
}
```

### 2. Frame Navigation History
```typescript
// utils/frameNavigation.ts
export class FrameNavigator {
  private history: string[] = [];
  private maxHistory = 10;

  push(frame: string) {
    this.history.push(frame);
    if (this.history.length > this.maxHistory) {
      this.history.shift();
    }
  }

  pop(): string | undefined {
    return this.history.pop();
  }

  clear() {
    this.history = [];
  }
}
```

## Frame Performance Optimizations

```typescript
// utils/frameOptimizations.ts
export const frameOptimizations = {
  // Pre-generate common images
  preloadImages: async () => {
    const commonImages = [
      'background',
      'character-base',
      'ui-elements',
      // ... other common images
    ];

    await Promise.all(
      commonImages.map(img => loadImage(`/assets/${img}.png`))
    );
  },

  // Cache frame states
  cacheFrame: (frameId: string, state: any) => {
    sessionStorage.setItem(`frame_${frameId}`, JSON.stringify(state));
  },

  // Optimize frame transitions
  optimizeTransition: async (fromFrame: string, toFrame: string) => {
    // Pre-load next frame assets
    // Clean up previous frame
    // Handle state preservation
  }
};
```

## Frame Security

```typescript
// utils/frameSecurity.ts
export const frameSecurity = {
  // Validate frame context
  validateContext: (context: FrameContext) => {
    // Verify frame origin
    // Check user permissions
    // Validate signature
  },

  // Secure state management
  secureState: (state: any) => {
    // Encrypt sensitive data
    // Validate state changes
    // Prevent tampering
  },

  // Transaction safety
  validateTransaction: (tx: any) => {
    // Verify transaction parameters
    // Check gas limits
    // Validate contract interactions
  }
};
```

This implementation focuses on Frame-specific features and optimizations, ensuring the game works well within Farcaster's Frame constraints while maintaining a good user experience. Would you like me to expand on any particular aspect?