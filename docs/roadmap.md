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

**Phase 1 — Core Loop (DONE):**
- [x] **Data model** — GameState autoload with Resource-based models (Company, Employee, Product, Financials, Market, Event)
- [x] **Advance quarter** — 12-step simulation engine (work output, growth, revenue, costs, competitors, events, morale, quits, skill growth, clamping)
- [x] **Employee system** — Generate candidates, hire, view, fire, assign work categories, skill growth, quit mechanic
- [x] **Work allocation** — Assign employees to Features/Bugs/Tech Debt/Infra/R&D, see output each quarter
- [x] **Product metrics** — Feature shipping, bugs, tech debt, stability, UX score, churn rate affected by work
- [x] **Basic finances** — Burn rate (salaries + infra + office), revenue (4 models), cash, runway display
- [x] **Game over** — Bankruptcy and dead product conditions
- [x] **Events (10 initial)** — 10 narrative events with template variables, variations, weighted selection, cooldowns (now expanded to 41)
- [x] **All 4 revenue models** — SaaS, Consumer, Marketplace, Dev Tools each calculate differently
- [x] **Competitors** — 4 AI companies that grow users, improve products, raise funding
- [x] **Save/load** — Threaded auto-save, JSON serialization, continue from main menu
- [x] **Scene management** — Preloaded scene cache, deferred transitions, signal cleanup (mobile-optimized)
- [x] **Template engine** — {variable} substitution in event text with per-event variations (Classic Mode / Tier 1)

**Phase 2 — Systems Depth (IN PROGRESS):**
- [ ] **Employee sorting/filtering** — Sort and filter employees by role, skill level, morale, assignment on the People screen
- [x] **Fundraising** — VC meetings, term sheets, dilution calc, board seats, named VC firms with industry preferences
- [x] **Events (41 total)** — 41 events across 5 categories (people, product, money, market, culture) with 2-3 variations each
- [x] **Event resolution UI** — Modal popup with choices, effects applied, outcome text with variations
- [x] **Hiring pipeline** — Post job ($5K) → candidates with hidden stats → interview to reveal → offer/reject, runway warnings
- [ ] **Deep interviews system** — Assign a team member to conduct the interview instead of free-peek:
  - **Who interviews matters:** VP has high accuracy at reading candidates but costs the most time/resources; Director is solid but less accurate; Manager is average; Engineer is cheap but quality depends on their people skill stat
  - **Interviewer skill affects reveal:** High people-skill interviewer reveals true stats more accurately; low people-skill may misjudge (show inflated or deflated stats with a margin of error)
  - **Time/resource cost:** Senior interviewers tied up for a quarter tick can't do their normal work output that quarter (opportunity cost)
  - **Culture fit detection:** Only interviewers with high culture-fit themselves can reliably assess a candidate's culture fit — otherwise it shows as "???"
  - **Interview feedback flavor text:** Each interviewer gives a short written assessment that reflects their own biases and accuracy
- [ ] **Specific features to build** — Pick from feature list instead of just accumulating progress
- [ ] **Market shifts** — Economy state changes (bull/bear), affects fundraising and hiring
- [ ] **News ticker** — 150+ headline templates shown each quarter
- [ ] **Employee bios** — 200+ bio templates with personality tags
- [x] **Quarterly report** — 5-bullet narrative summary after each quarter advance (revenue, cash, team, product, users)
- [ ] **All 4 Software company types** — SaaS, Consumer, Marketplace, Dev Tools with unique mechanics
- [x] **Win conditions** — IPO ($100M+ ARR & 100K users), acquisition (accept event), sustainable (4Q profit after Y3), unicorn ($1B val) + victory screen
- [x] **CEO background & skills** — 4 founder archetypes (Engineer/Finance/Recruiter/Hustler) with stats affecting gameplay:
  - **Engineer** — Can personally contribute to product (features, bugs, infra). Weaker at fundraising and BD. Interviews are decent for technical roles, weaker for business roles
  - **Finance** — Better fundraising outcomes (higher valuations, lower dilution). Better at managing burn rate (cost events have smaller penalties). Weaker at product decisions
  - **Recruiter/People** — Best interviewer in the company. Hiring pipeline moves faster, better culture-fit reads. Can spot flight-risk employees early. Weaker at product and finance
  - **Business/Sales** — Better at BD deals, partnership events, and reputation. Revenue grows faster from deals. Weaker at technical product decisions
  - **Custom** — Distribute a limited pool of trait points (e.g., 20 points across 4 stats, each 1-10). Player designs their own founder. Can't max everything — real tradeoffs required
  - **God Mode** — Unlockable after first win (or cheat code). All stats maxed. For fun/sandbox, excluded from leaderboard/achievements
  - CEO has their own stats (technical, finance, people, business — each 1-10) that affect event outcomes, interview quality, VC negotiations, and product contributions
  - CEO can "level up" skills slowly through choices (picking the finance option in events nudges finance skill up)
