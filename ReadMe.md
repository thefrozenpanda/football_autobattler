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
  - Offensive Guru (passing-focused)
  - Defensive Mastermind (elite defense)
  - Special Teams Specialist (field position advantage)
  - Ground Game Coach (run-heavy offense)

#### Match System
- **Yards-Based Progression**: Advance 80 yards (68 for Special Teams) to score
- **Down System**: 5-second downs, 4 downs to gain 10 yards for first down
- **Field Position**: Turnovers inherit current field position
- **60-Second Regulation**: Timed matches with overtime support
- **Overtime**: 15-second periods if tied (First, Second, Third Overtime, etc.)

#### Card System
- **11-Man Rosters**: Authentic football positions per team
- **Card Types**:
  - Yard Generators (QB, RB, WR, TE) - generate yards per action
  - Boosters (OL, some TE) - enhance yard generation with % boosts
  - Defenders (DL, LB, CB, S) - apply status effects (slow, freeze, yard removal)
- **Statistics Tracking**: Individual card stats throughout match
  - Offensive: Yards gained, touchdowns scored, times boosted others
  - Defensive: Times slowed, times froze, yards removed

#### UI/UX
- **Main Menu**: Start game or exit
- **Coach Selection Screen**: Visual cards with coach abilities and formations
- **Match Display**: Real-time game state, down counter, field position
- **Winner Popup**: Final score, Offensive MVP, Defensive MVP stats
- **Pause System**: In-game pause with resume/quit options
- **Overtime Indicator**: Yellow highlight during overtime periods

#### Visual System
- **Formation-Based Positioning**: Cards arranged in authentic football formations
- **Status Effects**: Visual indicators for slowed/frozen cards
- **Progress Bars**: Show card cooldown progress
- **1600x900 Resolution**: Optimized for readability

---

## Gameplay Mechanics

### Down System
- Each down lasts **5 seconds** (auto-advances)
- Offense needs **10 yards in 4 downs** for first down
- Failure to gain 10 yards = **turnover** (defense inherits field position)
- Gaining 10+ yards = **first down** (down counter resets to 1st)

### Card Actions
- Cards act automatically based on **cooldown timers** (3-5 seconds)
- **Yard Generators**: Generate base yards (2.5-4.5 per action)
- **Boosters**: Apply percentage boosts to targeted positions
  - Example: OL boosts QB by 20%, so 4-yard play becomes 4.8 yards
  - Boosts stack additively (multiple OL boost the same QB)
- **Defenders**: Apply one of three status effects:
  - **Slow**: Reduces target card's progress rate to 50% (2 seconds)
  - **Freeze**: Completely stops target card progress (1 second)
  - **Remove Yards**: Subtracts yards from offense's total

### Scoring
- Reach **yardsNeeded** (80 or 68) = **Touchdown** (7 points)
- Phase switches after TD or turnover
- Match ends when timer reaches 0:00
- Tied games go to **overtime**

### Coach Abilities
- **Offensive Guru**: All yard generators gain +10% yards
- **Defensive Mastermind**: 5% chance to remove 2 extra yards on defensive plays
- **Special Teams**: Start at 32-yard line instead of 20 (need 68 yards vs 80)
- **Ground Game**: Running backs (RB) gain +2 extra yards per action

---

## Development Status

### Current Version: Alpha v0.3
- **Phase**: Early prototype with core mechanics implemented
- **Playable**: Yes - full match flow from menu to winner screen
- **Balance**: Initial tuning complete, playable but may need adjustment
- **Next Focus**: Seasonal structure and progression systems

### Recent Updates
- Match end system with MVP calculations
- Overtime system (multiple periods)
- Winner popup with detailed statistics
- Card statistics tracking
- Formation improvements to prevent overlap
- Debug logging system for troubleshooting

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
- **Arrow Keys**: Navigate menu options
- **Enter / Space**: Select option
- **Mouse**: Click buttons or hover for highlight
- **ESC**: Quit game (from main menu)

### Coach Selection
- **Arrow Keys**: Navigate coaches (Left/Right)
- **Enter / Space**: Select coach
- **Mouse**: Click coach card or hover for highlight
- **ESC**: Return to main menu

### Match
- **ESC**: Pause game
- **Mouse**: Click "Return to Menu" on winner screen

### Pause Menu
- **Arrow Keys**: Navigate options (Up/Down)
- **Enter / Space**: Select option
- **Mouse**: Click buttons or hover for highlight
- **ESC**: Resume game

---

## Planned Features

