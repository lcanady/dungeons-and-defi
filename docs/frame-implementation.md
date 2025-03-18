# Dungeons and DeFi - Farcaster Frame v2 Implementation

## Project Setup

```bash
# Create Next.js app
yarn create next-app dungeons-and-defi
cd dungeons-and-defi

# Install Frame SDK
yarn add @farcaster/frame-sdk
```

## Basic Frame Structure

```typescript
// app/page.tsx
export default function Home() {
  return (
    <>
      <head>
        <title>Dungeons and DeFi</title>
        <meta property="fc:frame" content="vNext" />
        <meta property="fc:frame:image" content="https://your-domain.com/api/frame/image" />
        <meta property="fc:frame:button:1" content="Start Game" />
        <meta property="fc:frame:button:2" content="How to Play" />
        <meta property="fc:frame:button:3" content="Leaderboard" />
        <meta property="fc:frame:button:4" content="About" />
        <meta property="fc:frame:post_url" content="https://your-domain.com/api/frame" />
      </head>
    </>
  );
}
```

## Frame API Route

```typescript
// app/api/frame/route.ts
import { NextRequest } from 'next/server';
import { getFrameMessage } from '@farcaster/frame-sdk';

export async function POST(req: NextRequest) {
  try {
    // Validate frame message
    const frameMessage = await getFrameMessage(req);
    if (!frameMessage) {
      return new Response('Invalid frame message', { status: 400 });
    }

    // Get game state
    const state = await getGameState(frameMessage.interactor.fid);

    // Process the button click
    const { newState, imageUrl } = await processGameAction({
      action: frameMessage.button,
      state,
      fid: frameMessage.interactor.fid
    });

    // Return new frame
    return new Response(
      `<!DOCTYPE html>
      <html>
        <head>
          <title>Dungeons and DeFi</title>
          <meta property="fc:frame" content="vNext" />
          <meta property="fc:frame:image" content="${imageUrl}" />
          ${newState.buttons.map((button, i) => 
            `<meta property="fc:frame:button:${i + 1}" content="${button}" />`
          ).join('')}
          <meta property="fc:frame:post_url" content="https://your-domain.com/api/frame" />
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
    return new Response('Error processing frame action', { status: 500 });
  }
}
```

## Game State Management

```typescript
// lib/gameState.ts
interface GameState {
  scene: 'MAIN_MENU' | 'CHARACTER_CREATION' | 'QUEST_BOARD' | 'COMBAT';
  character?: {
    id: string;
    class: string;
    level: number;
  };
  currentQuest?: {
    id: string;
    progress: number;
  };
  buttons: string[];
}

async function getGameState(fid: string): Promise<GameState> {
  // Get state from your database
  const state = await db.get(`game:${fid}`);
  return state || {
    scene: 'MAIN_MENU',
    buttons: ['Start Game', 'How to Play', 'Leaderboard', 'About']
  };
}

async function saveGameState(fid: string, state: GameState) {
  await db.set(`game:${fid}`, state);
}
```

## Game Actions

```typescript
// lib/actions.ts
async function processGameAction({
  action,
  state,
  fid
}: {
  action: string;
  state: GameState;
  fid: string;
}) {
  switch (action) {
    case 'Start Game':
      return handleStartGame(state);
    
    case 'Create Character':
      return handleCharacterCreation(state, fid);
    
    case 'View Quests':
      return handleQuestBoard(state);
    
    case 'Start Combat':
      return handleCombat(state);
    
    default:
      return handleMainMenu();
  }
}

async function handleStartGame(state: GameState) {
  const imageUrl = await generateImage({
    scene: 'CHARACTER_CREATION',
    text: 'Choose Your Class'
  });

  return {
    newState: {
      scene: 'CHARACTER_CREATION',
      buttons: [
        'Choose Warrior',
        'Choose Mage',
        'Choose Rogue',
        'Back'
      ]
    },
    imageUrl
  };
}

async function handleCharacterCreation(state: GameState, fid: string) {
  // Create character NFT or DB entry
  const imageUrl = await generateImage({
    scene: 'CHARACTER_CREATED',
    character: { /* character data */ }
  });

  return {
    newState: {
      scene: 'MAIN_MENU',
      character: { /* character data */ },
      buttons: [
        'View Quests',
        'View Character',
        'Inventory',
        'Menu'
      ]
    },
    imageUrl
  };
}
```

## Image Generation

```typescript
// lib/images.ts
import { createCanvas, loadImage } from 'canvas';

async function generateImage({
  scene,
  text,
  character,
  quest
}: {
  scene: string;
  text?: string;
  character?: any;
  quest?: any;
}) {
  // Create a 1200x630 canvas (recommended Frame dimensions)
  const canvas = createCanvas(1200, 630);
  const ctx = canvas.getContext('2d');

  // Draw background
  const bg = await loadImage(`/backgrounds/${scene}.png`);
  ctx.drawImage(bg, 0, 0, 1200, 630);

  // Add text
  if (text) {
    ctx.font = 'bold 48px Arial';
    ctx.fillStyle = 'white';
    ctx.textAlign = 'center';
    ctx.fillText(text, 600, 100);
  }

  // Add scene-specific elements
  switch (scene) {
    case 'CHARACTER_CREATION':
      await drawCharacterClasses(ctx);
      break;
    case 'QUEST_BOARD':
      await drawQuests(ctx, quest);
      break;
    case 'COMBAT':
      await drawCombatScene(ctx, character);
      break;
  }

  // Return image URL or buffer
  return canvas.toBuffer('image/png');
}
```

## Scene Flow Examples

### 1. Main Menu
```typescript
// Initial frame
{
  image: '/images/main-menu.png',
  buttons: [
    'Start Game',
    'How to Play',
    'Leaderboard',
    'About'
  ]
}
```

### 2. Character Creation
```typescript
// Character creation frame
{
  image: '/images/character-creation.png',
  buttons: [
    'Choose Warrior',
    'Choose Mage',
    'Choose Rogue',
    'Back'
  ]
}
```

### 3. Quest Board
```typescript
// Quest board frame
{
  image: '/images/quest-board.png',
  buttons: [
    'Accept Quest',
    'Next Quest',
    'View Details',
    'Back'
  ]
}
```

### 4. Combat
```typescript
// Combat frame
{
  image: '/images/combat.png',
  buttons: [
    'Attack',
    'Use Item',
    'Flee',
    'Status'
  ]
}
```

## Error Handling

```typescript
// lib/errors.ts
async function handleFrameError(error: Error) {
  const errorImage = await generateImage({
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
    imageUrl: errorImage
  };
}
```

## Best Practices

1. **Image Generation**
   - Always use 1200x630 dimensions
   - Keep file sizes small
   - Pre-generate common images
   - Cache generated images

2. **State Management**
   - Keep state minimal
   - Store state in a database
   - Use player FID as key
   - Handle state transitions cleanly

3. **Button Actions**
   - Maximum 4 buttons per frame
   - Clear, concise button text
   - Consistent navigation patterns
   - Handle all button states

4. **Performance**
   - Cache frame responses
   - Optimize image generation
   - Handle errors gracefully
   - Implement timeouts

5. **User Experience**
   - Clear feedback
   - Consistent navigation
   - Error recovery
   - Progress persistence

This implementation provides a focused approach to building the game as a Farcaster Frame v2 application, handling:
- Frame setup and routing
- State management
- Image generation
- User interactions
- Error handling

Would you like me to expand on any particular aspect?