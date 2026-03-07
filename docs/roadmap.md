# Venture — Roadmap & Development Guide

**Goal:** Nothing → shipped game in 13 weeks. Work through phases sequentially; each one should be playable before starting the next.

---

## Development Phases

### Phase 0: Paper Prototype (Weekend 1)

**Goal:** Validate the core decision loop is fun before writing code.

**What to do:**
- Open a spreadsheet or use index cards
- Create 5 employee cards with stats
- Create a simple product tracker (features, tech debt, bugs)
- Create a cash tracker (starting cash, burn rate, revenue)
- Play 4 "quarters" manually:
  - Allocate employees to tasks
  - Roll dice for outcomes (or just decide what feels realistic)
  - Process an event card you wrote
  - Update numbers
- **Signal it's working:** You find yourself agonizing over allocation tradeoffs

**Deliverable:** A one-page notes doc on what felt fun and what felt tedious.

---

### Phase 1: Skeleton App (Weeks 1–2)

**Goal:** Playable but ugly. Core loop works end-to-end.

**Build in this order:**
1. Data model (GameState, Company, Employee, Product, Financials)
2. New game setup screen (pick company type, name, difficulty)
3. Quarter cycle: advance button that runs the simulation
4. Employees screen (list view, stats, hire/fire)
5. Product screen (allocation sliders for team work distribution)
6. Finance screen (cash, burn, revenue, runway display)
7. End-of-quarter results screen
8. Save/load

**Cursor prompt for Phase 1:**

```
I'm building a tech startup management sim game in Godot 4.3 (GDScript).
The game is structured as a turn-based simulation where each turn
represents one quarter (3 months).

Start by creating the core data model as Resource classes. Key entities:

[Paste the Data Model from game-design.md Section 4.2]

Then create a SimulationEngine class that processes one quarter:
[Paste the Simulation Engine steps from game-design.md Section 4.3]

Use an autoload GameState singleton for all run state. Keep the UI
minimal for now — just Control nodes with Labels and Buttons.
We'll make it pretty later.

Start with the Employee system:
- Generate random employees with stats
- Display them in a list (VBoxContainer of employee cards)
- Allow hiring from a candidate pool
- Allow firing
- Allow assigning to work categories (Features, Bugs, TechDebt, Infra, R&D)

Then build the quarterly simulation that takes those assignments
and produces outcomes (features built, bugs fixed, etc.)
```

---

### Phase 2: Systems Depth (Weeks 3–5)

**Goal:** All core systems functional. Game is playable start to finish.

**Build:**
1. Hiring pipeline (post job → wait → receive candidates → interview → offer)
2. Product feature system (specific features to build, not just sliders)
3. Revenue calculation based on company type
4. Competitor AI (simple: they grow users and raise money on a schedule)
5. Event system (create 20+ events, trigger based on context)
6. Fundraising flow (VC meetings, term sheets, dilution calc)
7. Win/loss conditions and game over screen
8. Basic market/economic conditions that shift over time

**Cursor prompt for event system:**

```
Add an event system to the startup sim game. Events should:

1. Be defined as data (not hardcoded logic) so we can easily add more.
   Each event has:
   - id, title, description (narrative text)
   - choices[] — 2-3 options the player can pick
   - each choice has: label, effects (changes to game state), outcome_text
   - trigger_conditions: when this event can fire (e.g., employee_count > 5,
     quarter > 4, has_raised_funding == true)
   - weight: probability of firing when conditions are met
   - one_time: boolean (some events only fire once per game)

2. At the start of each quarter, roll for 1-3 events from the eligible pool.
   Present them in the Inbox screen. Player must resolve all events before
   advancing the quarter.

3. Here are 10 starter events to implement:
   [Paste 10 events from game-design.md Section 3.6 with specific effects]

Make the event definitions loadable from a JSON file so I can
add more without changing code.
```

---

### Phase 3: Polish & Balance (Weeks 6–8)

**Goal:** Game feels good to play. Numbers are balanced. UI is clean.

