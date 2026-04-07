# Venture — Roadmap & Development Guide

**Goal:** Nothing → shipped game in 13 weeks. Work through phases sequentially; each one should be playable before starting the next.

---

## Current Priority Override (Spring 2026)

For the active execution plan, use `docs/current-execution-path.md`.

Right now, the smartest path is:
- Quality and stability first
- Balance validation second
- Real-device readiness gates third
- Internal mobile beta after gates pass

This temporarily takes priority over large net-new scope until the first phone beta is stable.

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
- [x] **Stage-aware responsibilities** — Early teams behave cross-functionally (shared hats + partial feature support), while growth/scale runs require dedicated ownership across Bugs/Tech Debt/Infra/R&D to avoid hidden operational drag
- [x] **Role-mesh bonuses** — Balanced lane coverage now creates explicit cross-functional synergy (faster cleaner shipping, stronger reliability/retention, reduced operational pressure), so every assignment can move core outcomes
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
- [x] **Employee sorting/filtering** — Sort and filter employees by name, skill, morale, salary, assignment on the People screen
- [x] **Fundraising** — VC meetings, term sheets, dilution calc, board seats, named VC firms with industry preferences
- [x] **Events (41 total)** — 41 events across 5 categories (people, product, money, market, culture) with 2-3 variations each
- [x] **Event resolution UI** — Modal popup with choices, effects applied, outcome text with variations
- [x] **Hiring pipeline** — Post job ($5K) → candidates with hidden stats → interview to reveal → offer/reject, runway warnings
- [x] **Salary negotiation** — One-shot "Negotiate −15%" button per candidate; low-fit candidates may walk if pushed
- [x] **Specialty match system** — `EmployeeData.specialty_mult()` drives real productivity bonuses (0.9×–1.4×) based on role, assignment, and company type; "⚡ Great fit / ✓ Good fit" badges shown on hire and team cards
- [x] **Feature build speed tuned** — Progress multiplier increased 3× so features complete in 1–4 quarters with a small team; more people scale linearly
- [x] **Feature ETA display** — Product screen shows estimated quarters to completion, engineer count, and specialty-fit summary; updates every refresh
- [x] **Feature shipped celebration** — Colour-coded banner (quality-tinted) fades in on Product screen and Dashboard when a feature ships; `feature_shipped` signal on GameState
- [x] **Quarter-over-quarter deltas** — Cash, Revenue, Burn Rate show `+/- $X vs last Q` in green/red below each stat
- [x] **Milestone roadmap** — Visual progress strip on Product screen toward next user count, features-shipped, and revenue targets
- [x] **Nav tabs to top** — People / Product / Finances / Market row repositioned to top of dashboard in `_ready()`
- [x] **Valuation-based event pacing** — Max 1 event/quarter under $500K valuation, 2 under $2M, 3 above; event context now includes `valuation`, `features_shipped`, `revenue`
- [x] **New game UX** — Consumer App default + "★ Recommended" badge; plain-English descriptions per company type and difficulty; difficulty description updates live
- [x] **Preset scenario ladder** — New game now supports bootstrap + mid/large-company starts (`Garage`, `Accelerator`, `Spinoff`, `VC-Backed`, `Growth Operator`, `Scale Chief`) for players who want different company scale entry points
- [x] **Employee hire badge** — Pop-in "Welcome to the Team" modal immediately after hiring; shows avatar, name, title, Skill/Morale/Speed stats, employee number, and hire date; spring scale-in animation; transitions to assignment prompt
- [x] **Visual asset set** — 8 Pixar-inspired employee avatars (deterministic hash assignment), 4 office banners (garage → co-working → small office → HQ), 4 product mockup illustrations per company type, 5 assignment-category icons, app icon; all loaded dynamically and displayed on relevant screens
- [x] **Deep interviews system** — Candidate interviews now require picking an interviewer (Founder / VP / Director / Manager / Engineer tiers):
  - **Who interviews matters:** Higher-tier interviewers provide better read accuracy but cost more and can be tied up for 1-2 quarters
  - **Interviewer skill affects reveal:** Estimated stats include error margins based on interviewer quality
  - **Time/resource cost:** Interviewer lock consumes their work output during lock quarters (opportunity cost in simulation)
  - **Culture fit detection:** Culture estimate shows as `???` unless interviewer people-skill is strong enough
  - **Interview feedback flavor text:** Cards include a short natural-language recommendation with confidence level
