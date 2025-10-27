# The Gridiron Bazaar: An American Football Auto-Battler Design Document

## Executive Summary

This document outlines the conversion of "The Bazaar" into an American Football-themed auto-battler called "The Gridiron Bazaar." The game maintains the core loop of asynchronous PvP, item collection, and strategic positioning while reimagining all systems through the lens of American Football.

---

## Core Gameplay Loop

### Overview
Players assume the role of a **Head Coach** building and managing a team through a season. Each "run" represents a season culminating in the playoffs, with the goal of winning 10 games to reach the Championship.

### Daily Structure (Game Weeks)
- **Hours 1-5**: Training Camp Activities
  - Scout players from free agency
  - Negotiate trades with other teams
  - Practice drills (PvE encounters)
  - Team facility upgrades
  - Media events and sponsorships
- **Hour 6**: Game Day (Auto-battler PvP)

### Prestige System → Team Morale
- Start with 20 Morale points
- Losing games reduces morale by the week number
- At 0 Morale: "Rally Event" (equivalent to Resurrection)
  - Owner intervention
  - Locker room speech
  - Star player return from injury

---

## Hero System → Head Coach Archetypes

### 1. **The Offensive Guru** (Vanessa equivalent)
- **Philosophy**: High-scoring, aggressive offense
- **Starting Item Pool**: Passing plays, wide receivers, offensive linemen
- **Unique Mechanic**: "Air Raid" - extra passing play slots
- **Signature Skill**: "No Huddle" - reduces all offensive play cooldowns

### 2. **The Defensive Mastermind** (Dooley equivalent)
- **Philosophy**: Defense wins championships
- **Starting Item Pool**: Defensive formations, linebackers, safeties
- **Unique Mechanic**: "The Wall" - defensive plays can stack effects
- **Signature Skill**: "Blitz Package" - periodic overwhelming defensive pressure

### 3. **The Special Teams Specialist** (Pygmalien equivalent)
- **Philosophy**: Field position and special plays
- **Starting Item Pool**: Kickers, punters, returners, trick plays
- **Unique Mechanic**: "Field Position" - currency generation through strategic punting
- **Signature Skill**: "Hidden Yardage" - special teams plays generate momentum

### 4. **The Ground Game Coach** (Mak equivalent)
- **Philosophy**: Run-heavy, possession football
- **Starting Item Pool**: Running backs, fullbacks, tight ends
- **Unique Mechanic**: "Time of Possession" - damage over time through sustained drives
- **Signature Skill**: "Pound the Rock" - running plays gain power over time

---

## Item System → Players and Plays

### Item Types (Player/Play Categories)

#### Players (Equipment)
- **Quarterbacks** (Large Weapons)
  - Execute passing plays
  - High damage, longer cooldowns
  - Example: "Franchise QB" - 300 damage every 8 seconds
  
- **Running Backs** (Medium Weapons)
  - Consistent ground game
  - Medium damage, medium cooldowns
  - Example: "Workhorse RB" - 150 damage every 4 seconds

- **Wide Receivers** (Small Weapons)
  - Quick strikes
  - Lower damage, fast cooldowns
  - Example: "Slot Receiver" - 75 damage every 2 seconds

- **Linemen** (Shield Items)
  - Provide protection (shields)
  - Enable other players
  - Example: "All-Pro Guard" - Grants 50 shield to adjacent players

#### Plays (Tools/Tech)
- **Offensive Plays**
  - "Hail Mary" - High damage, long cooldown, can crit
  - "Screen Pass" - Quick damage that scales with shields
  - "QB Sneak" - Fast, guaranteed small damage

- **Defensive Plays**
  - "Zone Coverage" - Reduces incoming damage by percentage
  - "Man Coverage" - Nullifies specific opponent plays
  - "Safety Blitz" - Destroys opponent's rightmost item

- **Special Teams Plays**
  - "Onside Kick" - Chance to steal opponent's currency
  - "Field Goal" - Consistent damage based on field position
  - "Punt Return" - Converts defense into offense

### Item Sizes → Player Positions
- **Small (1 slot)**: Specialists, Kickers, Slot Receivers
- **Medium (2 slots)**: Running Backs, Linebackers, Safeties
- **Large (3 slots)**: Quarterbacks, Offensive Linemen, Defensive Ends

### Item Rarity → Player Talent Level
- **Bronze**: Rookie/Practice Squad
- **Silver**: Starter
- **Gold**: Pro Bowl
- **Diamond**: Hall of Fame

---

