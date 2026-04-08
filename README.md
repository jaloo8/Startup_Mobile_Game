# VENTURE

A startup simulation mobile game. Build a tech company from a garage to a sustainable business across 20-40 quarters of strategic decisions.

## Description

VENTURE is a turn-based management simulation with idle mechanics, built in Godot 4.6 for iOS and Android. Players take on the role of a startup CEO, making quarterly decisions about hiring, product development, fundraising, hosting infrastructure, and company strategy. The game combines the depth of a business sim with the progression feel of an idle game, designed for 10-20 minute portrait-mode mobile sessions.

## Game Overview

Start a company from one of four types (SaaS, Consumer App, Marketplace, or Dev Tools), choose a niche, and hire your first employees. Each quarter you allocate your team across feature development, bug fixes, tech debt, infrastructure, and R&D. Manage your burn rate, raise funding from VC firms, compete against AI rivals, and navigate random events ranging from market downturns to viral press coverage.

The goal is to reach sustainable profitability at scale. Victory requires maintaining profitable quarters while hitting company-type-specific growth thresholds. After winning, a sandbox mode lets you keep building.

## Technical Stack

| | |
|---|---|
| Engine | Godot 4.6, Forward Plus |
| Language | GDScript |
| Resolution | 720x1280 portrait |
| Platforms | iOS, Android (Steam future) |
| Architecture | 8 autoload singletons, Resource-based data models |
| Content data | 13 JSON files |
| Codebase | 69 source files, ~24,000 lines of GDScript |
| Monetization | Free through Year 2 (8 quarters), $2.99 full unlock |

## Features

**Core simulation**
- Quarterly turn-based loop with revenue, expenses, hiring, events, and competitor simulation
- 4 company types (SaaS, Consumer App, Marketplace, Dev Tools), each with distinct revenue models and win conditions
- 3 difficulty levels (Sandbox, Normal, Hardcore) affecting churn, competitor growth, fundraising, and event pressure
- Niche selection per company type with growth/churn/revenue modifiers

**Team management**
- Hire full-time employees, contractors, and interns with distinct cost and retention profiles
- Employee specialties (Mobile, Backend, DevOps, Design, etc.) with productivity multipliers
- Deep interview system with interviewer selection, confidence-based stat estimates, and opportunity-cost locks
- Salary negotiation, morale tracking, and personality-driven collaboration effects

**Product development**
- Feature trees per company type with idle-game exponential cost scaling
- Work allocation across Features, Bugs, Tech Debt, Infrastructure, and R&D
- Interactive product mockup with tappable shipped features for reputation bonuses
- Build ETA with specialty-fit and team throughput calculations

**Fundraising and finance**
- VC fundraising with dilution, valuation modeling, and board patience mechanics
- Quarterly financial reports with cash/revenue/burn deltas and natural-language driver explanations
- Trend charts for cash, revenue, users, valuation, and team metrics
- Hosting infrastructure simulation with plan selection, lane-level capacity, and reliability pressure

**Events and world**
- Stage-aware and difficulty-scaled random events with meaningful choices
- Multi-quarter world events (risk-off cycles, regulation waves, capital reopenings)
- AI competitor behavior with niche-biased seeding and market leaderboard
- News ticker with context-aware headline generation

**Progression and meta**
- 6 starting scenarios (Garage, Accelerator, Spinoff, VC-Backed, Growth Operator, Scale Chief)
- 39 achievements across 6 categories with persistent cross-run tracking
- Founder level / prestige system with XP and unlockable perks
- Daily login bonus and streak tracking
- Run history hall of fame
- Post-victory sandbox continuation
- Save/load with atomic writes, checksums, and backup recovery

**Animation and visual polish**
- Disney-inspired animation system (squash & stretch, anticipation, follow-through, asymmetric timing)
- Procedural 14x20 pixel-art employee sprites with 4-frame animation cycles and morale expressions
- Office scene with furniture (desks, chairs, monitors with glow, plants, whiteboards, water cooler, coffee mugs)
- Economy mood lighting (bull/bear vignettes on dashboard)
- Celebration effects: confetti bursts, screen flashes, typewriter text reveals, screen shake
- Per-screen entrance animations (fade, slide, stagger, pop-in)

**Mobile and UX**
- 5-step guided tutorial for first-run players
- 44-48px touch targets enforced across all interactive elements
- Quarter transition animations with SFX hooks and synthesized fallbacks
- Dev tools panel for testing (god mode, time skip, state inspector, quick save/load)
- Performance optimizations: sprite caching, avatar texture caching, resize debouncing

## Project Structure

```
startup_mobile_game/
├── project.godot
├── src/
│   ├── autoload/       # 8 global singletons (game state, scene loader, analytics, etc.)
│   ├── models/         # 6 Resource-based data containers
│   ├── engine/         # 11 simulation modules (core loop, revenue, hiring, events, etc.)
│   ├── ui/             # 14 screen modules + shared components
│   ├── data/           # 13 JSON content files (events, features, competitors, etc.)
│   └── resources/      # Godot resource definitions
├── tools/
│   ├── backend_smoke.py    # Offline structural validation
│   └── balance_sim.py      # Automated balance simulation (108-run matrix)
├── tests/                  # Test files
├── docs/                   # Design docs, roadmap, QA checklist
└── assets/                 # Illustrations, icons, avatars
```

## Getting Started

1. Install [Godot 4.6](https://godotengine.org/download) (Standard or .NET edition).
2. Clone this repository.
3. Open `project.godot` in the Godot editor.
4. Press F5 (or the Play button) to run.

The game runs in 720x1280 portrait mode. On desktop, the editor window will simulate the mobile viewport.

## Development

**Smoke tests**

Run the offline structural validator to check JSON content integrity and feature-ID wiring:

```bash
python3 tools/backend_smoke.py
```

**Balance simulation**

Run the automated balance matrix (4 types x 3 difficulties x 3 strategies x 3 seeds = 108 runs):

```bash
python3 tools/balance_sim.py
```

**Dev mode**

Enable dev mode in-game through the Settings screen to access the developer tools panel, which includes a state inspector, cash/user injection, time skip, god mode, difficulty swap, and 5-slot quick save/load.

## Current Status

Core gameplay is 92%+ content-complete across 15 screens, 69 source files, and 312 content items. All major systems work end-to-end. Balance tuning pass completed (Apr 2026) addressing profit streak requirements, SaaS/Dev Tools revenue thresholds, and Hardcore survivability. Animation and visual polish pass completed with Disney-inspired motion across all screens. Next milestones: first device build on iOS/Android, IAP wiring, internal beta (TestFlight/Play Store internal track), then public launch targeting mid-May 2026.

## License

MIT -- see [LICENSE](LICENSE).