- [x] **Specific features to build** — Player chooses from a company-type-specific feature tree (10 features per type) with prerequisites, costs, and gameplay effects
- [x] **Market shifts** — Economy state transitions (bull/neutral/bear), affects user growth, churn, fundraising, and valuation; indicator on dashboard
- [x] **News ticker** — 67 contextual headline templates shown on dashboard each quarter, filtered by economy/users/company
- [~] **Product niche / what you're building** — New game now supports JSON-driven niche selection per company type (`niches.json`) with growth/churn/revenue modifiers, niche-aware event/headline weighting, and niche-biased competitor seeding; fully bespoke niche event packs are still pending:
  - **SaaS:** CRM, Project Management, HR Platform, Analytics Tool, Accounting, Email Marketing, Helpdesk, etc.
  - **Consumer:** Social Media, Dating App, Photo/Video, Music Streaming, Fitness Tracker, Messaging, Mobile Game, Utility App, etc.
  - **Marketplace:** E-commerce, Gig Economy, Food Delivery, Real Estate, Freelancer Platform, Rental, etc.
  - **Dev Tools:** IDE/Editor, CI/CD, Cloud Hosting, Monitoring, API Gateway, Database-as-a-Service, etc.
  - Each niche gets: a short flavor description, niche-specific competitors, tailored events, a starting user acquisition strategy, and unique headline templates
  - Niches within the same company type share the core growth curves and feature trees but get bonus modifiers (e.g., mobile games have spikier user growth but higher churn; CRMs grow slow but retain well)
  - Some niches are easier than others — utility apps are simpler to launch, while competing in OS/cloud is brutal but has massive upside
  - Future DLC types (AI, Gaming, Hardware, Platform/OS, Autonomous Mobility) each get their own niche lists
  - Modders can add custom niches via JSON
- [x] **Early game economy revamp** — Garage start cash raised to $60K (was $20K); accelerator to $150K; organic user growth doubled to 20/quarter; all 4 revenue model rates increased (SaaS 6% conversion/$28 ARPU, Consumer 0.025 CPM/4% premium, Marketplace $65 GMV/user, DevTools 1200 calls/$0.0012); salary floors trimmed (Junior now $12K-$20K/Q); contractor/intern employment types and office tier tiers remain future scope
- [x] **Employee bios** — 72 bio strings across 6 personality types + seniority prefixes in `bios.json`; `HiringEngine._pick_bio()` assigns on candidate generation; bio + age shown in employee detail view
- [x] **Quarterly report** — 6+ bullet narrative summary after each quarter advance (revenue, cash, team, product, users, economy, hosting + situational stress/board notes)
- [x] **All 4 Software company types** — SaaS, Consumer, Marketplace, Dev Tools each have unique growth curves, churn patterns, key metrics, feature trees (10 features each), and event filtering
- [x] **Win conditions** — IPO ($100M+ ARR & 100K users), acquisition (accept event), sustainable (6Q profit + scale checks after Y5), unicorn ($1B val) + victory screen
- [x] **CEO background & skills** — 4 founder archetypes (Engineer/Finance/Recruiter/Hustler) with stats affecting gameplay:
  - **Engineer** — Can personally contribute to product (features, bugs, infra). Weaker at fundraising and BD. Interviews are decent for technical roles, weaker for business roles
  - **Finance** — Better fundraising outcomes (higher valuations, lower dilution). Better at managing burn rate (cost events have smaller penalties). Weaker at product decisions
  - **Recruiter/People** — Best interviewer in the company. Hiring pipeline moves faster, better culture-fit reads. Can spot flight-risk employees early. Weaker at product and finance
  - **Business/Sales** — Better at BD deals, partnership events, and reputation. Revenue grows faster from deals. Weaker at technical product decisions
  - **Custom** — Distribute a limited pool of trait points (e.g., 20 points across 4 stats, each 1-10). Player designs their own founder. Can't max everything — real tradeoffs required
  - **God Mode** — Unlockable after first win (or cheat code). All stats maxed. For fun/sandbox, excluded from leaderboard/achievements
  - CEO has their own stats (technical, finance, people, business — each 1-10) that affect event outcomes, interview quality, VC negotiations, and product contributions
  - CEO can "level up" skills slowly through choices (picking the finance option in events nudges finance skill up)
- [x] **Founder burnout** — Founder energy (0-100) drains from stress, recovers from wins; burnout at zero = game over; displayed on dashboard
- [x] **Board takeover** — Board patience tracked for funded companies; miss growth targets → patience drops; zero patience = replaced as CEO; displayed on finance screen
- [~] **Employee personalities** — Each employee now has one trait (Steady/Ambitious/Perfectionist/Team Player/Mentor/Adaptable) that affects output, morale dynamics, and growth behavior; team-composition collaboration/morale effects are now integrated, while deeper personality-authored event branches are still pending:
  - How they interact with other employees (conflicts, synergies)
  - Their response to events (a Perfectionist hates shipping buggy features, an Ambitious employee wants promotions faster)
  - Interview accuracy (a good read depends on interviewer personality matching)
  - Team composition bonuses/penalties (all Lone Wolves = no collaboration bonus; mix of Mentors + Juniors = faster skill growth)