## Combat System → The Game

### Auto-Battle Mechanics

#### Pre-Game (Start of Combat)
1. **Coin Toss** - Random determination of who gets opening possession
2. **Opening Drive** - First item to activate gets bonus damage
3. **Home Field Advantage** - Based on win streak

#### During the Game
- **Drives**: Items activate on cooldowns representing offensive drives
- **Turnovers**: Critical failures that give opponent momentum
- **Time Management**: Some plays affect cooldown speeds
- **Momentum Swings**: Combo effects from successful play sequences

#### Game End Conditions
- **Regulation**: 30-second timer (four quarters)
- **Overtime**: Sudden death if tied
- **Mercy Rule**: Game ends early if lead exceeds threshold

### Status Effects → Game States

| Bazaar Effect | Football Equivalent | Description |
|--------------|-------------------|-------------|
| Burn | Fatigue | Players lose effectiveness over time |
| Poison | Injury | Bypasses protection, direct health damage |
| Freeze | Penalty | Skip next activation |
| Shield | Blocking | Absorbs incoming damage |
| Haste | No-Huddle | Faster play activation |
| Slow | Clock Management | Slower activation |
| Charge | Momentum | Instant activation boost |
| Regeneration | Fresh Legs | Health recovery over time |

---

## Progression Systems

### Experience → Season Progress
- Gain XP through:
  - Winning games
  - Completing practice drills
  - Media appearances
  - Fan events
- Level up rewards:
  - Roster expansion (more item slots)
  - Coaching tree upgrades (skill choices)
  - Salary cap increases

### Skills → Coaching Philosophy

#### Offensive Tree Examples
- **West Coast Offense**: Short passes deal +25% damage
- **Vertical Passing**: Deep balls can critically strike
- **Read Option**: Running plays adapt based on defense

#### Defensive Tree Examples  
- **Tampa 2**: Middle items gain defensive bonuses
- **46 Defense**: Overwhelming pressure on leftmost enemy
- **Prevent Defense**: Take less damage when ahead

#### Special Teams Tree Examples
- **Coffin Corner**: Punts apply debuffs
- **Return Specialist**: Convert defense to offense
- **Clutch Kicker**: Field goals gain power late game

---

## PvE Encounters → Practice & Preseason

### Training Camp Drills
Replaces monster encounters with themed football challenges:

#### Early Season (Days 1-3)
- **Rookie Scrimmage**: Easy encounter, drops basic players
- **Position Drills**: Targeted loot for specific positions
- **Two-Minute Drill**: Time pressure encounter

#### Mid Season (Days 4-6)
- **Division Rival**: Moderate difficulty, rivalry bonuses
- **Prime Time Game**: High risk/reward under lights
- **Weather Game**: Environmental hazards

#### Late Season (Days 7-10)
- **Playoff Preview**: Tough teams, playoff-caliber loot
- **Championship Defense**: Previous season's champion
- **Hall of Fame Team**: Legendary difficulty

### Encounter Rewards → Scouting Reports
- Player acquisitions
- Playbook additions
- Coaching insights (skills)
- Equipment upgrades

---

## Economy System → Team Management

### Currency → Salary Cap
- Start with 8M cap space, 5M annual increase
- Spend on:
  - Player contracts
  - Play installations
  - Facility upgrades
  - Coaching staff

### Merchants → Team Resources

#### Front Office (Merchants)
- **General Manager**: High-value players, expensive
- **Scout**: Hidden gems, random quality
- **Assistant Coach**: Playbook expansions
- **Team Doctor**: Injury recovery, regeneration items
- **Equipment Manager**: Upgrades and enchantments

#### Income Sources
- **Ticket Sales**: Base income each week
- **Merchandise**: Scales with wins
- **TV Deals**: Bonuses for primetime games
- **Sponsorships**: Special event rewards

---

## Unique Football Mechanics

### 1. **Playbook Synergies**
Certain plays work better together:
- Run + Play Action = Deception bonus
- Pass + Draw = Misdirection bonus
- Blitz + Coverage = Pressure bonus

### 2. **Formation System**
Item positioning matters more:
- **I-Formation**: Middle items gain run bonuses
- **Spread**: Wide items gain pass bonuses
- **Nickel/Dime**: More slots for defensive backs

### 3. **Clock Management**
New strategic layer:
- Some plays "burn clock" (delay enemy items)
- Others run "hurry-up" (accelerate your items)
- "Timeouts" as one-time tactical advantages

