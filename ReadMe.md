# The Gridiron Bazaar
### An American Football Auto-Battler

A strategic auto-battler game where players build football teams through coach selection and card-based gameplay. Teams automatically execute plays using authentic football mechanics including downs, field position, and tactical card interactions.

---

## Table of Contents
- [Overview](#overview)
- [Current Features](#current-features)
- [Gameplay Mechanics](#gameplay-mechanics)
- [Development Status](#development-status)
- [Installation](#installation)
- [Controls](#controls)
- [Planned Features](#planned-features)
- [Suggestions for Enhanced Football Realism](#suggestions-for-enhanced-football-realism)

---

## Overview

The Gridiron Bazaar transforms American football into a strategic auto-battler experience. Players select a coaching archetype, each with unique abilities and 11-man rosters (QB, RB, WR, OL, TE on offense / DL, LB, CB, S on defense). Cards execute automatically based on cooldown timers, with the goal of advancing 80 yards for a touchdown while preventing the opponent from doing the same.

### Design Philosophy
- **Authentic Football Mechanics**: Down system, field position, formations
- **Strategic Depth**: Coach abilities, card synergies, offensive/defensive balance
- **Auto-Battler Simplicity**: Automated card actions, focus on team composition
- **Readable Pace**: Slow enough to understand actions, fast enough to stay engaging

---

## Current Features

### ✅ Implemented

#### Core Systems
- **Coach Selection**: 4 unique coaching archetypes with distinct playstyles
  - Offensive Guru (passing-focused, +10% all yard generators)
  - Defensive Mastermind (elite defense, 5% chance +2 extra yard removal)
  - Special Teams Specialist (field position advantage, 68 yards to TD vs 80)
  - Ground Game Coach (run-heavy offense, RB +2 extra yards)

#### Season Mode (Fully Implemented)
- **18-Team League**: Two 9-team conferences (Conference A & B)
- **17-Week Regular Season**: Full schedule with conference and cross-conference games
- **Playoff System**: Top 6 teams per conference advance to playoffs
  - Wildcard Round, Divisional Round, Conference Championships, Super Bowl
- **Team Naming**: Customize your team name at season start
- **Season Phases**: Training → Preparation → Match → Repeat
- **Save/Load System**: Save your season progress and resume later

#### Training & Progression
- **Card Training System**: Upgrade your players between weeks
  - Yards Upgrades: Increase yard generation (+0.5 per upgrade)
  - Cooldown Upgrades: Reduce action cooldown (-10% per upgrade)
  - Boost Upgrades: Increase booster percentage (+5% per upgrade)
  - Duration Upgrades: Extend defensive effect duration (+0.5s per upgrade)
  - Kicker Range/Accuracy Upgrades: Improve field goal success
  - Punter Range Upgrades: Increase punt distance
  - Max 3 upgrades per card type
- **Training Budget**: Earn cash from wins/losses, spend on upgrades
  - Winners: 150 cash (player), 100 cash (AI)
  - Losers: 100 cash (player), 50 cash (AI)
- **AI Team Training**: Computer teams also train between weeks

#### Match System
- **Yards-Based Progression**: Advance 80 yards (68 for Special Teams) to score
- **Down System**: 2-second downs, 4 downs to gain 10 yards for first down
- **Field Position**: Turnovers inherit current field position
- **60-Second Regulation**: Timed matches with overtime support
- **Overtime**: 15-second periods if tied (First, Second, Third Overtime, etc.)
- **Special Teams Integration**:
  - Field Goals: Range-based accuracy (distance/max range)
  - Punts: Random distance within kicker's range (35-50 yards)
  - Automatic punt on 4th down at midfield or beyond

#### Card System
- **11-Man Rosters**: Authentic football positions per team (plus kicker/punter)
- **Card Types**:
  - Yard Generators (QB, RB, WR) - generate yards per action (2.5-6.5 yards)
  - Boosters (OL, TE) - enhance yard generation with % boosts (15-30%)
  - Defenders (DL, LB, CB, S) - apply status effects (slow, freeze, yard removal)
  - Kicker - attempt field goals (range and accuracy stats)
  - Punter - punt the ball for field position (min/max range stats)
- **Statistics Tracking**: Individual card stats throughout match and season
  - Offensive: Yards gained, touchdowns scored, times boosted others
  - Defensive: Times slowed, times froze, yards removed
- **Card Upgrade System**: Cards can be upgraded up to 3 times (tracked visually with +1, +2, +3)

#### Season Management Screens
- **Season Menu Hub**: Central menu for all season activities
  - Continue to next match
  - Training (upgrade cards)
  - Lineup (view/manage roster)
  - Schedule (view all 17 weeks + playoffs)
  - Standings (conference standings with W-L-PF-PA)
  - Stats (player statistics leaderboards)
  - Scouting (view opponent's roster and coach)
  - Options (game settings)
  - Save Season
  - Quit to Main Menu
- **Lineup Screen**: View offensive and defensive rosters with card details
- **Schedule Screen**: View all matches for all 18 teams, simulate weeks
- **Standings Screen**: Conference standings with tiebreaker logic
- **Stats Screen**: Leaderboards for yards, touchdowns, defensive stats
- **Scouting Screen**: View upcoming opponent's coach and full roster
- **Season End Screen**: Championship results and season summary

#### UI/UX
- **Main Menu**: Start New Season / Continue Season / Options / Exit
- **Coach Selection Screen**: Visual cards with coach abilities and formations
- **Team Naming Screen**: Enter custom team name for season
- **Match Display**: Real-time game state, down counter, field position, timer
- **Winner Popup**: Final score, Offensive MVP, Defensive MVP stats
- **Pause System**: In-game pause with resume/options/quit
- **Overtime Indicator**: Yellow highlight during overtime periods
- **Tooltips**: Hover over cards to see detailed stats and upgrade info
- **Event Popups**: Touchdown announcements, turnover alerts
- **Options Menu**: Graphics, audio, and gameplay settings
- **UI Scaling System**: Adaptive scaling for different resolutions

#### Visual System
- **Formation-Based Positioning**: Cards arranged in authentic football formations
- **Status Effects**: Visual indicators for slowed/frozen cards
- **Progress Bars**: Show card cooldown progress
- **Card Animations**: Bounce effect when cards activate
- **1600x900 Resolution**: Optimized for readability (fixed, non-resizable)

---

## Gameplay Mechanics

### Down System
- Each down lasts **2 seconds** (auto-advances)
- Offense needs **10 yards in 4 downs** for first down
- Failure to gain 10 yards = **turnover** (defense inherits field position)
- Gaining 10+ yards = **first down** (down counter resets to 1st)
- **4th Down Logic**: Automatic punt if at or past midfield, otherwise attempt to gain yards

### Card Actions
- Cards act automatically based on **cooldown timers** (typically 1.5-3 seconds, varies by card)
- **Yard Generators**: Generate variable yards per action (2.5-6.5 range depending on position)
  - QB: Higher yards, slower cooldown
  - RB: Medium yards, fast cooldown
  - WR: High variability in yard ranges
  - Uses min/max ranges for randomization
- **Boosters**: Apply percentage boosts to targeted positions (15-30%)
  - Example: OL boosts QB by 20%, so 4-yard play becomes 4.8 yards
  - Boosts stack additively (multiple OL can boost the same QB)
  - TE can be both yard generator and booster depending on coach
- **Defenders**: Apply one of three status effects:
  - **Slow**: Reduces target card's progress rate to 50% (duration varies)
  - **Freeze**: Completely stops target card progress (duration varies)
  - **Remove Yards**: Subtracts 2-4 yards from offense's total
- **Special Teams**:
  - **Kicker**: Field goal attempts with range-based accuracy (max 50 yards)
  - **Punter**: Punts 35-50 yards for field position battles

### Scoring
- Reach **yardsNeeded** (80 or 68 for Special Teams) = **Touchdown** (7 points)
- Phase switches after TD or turnover
- Match ends when timer reaches 0:00
- Tied games go to **overtime** (15-second periods)
- **Field Goals**: 3 points if successful (automatic safety mechanism after 10+ OT periods)

### Coach Abilities
- **Offensive Guru**: All yard generators gain +10% yards
- **Defensive Mastermind**: 5% chance to remove 2 extra yards on defensive plays
- **Special Teams**: Start at 32-yard line instead of 20 (need 68 yards vs 80)
- **Ground Game**: Running backs (RB) gain +2 extra yards per action

### Card Upgrade Effects
- **Yards Upgrade**: +0.5 yards per action (for yard generators)
- **Cooldown Upgrade**: -10% cooldown time (faster actions)
- **Boost Upgrade**: +5% boost amount (for boosters)
- **Duration Upgrade**: +0.5 seconds effect duration (for defenders)
- **Kicker Range**: +2 yards max field goal distance
- **Kicker Accuracy**: +5% accuracy at max range
- **Punter Range**: +2 yards max punt distance
- **Max 3 upgrades per card** (shown as +1, +2, +3 badges)

---

## Development Status

### Current Version: Beta v0.7
- **Phase**: Feature-complete season mode with full progression systems
- **Playable**: Yes - complete season experience from team creation through Super Bowl
- **Balance**: Ongoing tuning, AI competitive, upgrade economy functional
- **Stability**: Recently optimized with critical bug fixes and performance improvements
- **Next Focus**: Advanced features, Dynasty mode, additional game modes

### Recent Updates (Latest First)

#### Performance & Stability (Current)
- **Phase 3 Optimizations**: Card filtering cache, team lookup indexing, inline math optimizations
- **Phase 2 Fixes**: Playoff bounds checking, nil team validation, string concatenation optimization (10-100x faster saves), UIScale caching
- **Phase 1 Critical Fixes**: Win/loss tracking, cooldown initialization, upgrade recalculation, division by zero guards
- **Overall Impact**: Eliminated ~200 function calls per frame, O(n²) → O(n) save/load, 18+ bug fixes

#### Recent Feature Additions
- Tooltips for all cards (including kicker/punter special teams)
- Event popup system (touchdowns, turnovers)
- Improved match UI with better visual feedback
- Field position bug fixes and punt distance corrections
- Training screen improvements and option selection fixes
- Season save/load system with validation
- AI training between weeks
- Scouting screen for opponent analysis
- Conference standings with tiebreaker logic
- Stats leaderboards across all teams

---

## Installation

### Requirements
- **LÖVE 11.3** or higher ([Download here](https://love2d.org/))
- Operating System: Windows, macOS, or Linux

### Setup
1. Install LÖVE framework
2. Clone or download this repository
3. Run the game:
   ```bash
   love /path/to/football_autobattler
   ```
   Or drag the folder onto the LÖVE application

---

## Controls

### Menu Navigation
- **Arrow Keys**: Navigate menu options (Up/Down)
- **Enter / Space**: Select option
- **Mouse**: Click buttons or hover for highlight
- **ESC**: Return to previous menu / Quit game (from main menu)

### Coach Selection
- **Arrow Keys**: Navigate coaches (Left/Right)
- **Enter / Space**: Select coach
- **Mouse**: Click coach card or hover for highlight
- **ESC**: Return to main menu

### Team Naming
- **Type**: Enter team name (alphanumeric and spaces)
- **Backspace**: Delete characters
- **Enter**: Confirm team name
- **ESC**: Use default name and continue

### Season Menu
- **Arrow Keys**: Navigate menu options (Up/Down)
- **Enter / Space**: Select option
- **Mouse**: Click buttons or hover for highlight
- **ESC**: Access quit/save menu

### Training Screen
- **Mouse**: Click cards to select, click upgrade buttons to purchase
- **Hover**: See card details and upgrade costs
- **ESC**: Return to season menu

### Lineup/Stats/Schedule/Standings Screens
- **Mouse**: Click to interact with elements, scroll if needed
- **Hover**: View detailed information
- **ESC**: Return to season menu

### Match
- **ESC**: Pause game
- **Mouse**: Hover over cards for tooltips, click "Return to Menu" on winner screen
- **Automatic**: Game plays automatically, no input needed during match

### Pause Menu (In-Match)
- **Arrow Keys**: Navigate options (Up/Down)
- **Enter / Space**: Select option (Resume / Options / Quit)
- **Mouse**: Click buttons or hover for highlight
- **ESC**: Resume game

---

## Planned Features

### Near-Term Improvements (Next Updates)

#### Roster Management Enhancements
- **Active Roster Selection**: Choose which 11 cards start in each game from a larger pool
- **Bench System**: Maintain backup players, make substitutions between games
- **Formation Editor**: Customize offensive and defensive card positioning
- **Injury Reserve**: Handle injured players, promote backups to starting roles

#### Gameplay Refinements
- **Two-Point Conversions**: Risk/reward decision after touchdowns
- **Punt Returns**: Special return mechanics for exciting field position swings
- **Onside Kicks**: Desperation plays to regain possession
- **Home Field Advantage**: Small bonuses for home team (crowd noise, familiarity)
- **Weather Effects**: Rain (reduced passing), snow (reduced speed), wind (affects kicks)
- **Momentum System**: Hot/cold streaks that temporarily boost/reduce performance

#### Enhanced Card Training System
- **Critical Chance Upgrades**: Cards have % chance to perform at 1.5x effectiveness
- **Temporary vs Permanent Boosts**:
  - Week Boosts: Single-game bonuses (cheaper)
  - Season Boosts: Last entire season (moderate cost)
  - Permanent Upgrades: Keep forever across multiple seasons (expensive)
- **Training Card Tiers**: Bronze/Silver/Gold tiers with stacking upgrade system
  - Upgrade same training type to higher tier instead of consuming multiple slots
- **Targeted Training**: Assign specific training cards to specific players
- **Training Specialization**: Position-specific training options (QB accuracy, RB elusiveness, etc.)

### Mid-Term Additions

#### Advanced Coaching System
- **Progressive Coach Leveling**:
  - Start with 1 base ability, unlock additional passive/active skills through experience
  - Gain XP from: Game wins, season completion, coaching challenges, playoff performance
  - Multiple skill trees per coach archetype for customization
- **Coordinator System**:
  - Hire Offensive Coordinator (OC), Defensive Coordinator (DC), Special Teams Coordinator (STC)
  - Each provides passive bonuses to their unit
  - Coordinators have own sub-archetypes and leveling progression
  - Unlock single activatable ability at max level
  - Activatable abilities: Short-duration in-match power boosts (30-second surge)

#### Expanded Economy
- **Salary Cap Management**: Limited budget for roster construction
- **Contract System**: Multi-year player contracts with cap implications
- **Card Acquisition Methods**:
  - **Draft**: Annual draft of rookie cards with varying potential
  - **Free Agency**: Sign available veteran cards from other teams
  - **Trades**: Negotiate card-for-card or card-for-draft-pick trades with AI teams
  - **Pack System**: Random card packs from in-game currency or achievements
- **Advanced Training Economy**: Multiple training resources (drills, film study, strength training)

### Long-Term Vision

#### Dynasty Mode (Multi-Season Career)
- **Multi-Season Persistence**:
  - Build legacy over 10+ seasons
  - Track historical records and achievements
  - Hall of Fame system for legendary players and coaches
- **Player Development Arc**:
  - **Rookies**: Low stats, high potential, low salary
  - **Prime Years**: Peak performance (typically years 3-8)
  - **Veterans**: Slight decline but high experience bonuses
  - **Retirement**: Cards eventually retire, must be replaced
- **Player Aging System**:
  - Cards gain/lose attributes over time based on position and workload
  - Speed declines faster than technique
  - Injury history affects aging curve
- **Offseason Phases**:
  - **Training Camp**: Intensive training for all players
  - **Draft**: Scout and select college prospects
  - **Free Agency**: Bid on available veteran players
  - **Contract Negotiations**: Re-sign expiring contracts
  - **Roster Cuts**: Trim roster to 53-man limit (with practice squad)
- **Dynasty Challenges**:
  - Salary cap crisis management
  - Rebuild aging roster
  - Maintain playoff contention while developing youth
  - Create sustained championship dynasty (3+ titles in 5 years)

#### Additional Game Modes
- **Quick Match**: Single game with any team vs any team
- **Tournament Mode**: 8-team or 16-team single-elimination tournament
- **Challenge Mode**: Specific scenarios (comeback from 21-0, defend with backup defense, etc.)
- **Franchise Builder**: Start with expansion team, build from scratch
- **Historical Seasons**: Replay classic seasons with legendary rosters

#### Advanced Statistics & Analysis
- **Advanced Metrics Dashboard**:
  - Offensive/Defensive Efficiency ratings
  - Third-down conversion rates
  - Red zone success percentage
  - Time of possession analytics
  - Plus/minus ratings for individual cards
- **Replay System**: Review past games, analyze key plays
- **Tendency Reports**: AI learns your playcalling patterns, adjusts accordingly
- **Depth Charts**: Automatically optimize lineup based on matchups

#### Narrative & Immersion
- **Rivalry System**: Division/conference rivals with bonus stakes
- **Playoff Pressure Mechanics**: Increased stakes, tighter gameplay in postseason
- **Award Ceremonies**: MVP, Offensive/Defensive Player of Year, All-Pro teams
- **Media System**: Press conferences, headline news, social media reactions
- **Stadium Atmosphere**: Crowd noise affects gameplay, different stadium types
- **Broadcast Integration**: Simulated commentary and replays for big moments

---

## Suggestions for Enhanced Football Realism

To bring the gameplay more in-line with authentic American football, consider these features:

### 1. Drive Management
- **Clock Management**: Decisions about running out the clock or passing
- **Timeouts**: 3 per half, strategic use to stop clock or ice opponent
- **Two-Minute Drill**: Special mechanics when under 2 minutes

### 2. Situational Football
- **Red Zone Offense/Defense**: Special card abilities when inside 20 yards
- **Third Down Conversions**: Bonus for converting crucial 3rd downs
- **Goal Line Stands**: Increased defensive bonuses when defending near endzone
- **Fourth Down Decisions**: Risk/reward for going for it vs punting

### 3. Special Teams Phase
- **Kickoffs**: Field position battles after scores
- **Punt Game**: Net yards, hang time, returners
- **Field Goals**: Range-based success rates, wind effects
- **Fake Plays**: Trick plays on special teams

### 4. Personnel Packages
- **Offensive Sets**: I-formation, shotgun, wildcat, etc.
- **Defensive Formations**: 3-4, 4-3, nickel, dime packages
- **Matchup Exploits**: Bonus when formation counters opponent's formation

### 5. Pre-Snap Reads
- **Audibles**: Change play at line of scrimmage based on defense
- **Blitz Detection**: QB identifies pressure, adjusts protection
- **Coverage Reads**: Recognize man vs zone coverage

### 6. Advanced Statistics
- **Completion Percentage**: QB accuracy tracking
- **Yards After Catch**: Receiver effectiveness
- **Pass Rush Win Rate**: DL pressure metrics
- **Third Down Efficiency**: Converting on crucial plays

### 7. Injuries and Fatigue
- **Injury System**: Random injuries affect availability
- **Stamina**: Cards lose effectiveness when overused
- **Depth Chart**: Backup players matter more

### 8. Coaching Decisions
- **Play Calling**: Tendency tracking (run/pass ratio)
- **Adjustments**: Halftime changes, in-game adaptations
- **Challenges**: Review close calls, limited per game

### 9. Weather and Environment
- **Field Conditions**: Grass vs turf, wet vs dry
- **Temperature**: Cold weather affects ball handling, kicking
- **Wind**: Impacts passing and kicking distance
- **Altitude**: Denver's thin air affects gameplay

### 10. Narrative Elements
- **Rivalry Games**: Bonus stakes for division/conference matchups
- **Playoff Pressure**: Increased importance of postseason games
- **Hall of Fame**: Career achievements for legendary cards

---

## Technical Details

### Architecture
- **Framework**: LÖVE 11.3 (Lua-based game engine)
- **Resolution**: 1600x900 (fixed)
- **State Management**: Clean state machine (menu → coach_selection → game)
- **Module Structure**: Separated concerns for maintainability

### File Structure
```
football_autobattler/
├── main.lua                # Entry point and state manager
├── conf.lua                # LÖVE configuration
│
├── Menu & UI
│   ├── menu.lua            # Main menu UI
│   ├── coach_selection.lua # Coach selection screen
│   ├── team_naming.lua     # Team name input screen
│   ├── options_menu.lua    # Game settings menu
│   ├── dropdown.lua        # Dropdown UI component
│   └── ui_scale.lua        # Adaptive UI scaling system
│
├── Core Game Systems
│   ├── coach.lua           # Coach data and definitions (4 archetypes)
│   ├── card.lua            # Card class and logic
│   ├── card_manager.lua    # Card collection manager with caching
│   ├── field_state.lua     # Down system and yard tracking
│   ├── phase_manager.lua   # Match flow and card processing
│   ├── match.lua           # Match rendering and UI
│   └── debug_logger.lua    # Debugging and logging utilities
│
├── Season Mode
│   ├── season_manager.lua  # Season lifecycle and state management
│   ├── season_menu.lua     # Season hub menu
│   ├── season_end_screen.lua # Championship/season summary screen
│   ├── team.lua            # Team structure and management
│   ├── schedule_generator.lua # Schedule and playoff bracket generation
│   └── ai_training.lua     # AI team training logic
│
├── Season Screens
│   ├── training_screen.lua # Card upgrade/training interface
│   ├── lineup_screen.lua   # Roster viewing screen
│   ├── schedule_screen.lua # Full season schedule viewer
│   ├── standings_screen.lua # Conference standings display
│   ├── stats_screen.lua    # Player statistics leaderboards
│   ├── scouting_screen.lua # Opponent analysis screen
│   └── simulation_popup.lua # Week simulation popup
│
├── Utilities
│   └── settings_manager.lua # Game settings persistence
│
├── Libraries (lib/)
│   ├── flux.lua            # Animation/tweening library
│   └── lume.lua            # Utility functions library
│
├── Documentation
│   ├── ReadMe.md           # This file
│   ├── CODE_REVIEW_REPORT.md # Technical analysis
│   ├── Offensive.png       # Offensive formation reference
│   └── Defensive.png       # Defensive formation reference
│
└── archive/                # Previous documentation versions
```

### Performance
- **Target Frame Rate**: 60 FPS
- **Current Performance**: Stable, optimized in recent updates
  - Eliminated ~200 function calls per frame via UIScale caching
  - 10-100x faster save/load operations via string optimization
  - O(n²) → O(n) team lookups via hash indexing
  - Card filtering cache eliminates redundant loops
- **Memory Usage**: Low (< 150 MB typical, < 200 MB with full season)
- **Load Times**: Season save/load < 1 second
- **Match Performance**: Consistent 60 FPS with 22+ cards on screen

---

## Contributing

### Development Guidelines
- Follow LuaDoc comment style for new functions
- Test across multiple coaches before committing
- Update this README when adding features
- Run debug_logger to troubleshoot gameplay issues

### Reporting Issues
- Describe the issue clearly
- Include which coach you were playing
- Note game state (regulation vs overtime, score, down)
- Check `match_debug.log` for technical details

---

## Credits

**Development**: The Gridiron Bazaar Team
**Framework**: LÖVE (love2d.org)
**Concept**: American Football Auto-Battler

---

## License

[Choose appropriate license]

---

## Changelog

### v0.7 (Current - Beta)
**Performance & Stability Release**
- **Phase 3 Optimizations**:
  - Card filtering cache (eliminates redundant loops)
  - Team lookup indexing (O(n²) → O(n))
  - Inline math optimizations (removed lume.clamp overhead)
  - Module-level require() statements
  - Cached coach object lookups
- **Phase 2 Bug Fixes**:
  - Playoff bounds checking (prevents array OOB crashes)
  - Nil team validation in save/load system
  - String concatenation optimization (10-100x faster saves)
  - UIScale caching (~200 calls/frame eliminated)
- **Phase 1 Critical Fixes**:
  - Win/loss tracking operator precedence
  - Cooldown initialization bug
  - Upgrade recalculation circular math
  - Division by zero guards (Card:getProgress, field goals)
- **Impact**: 18+ bugs fixed, major performance improvements

### v0.6
**UI & Polish Release**
- Tooltips for all cards including kicker/punter
- Event popup system (touchdowns, turnovers)
- Improved match UI with visual feedback
- Field position and punt distance corrections
- Training screen bug fixes
- Season save/load validation and error handling
- Defensive nil checks throughout codebase

### v0.5
**Season Mode Release**
- Full 18-team league with conferences
- 17-week regular season schedule
- Playoff system (Wildcard, Divisional, Championship, Super Bowl)
- Season save/load system
- AI team training between weeks
- Season hub menu with all management screens
- Team naming and customization
- Scouting screen for opponent analysis
- Conference standings with tiebreakers
- Stats leaderboards across league

### v0.4
**Training & Progression Release**
- Card training system with multiple upgrade types
- Training budget and economy (win/loss cash rewards)
- Lineup management screen
- Schedule viewer with simulation
- Stats tracking screen
- Training screen UI with card selection
- Max 3 upgrades per card rule
- Visual upgrade badges (+1, +2, +3)

### v0.3
**Special Teams & Core Systems Release**
- Kicker and punter implementation
- Field goal mechanics with range-based accuracy
- Punt system for field position battles
- Match end system with winner popup
- Overtime system (15-second periods)
- Card statistics tracking (offensive and defensive)
- MVP system (Offensive and Defensive Player of Game)
- Fixed card overlap issues with new formations
- Improved resolution (1600x900)
- Fixed gameplay speed issues

### v0.2
**Core Mechanics Overhaul**
- Converted from damage-based to yards-based system
- Implemented down system (initially 5-second, later 2-second downs)
- Added field position and turnover mechanics
- Increased roster to 11 players per team
- Added coach-specific abilities (4 archetypes)
- Implemented booster stacking mechanics
- Formation system with offensive/defensive layouts

### v0.1
**Initial Prototype**
- Basic card system with 4 positions
- Damage-based combat (pre-yards conversion)
- Coach selection screen
- Simple match display
- Proof of concept auto-battler mechanics

---

## FAQ

**Q: How do I win a match?**
A: Score more touchdowns than your opponent within 60 seconds (or win in overtime).

**Q: How do I win the season?**
A: Win enough games to make the playoffs, then win your way through to the Super Bowl!

**Q: What's the best coach?**
A: Each has strengths - Offensive Guru for high scoring, Defensive Mastermind for shutouts, Special Teams for consistency, Ground Game for ball control. All are viable!

**Q: Why is my offense stuck?**
A: The defense might be freezing or slowing your key cards. Upgrade your cards to reduce cooldowns, or focus on players that aren't being targeted.

**Q: What if the game is tied?**
A: Goes to overtime! 15-second periods until someone scores more. After 10+ overtimes, a safety mechanism will determine a winner.

**Q: How do I upgrade my cards?**
A: Use the Training screen from the Season Menu. Earn cash by winning (and losing) games, then spend it on upgrades. Each card can be upgraded 3 times.

**Q: Can I customize my team?**
A: You can name your team at season start. Roster customization (formation editor, lineup selection) is planned for future updates.

**Q: How do I save my season?**
A: Use the "Save Season" option in the Season Menu. The game also auto-saves after each match.

**Q: Where is my save file?**
A: Save files are stored in LÖVE's save directory:
- **Windows**: `%APPDATA%\LOVE\football_autobattler\`
- **macOS**: `~/Library/Application Support/LOVE/football_autobattler/`
- **Linux**: `~/.local/share/love/football_autobattler/`

**Q: How many teams make the playoffs?**
A: 12 teams total - the top 6 from each conference (A and B).

**Q: What happens if I lose in the playoffs?**
A: Your season ends! Better luck next season.

**Q: Can I simulate matches instead of watching?**
A: Yes! Use the Schedule screen to simulate entire weeks of AI vs AI matches. Your own matches must be played.

**Q: Why did my field goal miss?**
A: Field goal accuracy depends on distance. Longer kicks have lower success rates based on your kicker's max range and accuracy stats.

**Q: How do stats and standings work?**
A: Check the Standings screen for W-L records and Points For/Against. The Stats screen shows individual player leaderboards for yards, touchdowns, and defensive stats.

---

For more information, see CODE_REVIEW_REPORT.md for technical details.