- [x] **Employee aging & retirement** — Employees have ages (Junior: 21-28, Senior: 40-62, Principal: 40-62); `retirement_check()` on `EmployeeData` uses probabilistic curve (60-80 range, 3%-25% chance); `SimulationEngine._age_employees()` increments age at Q4; retirement events logged separately from voluntary quits in `_process_employee_turnover()`
- [ ] **Executive poaching system** — Attempt to recruit named executives from competitor companies:
  - Browse competitor org charts and target specific C-suite/VP-level talent with known elite skills
  - Poached execs are expensive but a guaranteed quality hire — no interview RNG
  - Risk of getting caught: competitor may file a lawsuit (cash penalty, reputation hit, legal fees)
  - Probability of getting caught scales with target's seniority and competitor's size
  - Successful poaches weaken the competitor and trigger retaliatory events
  - Non-compete clauses: some execs can't work in the same focus area for 1-2 quarters after joining

- [ ] **Acqui-hire / Big company poaches you** — Mid-to-late game, large companies can approach your startup:
  - Triggered by milestone thresholds (user count, revenue, product quality) and some randomness
  - Big tech parodies (Goople, Mapple, Amacon, etc.) offer to buy your company or recruit you personally
  - Player choices: accept the deal (game ends with an acquisition ending), negotiate for more, or reject to keep building
  - Rejection can boost reputation ("turned down a Goople offer") and trigger press coverage
  - If you accept, payout depends on your metrics — could be a small talent grab or a massive buyout
  - Acqui-hire offers tend to be lower but come earlier; full acquisition offers come when you're bigger
  - Some offers come with strings: your team has to relocate, or you lose the company name, or key employees refuse to transfer
  - Risk: if you reject too many times, the big company may invest in a competitor instead

- [~] **News agency feature pieces** — 3 press/media events added to `events.json` (`press_feature_profile`, `press_negative_hit_piece`, `press_acquisition_rumor`) with reputation/morale effects; dedicated outlet personas (TekCrunch, Bloomburg, The Informant), investigative-piece mechanic, and reader-reaction headline variants are still pending

- [ ] **Stock market (post-IPO endgame)** — After IPO win condition, the game continues with a live stock price:
  - Stock price fluctuates each quarter based on revenue growth, user growth, profitability, economy state, and random market sentiment
  - Competitor stocks also visible (if they've IPO'd) for context
  - **Player actions:** Stock buybacks (spend cash to boost price/EPS), secondary share offerings (dilute to raise more cash), stock splits (cosmetic milestone), dividend announcements (reward shareholders, boosts sentiment)
  - Stock crashes possible from bad quarters, scandals (events), or bear markets
  - New post-IPO win conditions: reach a target market cap, join a stock index (parody S&P 500), or become the most valuable company in your sector
  - Analyst ratings (buy/hold/sell) shown each quarter with brief commentary
  - Quarterly earnings calls: choose how to present results (optimistic spin vs. honest vs. sandbagging) — affects stock price and board sentiment
- [x] **World & foreign policy events** — 12 new macro events added to `world_events.json` (global tariff shock, data privacy regulation wave, geopolitical instability, antitrust scrutiny, global recession signal, currency volatility, AI regulation uncertainty, supply chain normalization, interest rate cut cycle, big tech layoff wave, platform policy crackdown, and more); all use validated `fundraise_amount_mult` key; economy BULL/BEAR/NEUTRAL coupling and economy-state-influenced rolling are still handled by `WorldEventEngine`