### Next Phase: Weekly Preparation
- **Card Selection Screen**: Choose starting lineup before each match
- **Bench Management**: Build roster depth, make strategic substitutions
- **Formation Editor**: Customize offensive and defensive formations

### Season Structure
- **10-Win Championship**: Progress through regular season to championship
- **Season Stats**: Track performance across multiple games
- **Difficulty Scaling**: AI opponents get stronger as season progresses

### Economy System
- **Salary Cap**: Limited budget for building roster
- **Card Acquisition**: Pack opening, trading, free agency
- **Upgrades**: Improve card stats over time

### Enhanced Gameplay
- **Special Plays**: Field goals, punt returns, two-point conversions
- **Weather Effects**: Impact gameplay (wind, rain, snow)
- **Home Field Advantage**: Bonus for home team
- **Momentum System**: Hot/cold streaks affect performance

### Updated Card Training
- **Additional Trainings**: Critical Chance (1.5x card effects), 
- **Week vs Season vs Perm Boots**: 
- **Training Card Tiers**: Bronze, Silver, and Gold. Add the ability to upgrade a boost so as to not take up multiple slots for the same Training Type. 
- **Selective Training**: Add the ability to specify who the training is assigned to.

### Updated Coaching System
- **Updated Archtypes**: Archtypes now only allow the user to select 1 coach skill initially. Additional skills, both active and passive, are unlocked through gaining levels. Levels are gained through gaining experience. Experience is gained through completing games, seasons, and coaching challenges.
- **Coordinators**: Add offensive, defensive, and speacial teams coordinators to the game. Their purpose is to provide additional benefits, in the form of passive bonuses, to their respective group of players. They will also have their own sub-archtypes and leveling system. At their maximum level, they will unlock their lone activatable ability. Activatable abilities are used during matches to provide a short term boost to their group of players.

### New Mode: Dynasty
- **New Game Mode: Dynasty**: Dynasty mode is meant to be a multi-season adventure into managing and growing a team. The player 
- **Offseason Training Mode**: In between seasons, 
- **Player Aging**: As season go by, players will gain age. This will affect their .
- **New Phase: Draft**: Add the ability to specify who the training is assigned to.
- **New Phase: Free Agency**: Add the ability to specify who the training is assigned to.

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
├── main.lua              # Entry point and state manager
├── conf.lua              # LÖVE configuration
├── menu.lua              # Main menu UI
├── coach_selection.lua   # Coach selection screen
├── coach.lua             # Coach data and definitions
├── card.lua              # Card class and logic
├── card_manager.lua      # Card collection manager
├── field_state.lua       # Down system and yard tracking
├── phase_manager.lua     # Match flow and card processing
├── match.lua             # Match rendering and UI
├── debug_logger.lua      # Debugging utilities
├── Offensive.png         # Formation reference image
├── Defensive.png         # Formation reference image
└── CODE_REVIEW_REPORT.md # Technical analysis
```

### Performance
- **Target Frame Rate**: 60 FPS
- **Current Performance**: Stable, no bottlenecks identified
- **Memory Usage**: Low (< 100 MB)

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

### v0.3 (Current)
- Added match end system with winner popup
- Implemented overtime (15-second periods)
- Added card statistics tracking (offensive and defensive)
- Implemented MVP system (Offensive and Defensive Player of Game)
- Fixed card overlap issues with new formations
- Improved resolution (1600x900) for better readability
- Fixed gameplay speed issues (cards now act at proper intervals)

### v0.2
- Converted from damage-based to yards-based system
- Implemented down system (5-second downs, 4 downs for first down)
- Added field position and turnover mechanics
- Increased roster to 11 players per team
- Added coach-specific abilities
- Implemented booster stacking mechanics

### v0.1
- Initial prototype
- Basic card system with 4 positions
- Damage-based combat
- Coach selection screen
- Simple match display

---

## FAQ

**Q: How do I win?**
A: Score more touchdowns than your opponent within 60 seconds (or win in overtime).

**Q: What's the best coach?**
A: Each has strengths - Offensive Guru for high scoring, Defensive Mastermind for shutouts, Special Teams for consistency, Ground Game for ball control.

**Q: Why is my offense stuck?**
A: Defense might be freezing or slowing your key cards. Diversify your offense or rely on cards that aren't being targeted.

**Q: What if the game is tied?**
A: Goes to overtime! 15-second periods until someone scores more.

**Q: Can I customize my team?**
A: Not yet - rosters are fixed per coach. This is planned for future updates.

---

For more information, see CODE_REVIEW_REPORT.md for technical details.