**Build:**
1. UI overhaul — clean mobile-native design (reference PGM3's minimal aesthetic)
2. Charts and graphs (revenue over time, user growth, employee morale trends)
3. Employee detail view with history and development arc
4. Quarterly report that summarizes what happened (narrative + stats)
5. Game balance tuning — play 10+ complete runs, adjust numbers
6. Difficulty balancing across all three modes
7. Tutorial / first-quarter guided experience
8. Sound effects and minimal music (optional, nice-to-have)

**Cursor prompt for UI polish:**

```
Redesign the employee list screen for the startup sim game.
Current design is a basic VBoxContainer of labels. I want it to feel
like a premium mobile game, similar to Pocket GM 3's player cards.

Each employee card should show:
- Name and role/specialty (e.g., "Sarah Chen — Senior Backend")
- Skill bar (visual, color-coded: red < 30, yellow 30-70, green > 70)
- Morale indicator (emoji or icon)
- Current assignment badge (Features/Bugs/Debt/Infra/R&D)
- Salary (compact format: "$85K/yr")
- Tap to expand for full detail view

Use a dark theme with accent colors. No gradients. Clean typography.
Use PanelContainer with StyleBoxFlat for cards — rounded corners, thin border.
Sort options: by name, skill, morale, salary, specialty.
Apply a custom Godot Theme resource for consistency.
```

---

### Phase 4: Content & Replayability (Weeks 9–11)

**Goal:** Enough content for 20+ hours of unique gameplay.

**Build:**
1. Expand to 50+ events (use AI batch generation, then hand-edit for quality)
2. All 4 Software company types fully differentiated with unique mechanics
3. Unlockable scenarios (starting conditions that change the game)
4. Statistics and achievement system (track across runs)
5. "Postmortem" game-over screen with timeline visualization
6. Seed system — share seeds for specific market conditions

**AI prompt for batch-generating events:**

```
I'm building a tech startup management sim. I need events that
feel authentic to the startup experience. Each event should force
a meaningful decision with real tradeoffs.

Generate 20 events in this JSON format:
{
  "id": "unique_id",
  "title": "Short title",
  "description": "2-3 sentence narrative description from CEO's perspective",
  "stage": "early/growth/late",
  "company_types": ["saas", "consumer"],
  "choices": [
    {
      "label": "Short action label",
      "effects": { "cash": -5000, "morale_all": -5, "reputation": +10 },
      "outcome": "1-2 sentence result description"
    }
  ]
}

Focus on events in these categories:
- Employee drama (conflicts, departures, surprises)
- Product crises (outages, security, technical)
- Financial pressure (costs, revenue, fundraising)
- Market shifts (competitors, regulations, trends)
- Growth challenges (scaling, culture, process)

Make the tradeoffs genuinely hard. No obvious "right answer."
```

---

### Phase 5: Ship (Weeks 12–13)

**Goal:** App Store submission.

**Build:**
1. App Store screenshots and description
2. App icon
3. Final bug fixes and crash testing
4. TestFlight beta to 10–20 friends for feedback
5. Incorporate critical feedback
6. Submit to App Store

---

## Summary Timeline

| Phase | Focus | Weeks |
|-------|-------|-------|
| 0 | Paper prototype | Weekend 1 |
| 1 | Skeleton app (core loop end-to-end) | 1–2 |
| 2 | Systems depth (all systems functional) | 3–5 |
| 3 | Polish & balance (UI, tuning, tutorial) | 6–8 |
| 4 | Content & replayability (events, scenarios) | 9–11 |
| 5 | Ship (TestFlight, App Store) | 12–13 |

---

## Priority Checklist

Do these in order. Each one should be playable before starting the next.

### v1.0 — Base Game (Software Path)

- [ ] **Data model** — GameState autoload with path-module pattern for future DLC support
- [ ] **Advance quarter** — Button that processes a turn (even if nothing happens)
- [ ] **Employee system** — Generate, hire, view, fire employees
- [ ] **Work allocation** — Assign employees to tasks, see output
- [ ] **Product metrics** — Features, bugs, tech debt affected by work
- [ ] **Basic finances** — Burn rate, revenue, cash, runway countdown
- [ ] **Game over** — Bankruptcy when cash hits zero
- [ ] **Events (10)** — First batch of narrative events with choices
- [ ] **SaaS revenue model** — Subscription + user growth for first company type
- [ ] **Competitors** — Basic AI companies that grow and compete
- [ ] **Fundraising** — VC system with offers and dilution
- [ ] **Events (30 more)** — Expand the event library
- [ ] **All 4 Software company types** — SaaS, Consumer, Marketplace, Dev Tools differentiated
- [ ] **UI polish** — Make it look like a real game
- [ ] **Tutorial** — Guided first quarter
- [ ] **Win conditions** — IPO, acquisition, profitability
- [ ] **Difficulty tuning** — Balance all three difficulty modes
- [ ] **Achievements** — Track across runs
- [ ] **Ship it**

### v1.2 — DLC #1: The Intelligence Age (AI/ML Path)

- [ ] **GPU/Compute budget system** — Resource management for training and inference
- [ ] **Model quality score** — Training runs improve model, affects product quality
- [ ] **AI revenue models** — Usage-based API pricing, subscription
- [ ] **3 AI company types** — AI SaaS/API, AI-Powered App, AI Research Lab
- [ ] **AI employee specialties** — ML Engineer, Research Scientist, Data Engineer
- [ ] **40 AI-specific events** — Hype cycles, model leaks, compute costs, talent war
- [ ] **Balance & test**

### v1.3 — DLC #3: Press Start (Gaming Path)

- [ ] **Game project system** — Multiple projects with genres, platforms, quality scores
- [ ] **Review score simulation** — Press + user reviews based on quality and market fit
- [ ] **Wishlist / hype mechanic** — Pre-launch marketing affects launch spike
- [ ] **3 Gaming company types** — Indie, AA, Live Service
- [ ] **Gaming employee specialties** — Game Designer, QA, Community Manager
- [ ] **40 gaming-specific events** — Crunch, delays, viral moments, publisher pressure
- [ ] **Balance & test**

### v1.4 — DLC #2: Silicon Dreams (Hardware Path)

- [ ] **Manufacturing system** — Fabless vs. own production, BOM, defect rates
- [ ] **Supply chain management** — Components, suppliers, shortages, tariffs
- [ ] **Product generations** — Multi-quarter R&D cycles, tape-out risk
- [ ] **Inventory system** — Demand forecasting, dead stock, stockouts
- [ ] **3 Hardware company types** — Consumer Electronics, Chip Design, Robotics
- [ ] **Hardware employee specialties** — RTL Designer, MechE, Supply Chain Ops
- [ ] **40 hardware-specific events** — Fab delays, recalls, supply shortages, certification
- [ ] **Balance & test**

### v1.5 — DLC #4: The Platform Play (OS & Platform Path)

- [ ] **Developer ecosystem system** — Track third-party developers, SDK adoption
- [ ] **Platform governance decisions** — Fees, policies, API changes
- [ ] **Network effects model** — Users ↔ developers flywheel
- [ ] **2 Platform company types** — OS, Developer Platform/Cloud
- [ ] **Platform employee specialties** — DevRel, Platform Engineer, Partner Manager
- [ ] **30 platform-specific events** — Antitrust, developer revolt, ecosystem health
- [ ] **Balance & test**

---

## Cursor-Specific Workflow Tips

### Session structure — work in vertical slices, not horizontal layers
- Don't: "Build all the UI, then all the logic, then all the data"
- Do: "Build the Employee hiring flow end-to-end, then the Product allocation flow end-to-end"

### Prompt patterns that work well with Cursor

1. **Start each feature with the data model change:**
   "Add a `fundraising_round` property to CompanyData resource with fields for..."

2. **Then ask for the logic:**
   "Write a static function in SimulationEngine that simulates a VC meeting. Input: company metrics. Output: offer or rejection with terms."

3. **Then ask for the UI:**
   "Create a Godot scene with PanelContainers that displays the VC offer as a card with Accept/Negotiate/Decline buttons."

4. **Always provide context about the broader system:**
   "This is part of a startup sim game built in Godot 4.3. The player is the CEO. This screen appears when they choose to pursue fundraising in the Money tab."

### Common Cursor pitfalls for game dev

- **Cursor will over-engineer.** Tell it to keep things simple. "Use a simple Dictionary for this, not a full Resource class."
- **Cursor will forget game state connections.** Remind it: "Remember, employee morale affects their work output in the simulation engine. Check game_state.gd."
- **Cursor will make UI too complex.** Tell it: "Mobile-first. One column. Thumb-reachable. No horizontal scrolling. Use VBoxContainer."
- **Test each system as you build it.** Don't build 5 systems then try to connect them. Build one, play it, then build the next.

---

*Update checklist status as you complete each objective.*