- [ ] **Corporate Ventures program (mid-to-late game)** — Unlocks at $100M+ valuation or after Series B:
  - Start a CVC arm — allocate a quarterly budget from company cash to invest in AI-generated mini-startups
  - Each startup has a name, sector, team quality, product idea, and growth trajectory
  - Player picks which startups to fund (2-4 available per quarter), sets investment amount
  - Funded startups progress each quarter: some grow, some stall, some fail entirely
  - Successful portfolio companies can be: acquired (absorb their team + product into your company), taken to exit (cash return on investment, 2-10x), or kept as strategic partners (passive bonuses like user growth, tech, or reputation)
  - Failed investments are just lost money — the VC life
  - Portfolio companies in your sector give strategic synergy bonuses (e.g., investing in a data company while you're SaaS improves your product metrics)
  - Risk: if you over-invest and your core business suffers, the board gets angry (ties into board patience)
  - Leaderboard tracks your CVC returns alongside your main company performance

**Phase 3 — Polish & Balance (TODO):**
- [~] **UI overhaul** — Color-coded progress bars (green/gold/red via `_tint_bar()`), morale-colored 3px left borders on employee cards, stress warning badges (⚠ High stress / ⚠ Burnout risk), color-coded bugs/users/churn labels; Godot Theme resource and full typography pass still pending
- [x] **Turn-change clarity polish** — Dashboard now shows a compact "Last quarter" momentum strip (cash/revenue/users/valuation), explicit event-count + resolve-state guidance, a lightweight quarter-entry toast, a persistent "Next best action" hint, and a richer quarter transition wipe with SFX hooks/fallback synthesis.
- [x] **Finance decision guidance** — Finances now include quarter-delta context, a natural-language "Next best move", and a new driver-level drill-down summary (`Driver read`) that explains quarter-over-quarter cash movement from revenue and core cost buckets.
- [x] **Hosting economics + reliability** — Quarter simulation now models hosting demand/capacity lanes (web/cache/data), plan-based costs (Managed Cloud/Hybrid/In-house), overage costs, reliability incident pressure, and explicit player-facing capacity actions (lane upgrades + optimization) via Logistics. It now also includes workload-aware pressure profiling (AI/ML, streaming, marketplace, API/realtime) so data-center-heavy runs surface naturally from what you build.
- [x] **Charts and graphs** — `TrendChart` fully rewritten to 4-series named API with colored legend dots, last-value endpoint markers, and normalized multi-series overlay; Finance screen now plots Cash (green), Revenue (blue), Burn Rate (red), Users (gold) and Valuation (purple), Team (light blue), Morale (green); deeper drill-down analytics still pending
- [x] **Employee detail view** — Added dedicated employee profile screen with history timeline + trajectory chart + role/trait metadata
- [~] **Difficulty tuning** — Backend knobs now tune churn/competitor pressure, fundraising thresholds/offer sizes, and event pressure by difficulty; added `docs/difficulty-playtest-matrix.md` for structured 12-run validation, but full empirical pass is still pending
- [x] **Tutorial** — Guided first-quarter overlay implemented (`TutorialManager`) with step persistence, auto-advance triggers, skip, and replay from Settings
- [x] **Sound effects** — `SfxPlayer` autoload (`src/autoload/sfx_player.gd`) with PCM synthesis via `AudioStreamGenerator`; 6 named sounds: `hire`, `feature_ship`, `button_tap`, `event_popup`, `fire`, `retire`; registered in `project.godot`; wired into hire badge, fire button, event popup, and feature ship celebration
- [ ] **Dynamic org structures (large companies)** — Introduce team pods / function leads once company reaches scale thresholds, with clearer inter-team mesh bonuses and delegation tradeoffs
- [~] **Visual office/garage scene** — Static office banner images integrated for all 4 upgrade levels; animated character sprites in the workspace scene are still outstanding
- [~] **Office worker ambient animation** — Dashboard office banner now uses desk-aware pseudo-sprite workers (head/body badges), monitor+desk placement, and office customization states (per office tier + company accent); fully custom animated sprite art pipeline is still outstanding.
- [~] **Product visual prototype lab** — Product screen now includes a data-driven `Prototype Concept` switcher backed by `src/data/product_preview_prototypes.json` so new concept ideas can be added without code changes; concept-specific art variants and per-concept layout overrides are still pending
- [ ] **Time progression options** — Real-time or monthly-tick mode with speed controls (1x, 2x, 4x, pause) as alternative to quarterly turns
- [ ] **Hybrid real-time ops monetization experiment (player-first)** — Evaluate an optional real-time operations layer (timers that scale with company maturity) while keeping core quarter strategy decisions intact. Acceleration should come from earned tokens + optional rewarded ads, with premium focused on ad removal/QoL boosts rather than pay-to-win stat advantages. Validate only through soft-launch retention + sentiment data before broad rollout.
- [x] **Persistence hardening** — Save files now use checksum-enforced wrapper + strict validation + `.bak` fallback recovery; corrupted primary save auto-recovers from backup when available
- [x] **Storage safety limits** — Size limits for save/settings payloads and clamp/sanitize pass during deserialize to guard against malformed or tampered data
- [~] **Free vs paid foundation** — Free-tier gate + paywall + premium flags + restore path + save-slot entitlement gating are wired; gameplay branch currently keeps monetization temp-disabled behind an explicit stability-first guard until core QA signoff, and final store plugin QA on physical iOS/Android builds remains pending

#### Animation Roadmap (Now → Soon → Later)

**Now (done):**
- [x] **Tween-based product visual animations** — Ken Burns slow zoom (1.0→1.06, 13-second loop) on revealed feed & recommendation thumbnails; skeleton shimmer sweep on in-progress/preview cards (white strip loops left→right inside the clip boundary, killed on feature ship); phase-offset scale pulses on story bubbles (each bubble breathes 1.0→1.10 on its own 2.6-second cycle with 0.5s stagger). No new assets required — all driven by Godot's Tween system on static PNGs.
- [x] **Consumer streaming art pack** — 12 original generated images (brand badge, profile avatar, 3 feed thumbnails, 3 "For You" rec thumbnails, 4 story tiles) integrated into the live product visual via `_img_card()`, `_img_bubble()`, `_img_icon()` helpers with graceful solid-color fallbacks.
- [x] **Prototype concept switcher foundation** — Product screen now includes a `Prototype Concept` picker that maps ideas to visual preview modes from JSON (`src/data/product_preview_prototypes.json`), so future concept ideas can be plugged in quickly during polish sessions.
- [x] **Quarterly advance transition animation + SFX** — Dashboard now runs a richer full-screen transition (label + sweep + eased fade) when advancing a quarter, with audio hooks for asset-based whoosh/chime and synthesized fallback tones when SFX files are not present yet.

**Soon (next sprint):**
- [ ] **Kenney character sprite integration** — Download the free [Kenney Character Pack](https://kenney.nl/assets/toon-characters-1) (CC0, no attribution required). Wire up `AnimatedSprite2D` nodes for idle/walk/sit cycles. Display employees as animated sprites at their desks in the office scene, matching their current assignment (Features = typing, Bugs = looking worried, R&D = reading). Office scene upgrades (garage → co-working → HQ) swap the background banner and add more desk slots.
- [x] **Feature-ship confetti burst** — `GPUParticles2D` + `ParticleProcessMaterial` created programmatically in `product_overview.gd`; fires quality-tinted confetti (green/gold/red) on feature ship with `SfxPlayer.play("feature_ship")`; gradient built via `Gradient` API — no scene editor required.

**Later (post-alpha):**
- [ ] **Custom sprite art** — Commission or generate a consistent character sprite sheet once the game design is locked and company types are final. Replace the Kenney placeholders. Art style should match the Pixar-inspired employee avatars already in the hire badge.
- [ ] **AnimationPlayer sequences** — Richer multi-step office scenes: employees look up and react to events, celebrate shipped features, droop during low morale, etc. Requires the custom sprite sheets above.
- [ ] **Animated product mockup (beyond Tweens)** — For a future "showcase mode" trailer, pre-render the product visual transitions as a short video clip to embed in App Store screenshots.

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
- [x] **Pop-culture parody reference pack** — Expanded subtle startup-media parody layer across `src/data/events.json`, `src/data/headlines.json`, and `src/data/competitors.json` (plus world-event references) while keeping text legally safe and quote-free.
- [x] **Grounded world-events layer (historical + current-event inspired)** — `WorldEventEngine` + `world_events.json` has 26 macro events total (14 original + 12 new: global tariff shock, data privacy regulation, geopolitical instability, antitrust scrutiny wave, global recession signal, currency volatility, AI regulation uncertainty, supply chain normalization, interest rate cut cycle, big tech layoff wave, platform policy crackdown); all effect keys validated by smoke test; deeper economy-state coupling still pending.
- [x] **Reference tone + safety guardrails** — Added `docs/reference-tone-guardrails.md` with practical writing rules (neutral tone, no real-person defamation, no copyrighted dialogue, no graphic conflict framing) for future parody/event content.
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

### v1.6 — DLC #5: Autonomous Mobility (Autonomous Vehicle Path)

- [ ] **Autonomy stack management** — Track perception/planning quality, disengagement risk, and safety score over time
- [ ] **Compute + edge infra layer** — Add data-center + edge-node capacity/cost loops tied to fleet growth and simulation demand
- [ ] **Regulatory expansion loop** — City permits, safety audits, and rollout pacing decisions per market
- [ ] **2 mobility company archetypes** — Robotaxi Network and Autonomous Logistics
- [ ] **Mobility specialties** — Perception Engineer, Mapping Ops, Fleet Reliability, Safety Operations
- [ ] **35 mobility-specific events** — Safety incidents, weather disruptions, map drift, recall pressure, competitor pilots
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
