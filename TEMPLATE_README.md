# Roblox Tycoon System — Complete Template

## Quick Start (5 Minutes to Your Own Tycoon Game)

### Step 1: Install Tools
```bash
# Install aftman (Roblox toolchain manager)
curl -sL https://github.com/LPGhatguy/aftman/releases/download/v0.3.0/aftman-0.3.0-macos-aarch64.zip -o /tmp/aftman.zip
unzip /tmp/aftman.zip -d /tmp/aftman && /tmp/aftman/aftman self-install

# Install Rojo
aftman install  # reads aftman.toml in this project
```

### Step 2: Customize Your Game
Edit `src/shared/GameConfig.lua`:
- Change `TycoonItems` — your 18 progression items (name, cost, income, description)
- Change `BuildingColors` — 6 colors for building tiers
- Change `BuildingMaterials` — materials per tier (Wood, Brick, Metal, Neon, etc.)
- Change `Codes` — your promo codes
- Change `Achievements` — milestone names and thresholds
- Change `DailyRewards` — 7-day reward amounts

Edit `src/server/PlotManager.server.lua`:
- Search for "BUSINESS TYCOON" — change to your game name
- Search for "Build Your Empire!" — change to your subtitle

### Step 3: Connect to Studio
```bash
rojo serve  # starts sync server
```
- Open Roblox Studio → create new Baseplate
- Install Rojo plugin (Plugin Marketplace → search "Rojo")
- Click Connect → all 22 scripts sync instantly

### Step 4: Create Monetization
In Roblox Creator Dashboard:
1. Create 4 Game Passes: 2x Income, Auto-Buy, VIP, Speed Boost
2. Create 5 Dev Products: Small/Large Cash Pack, Instant Rebirth, 5min Boost, Starter Bundle
3. Copy asset IDs into `src/shared/GamePassConfig.lua`
4. Set prices and toggle "On Sale"

### Step 5: Publish
- Studio → File → Publish to Roblox
- Complete Maturity Questionnaire (all "No" for tycoon games)
- Set game to Public
- Done!

---

## What's Included (22 Lua Scripts)

### Server Scripts (10)
| Script | Purpose |
|--------|---------|
| TycoonManager | Core game loop, income, purchases, auto-buy |
| DataManager | Player persistence with DataStoreService |
| PlotManager | Full 3D world generation (lobby, plots, buildings) |
| MonetizationManager | Game passes + dev products |
| RebirthManager | Prestige system with multipliers |
| QuestManager | 3 daily quests with progress tracking |
| AchievementManager | 7 milestone achievements |
| DailyRewardManager | 7-day login streak rewards |
| CodeManager | Promo code redemption system |
| LeaderboardManager | Built-in leaderboard |

### Client Scripts (8)
| Script | Purpose |
|--------|---------|
| TycoonUI | Main HUD (cash, income, progress bar, items counter) |
| ShopUI | Game pass + dev product shop |
| QuestUI | Daily quest panel |
| DailyRewardUI | 7-day reward popup |
| CodeUI | Promo code input |
| TutorialManager | 5-step new player onboarding |
| SoundManager | Audio feedback for all actions |
| EffectsManager | Particles, floating text, achievement banners |

### Shared Modules (3)
| Module | Purpose |
|--------|---------|
| GameConfig | All game balance, items, achievements, quests |
| GamePassConfig | Monetization IDs and pricing |
| Utils | Number formatting, math helpers |

---

## Features

- **18 progression items** across 6 tiers (including 3 VIP-exclusive)
- **Auto-buy game pass** — purchases items automatically
- **Multi-part buildings** with tier-based materials and glow effects
- **Full atmosphere** — skybox, lighting, trees, lamps, fountain/centerpiece
- **Sound effects** on every interaction
- **5-step tutorial** for new players (auto-detects first visit)
- **3 daily quests** with progress bars and rewards
- **7 achievements** with gold banner notifications
- **7-day daily login rewards** with streak system
- **Promo code system** with duplicate prevention
- **Leaderboard** showing cash and rebirths
- **Progress bar** with time-to-afford estimate
- **Server-authoritative** architecture (anti-exploit)
- **Rate limiting** on purchases, rebirths, and codes
- **Data persistence** with auto-save every 60 seconds
- **Staggered notifications** — clean first-load experience
- **Rojo project** for professional file-based workflow

---

## Customization Examples

### Changing Theme (5 Minutes)
Replace items in GameConfig.lua:
```lua
-- Space Theme:
{name = "Antenna Array", cost = 0, income = 5, description = "Signal receiver"},

-- Restaurant Theme:
{name = "Hot Dog Stand", cost = 0, income = 5, description = "First food venture"},

-- Pet Theme:
{name = "Dog House", cost = 0, income = 5, description = "Your first pet home"},
```

### Adding More Items
Just add entries to the TycoonItems table. The system automatically:
- Creates purchase pads for new items
- Calculates grid positions (up to 18 items in 3x6 grid)
- Assigns tier colors and materials

### Changing Economy
Adjust costs and income values in GameConfig.lua. The system auto-balances:
- Progress bar calculates time estimates
- Quests scale with rebirth count
- Achievement thresholds are configurable

---

## Support

- Discord: [Your Discord]
- DevForum: [Your DevForum Profile]
- Issues: Open a GitHub issue

## License

This template is for personal and commercial use. You may:
- Use it in unlimited Roblox games
- Modify the code however you want
- Keep 100% of revenue from games you build

You may NOT:
- Resell the template itself
- Share the template files with others
- Claim you created the template system
