# Dungeons and DeFi - Frame API Routes

## Frame Route Handler

```typescript
// app/api/frame/route.ts
import { NextRequest } from 'next/server';
import { getFrameMessage } from '@farcaster/frame-sdk';
import { generateFrameImage } from '~/utils/frameImage';
import { handleGameAction } from '~/game/actions';

export async function POST(req: NextRequest) {
  try {
    // Validate frame message
    const frameMessage = await getFrameMessage(req);
    if (!frameMessage) {
      return new Response('Invalid frame message', { status: 400 });
    }

    // Get game state for the user
    const gameState = await getGameState(frameMessage.interactor.fid);

    // Handle the action
    const { newState, image } = await handleGameAction({
      action: frameMessage.button,
      state: gameState,
      context: frameMessage
    });

    // Generate the next frame
    return new Response(
      `<!DOCTYPE html>
      <html>
        <head>
          <title>Dungeons and DeFi</title>
          <meta property="fc:frame" content="vNext" />
          <meta property="fc:frame:image" content="${image}" />
          <meta property="fc:frame:button:1" content="${newState.buttons[0]}" />
          <meta property="fc:frame:button:2" content="${newState.buttons[1]}" />
          <meta property="fc:frame:button:3" content="${newState.buttons[2]}" />
          <meta property="fc:frame:button:4" content="${newState.buttons[3]}" />
          ${newState.postUrl ? `<meta property="fc:frame:post_url" content="${newState.postUrl}" />` : ''}
        </head>
      </html>`,
      {
        headers: {
          'Content-Type': 'text/html',
        },
      }
    );
  } catch (error) {
    console.error('Frame error:', error);
    return new Response('Internal server error', { status: 500 });
  }
}
```

## Game Action Handler

```typescript
// game/actions.ts
import { FrameMessage } from '@farcaster/frame-sdk';
import { GameState, GameAction } from '~/types';

export async function handleGameAction({
  action,
  state,
  context
}: {
  action: string;
  state: GameState;
  context: FrameMessage;
}) {
  // Handle different game actions
  switch (action) {
    case 'START_GAME':
      return handleStartGame(state, context);
    
    case 'CREATE_CHARACTER':
      return handleCharacterCreation(state, context);
    
    case 'START_QUEST':
      return handleStartQuest(state, context);
    
    case 'COMBAT_ACTION':
      return handleCombatAction(state, context);
    
    default:
      return handleDefaultState(state);
  }
}

// Action handlers
async function handleStartGame(state: GameState, context: FrameMessage) {
  const image = await generateFrameImage({
    scene: 'CHARACTER_CREATION',
    text: 'Welcome to Dungeons and DeFi!'
  });

  return {
    newState: {
      ...state,
      scene: 'CHARACTER_CREATION',
      buttons: [
        'Choose Warrior',
        'Choose Mage',
        'Choose Rogue',
        'Back'
      ]
    },
    image
  };
}

async function handleCharacterCreation(state: GameState, context: FrameMessage) {
  // Handle character creation logic
  const characterClass = context.button.toLowerCase();
  
  // Create character NFT
  const characterNFT = await mintCharacterNFT(context.interactor.fid, characterClass);
  
  const image = await generateFrameImage({
    scene: 'CHARACTER_CREATED',
    character: characterNFT
  });

  return {
    newState: {
      ...state,
      character: characterNFT,
      scene: 'MAIN_MENU',
      buttons: [
        'View Quests',
        'View Character',
        'View Inventory',
        'Exit'
      ]
    },
    image
  };
}

async function handleStartQuest(state: GameState, context: FrameMessage) {
  // Get available quests
  const quests = await getAvailableQuests(state.character);
  
  const image = await generateFrameImage({
    scene: 'QUEST_BOARD',
    quests: quests.slice(0, 3) // Show first 3 quests
  });

  return {
    newState: {
      ...state,
      scene: 'QUEST_BOARD',
      availableQuests: quests,
      buttons: [
        'Accept Quest',
        'Next Quest',
        'View Details',
        'Back'
      ]
    },
    image
  };
}

async function handleCombatAction(state: GameState, context: FrameMessage) {
  // Process combat action
  const combatResult = await processCombatAction(state.combat, context.button);
  
  const image = await generateFrameImage({
    scene: 'COMBAT',
    combat: combatResult
  });

  return {
    newState: {
      ...state,
      combat: combatResult,
      buttons: [
        'Attack',
        'Use Item',
        'Flee',
        'Status'
      ]
    },
    image
  };
}
```