### 4. **Injury System**
Adds risk/reward:
- Players can get injured (temporary debuffs)
- "Load management" - rest players for bigger games
- Medical staff items for recovery

### 5. **Home/Away Games**
Alternating advantages:
- Home games: Crowd noise disrupts opponent
- Away games: Earn more XP/currency for wins

---

## Seasonal Events & Meta-Game

### Season Structure
- **Preseason** (Tutorial): 4 practice games
- **Regular Season**: 10 potential wins needed
- **Playoffs**: Ranked mode equivalent
- **Pro Bowl**: Special event with unique rules
- **Draft**: New player acquisition events

### Dynasty Mode Features
- Carry over certain players between runs
- Coaching legacy bonuses
- Hall of Fame for best builds
- Team customization (colors, logos, stadiums)

---

## Monetization Conversion

### Base Game Access
- Free "Assistant Coach" mode (Normal)
- "Head Coach" mode requires pass (Ranked)

### Premium Content
- **Franchise Packs**: New coach types
- **Uniform Packs**: Cosmetic team customizations
- **Legendary Players**: Special edition historical players
- **Stadium Themes**: Visual environments
- **Announcer Packs**: Different commentary styles

### Battle Pass → Season Pass
- Weekly challenges
- Playoff rewards
- Championship rings (cosmetic achievements)
- Historical team unlocks

---

## User Interface Adaptations

### Main Screen → Locker Room
- Trophy case displays achievements
- Team photos show successful builds
- Playbook browser for theorycrafting

### Combat Screen → Football Field
- 100-yard field visualization
- Scoreboard shows health/damage
- Down and distance indicators
- Play-by-play commentary feed

### Shop Screen → Team Facilities
- War room for strategy
- Film room for reviewing past games
- Weight room for upgrades

---

## Multiplayer Features

### Asynchronous Tournaments
- **Division Play**: Weekly standings
- **Conference Championships**: Monthly events
- **Super Bowl**: Ultimate championship

### Social Features
- Trade proposals between players
- Coaching clinics (build sharing)
- Fantasy leagues within the game
- Replay system for epic games

---

## Example Build Strategies

### 1. **Air Raid Offense**
- Stack wide receivers and passing plays
- Focus on quick-strike damage
- Vulnerable to sustained defensive pressure

### 2. **Ground and Pound**
- Heavy running backs and offensive line
- Damage over time through possession
- Weak against aggressive defenses

### 3. **Defensive Domination**
- Stack defensive plays and linebackers
- Win through attrition and turnovers
- Struggles against balanced offenses

### 4. **Special Teams Chaos**
- Maximize field position and trick plays
- Unpredictable win conditions
- High risk, high reward

---

## Technical Considerations

### Maintaining The Bazaar's Core Appeal
- **Depth**: Multiple viable strategies per coach
- **Discovery**: Hidden synergies between players/plays
- **Progression**: Clear power growth through a run
- **Fairness**: No pay-to-win mechanics
- **Accessibility**: Easy to learn, hard to master

### Key Differences from The Bazaar
- Stronger thematic integration
- More emphasis on positioning (formations)
- Time management as strategic element
- Team building over item collecting
- Seasonal narrative structure

---

## Conclusion

"The Gridiron Bazaar" translates The Bazaar's innovative auto-battler mechanics into an American Football theme while adding sport-specific strategic elements. The conversion maintains the core appeal of asynchronous PvP, strategic depth, and rewarding progression while creating a unique identity through football's tactical richness.

The game targets both football fans seeking a strategic team-building experience and auto-battler enthusiasts looking for fresh mechanics. By combining The Bazaar's proven gameplay loop with American Football's strategic depth, The Gridiron Bazaar offers a compelling new entry in the auto-battler genre.

---

## Appendix: Quick Reference

### Conversion Table

| The Bazaar | The Gridiron Bazaar |
|------------|-------------------|
| Heroes | Head Coaches |
| Items | Players & Plays |
| Combat | Games |
| Days | Weeks |
| Hours | Training/Game Time |
| Merchants | Team Staff |
| Gold | Salary Cap |
| Prestige | Team Morale |
| Skills | Coaching Philosophy |
| PvE Monsters | Practice Squads |
| Resurrection | Rally Event |
| Stash/Rug | Bench/Field |

### Development Priorities

1. **Phase 1**: Core combat system with football animations
2. **Phase 2**: Four base coaches with unique playstyles  
3. **Phase 3**: Full season structure and progression
4. **Phase 4**: Social features and tournaments
5. **Phase 5**: Seasonal content and live operations