- [ ] **Founder burnout** — CEO morale as a loss condition (ties into CEO having their own stress/energy meter)
- [ ] **Board takeover** — Miss VC targets repeatedly → game over
- [ ] **Employee personalities** — Each employee has 1-2 personality traits (e.g., Perfectionist, Team Player, Lone Wolf, Mentor, Ambitious, Laid-back) that affect:
  - How they interact with other employees (conflicts, synergies)
  - Their response to events (a Perfectionist hates shipping buggy features, an Ambitious employee wants promotions faster)
  - Interview accuracy (a good read depends on interviewer personality matching)
  - Team composition bonuses/penalties (all Lone Wolves = no collaboration bonus; mix of Mentors + Juniors = faster skill growth)
- [ ] **Employee aging & retirement** — Employees have ages; between 60-80 they may retire depending on:
  - Wealth accumulated (high salary over many years → earlier retirement)
  - Loyalty to the company (long tenure, high morale → stays longer)
  - Passion for the work (engaged employees with meaningful assignments delay retirement)
  - Retirement triggers a farewell event with potential knowledge-transfer bonuses if planned
- [ ] **Executive poaching system** — Attempt to recruit named executives from competitor companies:
  - Browse competitor org charts and target specific C-suite/VP-level talent with known elite skills
  - Poached execs are expensive but a guaranteed quality hire — no interview RNG
  - Risk of getting caught: competitor may file a lawsuit (cash penalty, reputation hit, legal fees)
  - Probability of getting caught scales with target's seniority and competitor's size
  - Successful poaches weaken the competitor and trigger retaliatory events
  - Non-compete clauses: some execs can't work in the same focus area for 1-2 quarters after joining

**Phase 3 — Polish & Balance (TODO):**
- [ ] **UI overhaul** — Dark theme, PGM3-style cards, clean typography, Godot Theme resource
- [ ] **Charts and graphs** — Revenue over time, user growth, morale trends
- [ ] **Employee detail view** — History, development arc, full stats
- [ ] **Difficulty tuning** — Balance sandbox/normal/hardcore across 10+ test runs
- [ ] **Tutorial** — Guided first quarter
- [ ] **Sound effects** — Minimal UI sounds (optional)
- [ ] **Visual office/garage scene** — Animated character sprites for employees in the workspace (garage → office → campus progression)
- [ ] **Time progression options** — Real-time or monthly-tick mode with speed controls (1x, 2x, 4x, pause) as alternative to quarterly turns

**Phase 4 — Content & Replayability (TODO):**
- [ ] **Silicon Valley (show) character pack** — Parody versions of the show's cast as recruitable/encounter-able characters, each with specific skills and personalities that match their TV counterparts:
  - Erlich Bachman parody — loudmouth incubator founder, high business/low technical, may demand office space in your garage
  - Gilfoyle parody — elite systems engineer, abrasive personality, loyal if you earn respect, clashes with certain teammates
  - Dinesh parody — solid engineer who craves validation, competitive with peers, morale drops if overshadowed
  - Jared parody — operations savant, absurdly loyal, keeps team morale high, mysterious dark backstory flavor text
  - Gavin Belson parody — competitor CEO who may poach your people or make acquisition offers, grandiose event dialogue
  - Monica parody — VC partner contact who gives better fundraising intel and friendlier term sheets
  - Big Head parody — low skill but incredibly lucky, stumbles into success, cheap to hire but unpredictable output
  - Each character triggers unique events and dialogue when on your team or encountered
- [ ] **Expand competitor roster** — Add more parody companies per category; flesh out each with multiple product lines, unique behaviors, and market moves (acquisitions, pivots, IPOs)
- [ ] **Competitor product depth** — Each major competitor can have multiple products (e.g., Googlr has search, cloud, ads, hardware) that affect different market segments
- [ ] **Community mod packs** — Ship a companion "real names" JSON; build a simple import flow (paste URL or pick file) for user-created competitor packs
- [ ] **Scenario packs** — "Dot-Com Boom", "AI Gold Rush", "Pandemic Pivot", etc. (JSON configs)
- [ ] **Achievements** — Track across runs
- [ ] **Postmortem screen** — Timeline of key decisions, shareable
- [ ] **Seed system** — Share seeds for specific market conditions

**Phase 5 — Ship (TODO):**
- [ ] **App Store / Play Store assets** — Screenshots, description, icon
- [ ] **TestFlight / internal beta** — 10-20 testers
- [ ] **Final bug fixes**
- [ ] **Submit**

**Post-Launch — AI Narrative (TODO):**
- [ ] **Classic Mode content** — Hit all content quantity targets (50 events, 200 bios, 150 headlines)
- [ ] **Dynamic Mode (v1.2)** — On-device LLM (llama.cpp GDExtension), model download flow, fallback system
- [ ] **Online Mode (v1.3)** — Cloud API proxy, Claude Haiku integration, rate limiting

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