## Frame Image Generation

```typescript
// utils/frameImage.ts
import { createCanvas, loadImage } from 'canvas';
import { GameScene, Character, Combat } from '~/types';

export async function generateFrameImage({
  scene,
  text,
  character,
  quests,
  combat
}: {
  scene: GameScene;
  text?: string;
  character?: Character;
  quests?: Quest[];
  combat?: Combat;
}) {
  const canvas = createCanvas(1200, 630);
  const ctx = canvas.getContext('2d');

  // Load and draw background
  const background = await loadImage(`/assets/backgrounds/${scene}.png`);
  ctx.drawImage(background, 0, 0, 1200, 630);

  // Draw scene-specific elements
  switch (scene) {
    case 'CHARACTER_CREATION':
      await drawCharacterCreation(ctx, text);
      break;
    
    case 'QUEST_BOARD':
      await drawQuestBoard(ctx, quests);
      break;
    
    case 'COMBAT':
      await drawCombatScene(ctx, combat);
      break;
    
    // ... other scenes
  }

  // Return image URL or buffer
  return canvas.toBuffer('image/png');
}

// Helper drawing functions
async function drawCharacterCreation(ctx: CanvasRenderingContext2D, text?: string) {
  // Draw character creation UI
  ctx.font = 'bold 48px Arial';
  ctx.fillStyle = 'white';
  ctx.textAlign = 'center';
  
  if (text) {
    ctx.fillText(text, 600, 100);
  }

  // Draw character class previews
  // ... drawing code
}

async function drawQuestBoard(ctx: CanvasRenderingContext2D, quests?: Quest[]) {
  // Draw quest board background
  ctx.fillStyle = '#2c3e50';
  ctx.fillRect(100, 100, 1000, 430);

  if (quests) {
    // Draw quest cards
    quests.forEach((quest, index) => {
      drawQuestCard(ctx, quest, 150 + index * 350, 150);
    });
  }
}

async function drawCombatScene(ctx: CanvasRenderingContext2D, combat?: Combat) {
  if (!combat) return;

  // Draw combatants
  await drawCombatant(ctx, combat.player, 200, 315, 'right');
  await drawCombatant(ctx, combat.enemy, 1000, 315, 'left');

  // Draw health bars
  drawHealthBar(ctx, combat.player.health, 100, 50);
  drawHealthBar(ctx, combat.enemy.health, 700, 50);

  // Draw combat effects
  if (combat.lastAction) {
    drawCombatEffect(ctx, combat.lastAction);
  }
}
```

## State Management

```typescript
// utils/gameState.ts
import { redis } from '~/lib/redis';

export async function getGameState(fid: string): Promise<GameState> {
  const state = await redis.get(`game:${fid}`);
  return state ? JSON.parse(state) : createInitialState();
}

export async function saveGameState(fid: string, state: GameState) {
  await redis.set(`game:${fid}`, JSON.stringify(state));
}

function createInitialState(): GameState {
  return {
    scene: 'MAIN_MENU',
    character: null,
    inventory: [],
    quests: [],
    combat: null,
    buttons: [
      'Start Game',
      'How to Play',
      'Leaderboard',
      'Exit'
    ]
  };
}
```

## Error Handling

```typescript
// utils/errorHandling.ts
export async function handleFrameError(error: Error) {
  // Generate error frame
  const errorImage = await generateFrameImage({
    scene: 'ERROR',
    text: 'Something went wrong!'
  });

  return {
    newState: {
      scene: 'ERROR',
      buttons: [
        'Retry',
        'Main Menu',
        'Report Bug',
        'Exit'
      ]
    },
    image: errorImage
  };
}
```

This implementation provides:
1. Frame route handling
2. Game action processing
3. Dynamic image generation
4. State management
5. Error handling

The system is designed to:
- Handle frame interactions
- Maintain game state
- Generate appropriate responses
- Handle errors gracefully
- Provide a smooth game experience within Farcaster Frames

Would you like me to expand on any particular aspect or add more features?