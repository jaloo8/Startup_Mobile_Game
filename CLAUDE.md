# VENTURE — Claude Code Project Bible

**This file is read at the start of every Claude Code session. It is the definitive reference for working on this project. Keep it up to date.**

---

## 1. QUALITY RULES (Non-Negotiable)

These exist because previous sessions skimmed instead of reading, missed items, and delivered incomplete work. These rules prevent that.

1. **Read before summarizing.** When asked to review, audit, or find things in files/transcripts — read EVERY line. Do not skim headers. Do not summarize from memory. Actually open the file, read it start to finish, and report what you found. If a file is too long, read it in chunks. Never claim you "looked through everything" unless you literally did.

2. **Verify your own work.** After completing any task, cross-check the output against the source material. If you added items from a document, re-read that document and confirm nothing was skipped. If you wrote code, re-read the requirements and confirm every one is addressed.

3. **Show receipts.** When the user asks "did you get everything?", cite specific line numbers, message numbers, or section headers — not vague assurances. If you can't cite the source, you didn't actually check it.

4. **No filler work.** Don't pad responses with obvious items to make it look thorough while missing the subtle ones. The hard-to-find items buried in paragraphs matter more than the ones in headers.

5. **Say what you didn't do.** If you ran out of context, hit a limit, or skipped something — say so explicitly rather than pretending you covered it.

6. **Quality by default.** Do not wait to be told to be thorough. The first pass should be the good pass. If a task requires reading a file, read the whole file. If it requires checking 10 things, check all 10 — not 7 with a note that "the rest look fine."

7. **Count and list.** When adding, removing, or changing multiple items, state the exact count and list each one. "I added 5 items" is accountable. "I added several items" is not.

---

## 2. PROJECT OVERVIEW

| Field | Value |
|-------|-------|
| **Game** | VENTURE — premium mobile startup management sim |
| **Engine** | Godot 4.6, GDScript, Forward Plus renderer |
| **Resolution** | 720×1280 portrait (mobile-first) |
| **Platforms** | iOS, Android (Steam future possibility) |
| **Studio** | Water Hazard Studios |
| **Contact** | Water.Hazard.Studios@gmail.com |
| **Monetization** | $2.99 premium unlock (free trial: 8 quarters / Year 2). DLC $2.99 each. |
| **Launch target** | Mid-May 2026 |
| **Test devices** | iPhone 14, Samsung Galaxy S20 Ultra, iPad Pro 11" |

**One-line pitch:** "Pocket GM 3, but for tech startups — a premium mobile management sim where you build a company from garage to IPO."

**Core fantasy:** You are the CEO/founder. You make every strategic decision — what to build, who to hire, when to raise money, when to pivot. The game simulates realistic consequences.

**Session length:** 10–20 minutes (one quarter per session, natural stopping points)
**Total game length:** 20–40 quarters (5–10 years of startup life per run)

---

## 3. CODEBASE ARCHITECTURE

### Directory Layout
```
startup_mobile_game/
├── src/
│   ├── autoload/          17 global singletons (see list below)
│   ├── models/            6 Resource-based data containers
│   ├── engine/            13 simulation/logic modules
│   ├── data/              13 JSON content files
│   └── ui/                15 screens + shared components
│       ├── achievements/    Achievement browser
│       ├── components/      Shared UI (event popup, glossary, charts, anim helpers, dev panel, pixel chars)
│       ├── dashboard/       Quarter dashboard (main game screen)
│       ├── finance/         Finance overview
│       ├── game_over/       Game over screen
│       ├── history/         Run history
│       ├── logistics/       Hosting/infrastructure
│       ├── main_menu/       Main menu
│       ├── market/          Market leaderboard
│       ├── people/          Employee list + detail
│       ├── product/         Product overview + mockup
│       ├── saves/           Save slot picker
│       ├── settings/        Settings
│       ├── setup/           New game setup
│       └── victory/         Victory screen
├── assets/                Art, audio, avatars, branding, fonts, icons, illustrations, office sprites
├── docs/                  16 design/reference documents
├── tools/                 3 Python dev tools
├── CLAUDE.md              THIS FILE
├── PRIVACY_POLICY.txt
├── TERMS_OF_SERVICE.txt
└── SUPPORT.txt
```

### File Counts
| Type | Count |
|------|-------|
| .gd (GDScript) | 60 |
| .tscn (Godot scenes) | 17 |
| .json (data) | 13 |
| .py (tools) | 3 |

### Autoload Singletons (17)
These are registered in `project.godot` under `[autoload]` and available globally:

| Singleton | File | Purpose |
|-----------|------|---------|
| GameState | `src/autoload/game_state.gd` | Central state management, save/load, new_game, advance_quarter |
| SceneLoader | `src/autoload/scene_loader.gd` | Scene transitions with safety timeout |
| ThemeManager | `src/autoload/theme_manager.gd` | UI color/font constants |
| AdManager | `src/autoload/ad_manager.gd` | Premium gating, IAP, `MONETIZATION_TEMP_DISABLED` flag |
| Analytics | `src/autoload/analytics.gd` | GameAnalytics SDK wrapper, consent-gated |
| TutorialManager | `src/autoload/tutorial_manager.gd` | 5-step tutorial overlay |
| SfxPlayer | `src/autoload/sfx_player.gd` | 22 synthesized sound effects |
| ToastManager | `src/autoload/toast_manager.gd` | Toast notification system |
| AchievementManager | `src/autoload/achievement_manager.gd` | 40 achievements, persistent cross-run tracking |
| CurrencyManager | `src/autoload/currency_manager.gd` | VC Chips currency |
| IdleEngine | `src/autoload/idle_engine.gd` | Offline income calculation |
| WorldEventEngine | `src/autoload/world_event_engine_bridge.gd` | Multi-quarter macro events |
| UITouchHelper | `src/autoload/ui_touch_helper_bridge.gd` | Touch target hardening |
| Glossary | `src/autoload/glossary.gd` | In-game term definitions |
| RunHistory | `src/autoload/run_history.gd` | Cross-run history tracking |
| PrestigeManager | `src/autoload/prestige_manager.gd` | Prestige/meta-progression |
| DailyBonus | `src/autoload/daily_bonus.gd` | Daily login bonus |

### Engine Systems (13)
| Engine | File | Purpose |
|--------|------|---------|
| SimulationEngine | `src/engine/simulation_engine.gd` | **Core:** 12-step quarterly simulation loop |
| HiringEngine | `src/engine/hiring_engine.gd` | Candidate generation, interview simulation |
| RevenueEngine | `src/engine/revenue_engine.gd` | Revenue calculation per company type |
| CompetitorAI | `src/engine/competitor_ai.gd` | AI competitor growth, funding, products |
| EventEngine | `src/engine/event_engine.gd` | Event selection, weighting, triggering |
| WorldEventEngine | `src/engine/world_event_engine.gd` | Multi-quarter macro cycles (recessions, booms) |
| FundraisingEngine | `src/engine/fundraising_engine.gd` | VC meetings, term sheets, dilution |
| ValuationEngine | `src/engine/valuation_engine.gd` | Company valuation calculation |
| ScoringEngine | `src/engine/scoring_engine.gd` | Founder Score (6-axis, letter grades S→F) |
| HeadlineEngine | `src/engine/headline_engine.gd` | News ticker headline generation |
| TemplateEngine | `src/engine/template_engine.gd` | {variable} substitution in narrative text |
| SynergyEngine | `src/engine/synergy_engine.gd` | Feature synergy bonuses |
| QuarterlyReport | `src/engine/quarterly_report.gd` | 6+ bullet narrative summary generation |

### Data Models (6)
| Model | File | Key Fields |
|-------|------|------------|
| CompanyData | `src/models/company_data.gd` | name, type, niche, cash, valuation, reputation, office_level |
| EmployeeData | `src/models/employee_data.gd` | name, skill, morale, stress, specialty, salary, assignment, personality |
| ProductData | `src/models/product_data.gd` | features, tech_debt, bugs, stability, ux_score, users |
| FinancialsData | `src/models/financials_data.gd` | cash, burn_rate, revenue, runway, funding_rounds |
| MarketData | `src/models/market_data.gd` | competitors, economy_state, market_trend |
| EventData | `src/models/event_data.gd` | id, title, category, choices, effects, trigger_conditions |

### JSON Data Files (13)
| File | Contents | Count |
|------|----------|-------|
| `events.json` | Narrative events with choices | ~50 |
| `world_events.json` | Multi-quarter macro events | 26 |
| `competitors.json` | AI competitor companies | 86 |
| `features.json` | Buildable product features | 40 (10 per type) |
| `feature_synergies.json` | Feature combo bonuses | varies |
| `headlines.json` | News ticker templates | 67+ |
| `bios.json` | Employee backstories | 72 |
| `names.json` | Name generation data | varies |
| `niches.json` | Market niches per company type | varies |
| `vcs.json` | VC firm data with preferences | varies |
| `achievements.json` | Achievement definitions | 40 |
| `glossary.json` | In-game term definitions | varies |
| `product_preview_prototypes.json` | Product mockup concepts | varies |

---

## 4. GAME DESIGN (Key Systems)

### Core Loop
```
1. INBOX — Read events, news, requests
2. PEOPLE — Hire, fire, promote, manage
3. PRODUCT — Allocate team to work items
4. MONEY — Revenue, costs, fundraise
5. STRATEGY — Marketing, partnerships, etc.
6. ADVANCE — Simulate quarter, see results
7. BOARD REVIEW — Quarterly scorecard
```
Player visits screens in any order, then hits "Advance Quarter." PGM3-style: do management, then sim forward.

### 4 Company Types (Software Path — v1.0)
| Type | Unique Mechanic | Key Metric | Revenue Model |
|------|----------------|------------|---------------|
| **SaaS B2B** | Sales Pipeline (Lead→Demo→Trial→Negotiation→Closed) | ARR, Net Revenue Retention | Subscription tiers (Free→Pro→Enterprise) |
| **Consumer App** | Virality Engine / K-factor | DAU, MAU, retention | Ads, premium subs, IAP |
| **Marketplace** | Two-Sided Growth (supply + demand chicken-and-egg) | GMV, take rate, liquidity | Transaction fees |
| **Dev Tools** | Developer Ecosystem (DX, docs, community) | API calls, SDK installs | Usage-based pricing |

### 3 Difficulty Modes
| Mode | Description |
|------|-------------|
| Sandbox | Extra starting cash, slower competitors, forgiving market. Learning mode. |
| Normal | Realistic startup economics. Tight budget, real competition. |
| Hardcore | Minimal runway, aggressive competitors, realistic failure rates. |

### 6 Starting Scenarios
Garage ($20K), Accelerator ($125K), Corporate Spinoff ($500K), VC-Backed ($2M), Growth Operator ($8M), Scale Chief ($30M)

### 4 Founder Archetypes
Engineer, Finance, Recruiter, Hustler — plus Custom (distribute 20 points) and God Mode (unlocked after first win).

### Win Conditions
- **IPO** — $100M+ ARR with profitability
- **Acquisition** — Accept a buyout offer
- **Sustainable Business** — 6 consecutive profitable quarters after Year 5
- **Unicorn** — $1B valuation

### Loss Conditions
- **Bankruptcy** — Cash hits zero, can't raise or cut
- **Dead Product** — Users drop to zero
- **Founder Burnout** — CEO energy hits zero
- **Board Takeover** — VC-funded, miss targets repeatedly

### Employee System
- **Attributes:** Skill (1-100), Morale (1-100), Stress, Salary, Specialty, Personality (6 types), Culture Fit
- **Dev Bible target attributes not yet implemented:** Speed (1-100), Growth Potential (Low/Med/High), Seniority promotion (Junior→Principal)
- **Personalities:** Steady, Ambitious, Perfectionist, Team Player, Mentor, Adaptable
- **9 Specialties (Dev Bible target):** Frontend, Backend, Mobile, Design, Data/ML, DevOps, Sales, Marketing, Operations
- **Hiring flow:** Post job ($5K) → Candidates → Interview (tiered: Founder/VP/Director/Manager/Engineer) → Offer → Negotiate → Onboard

### Product System
- **5 work lanes:** Features, Bug Fixes, Tech Debt, Infrastructure, R&D
- **Features:** Company-type-specific trees (10 per type), prerequisites, quality-tinted celebrations
- **Interactive phone mockup:** Data-driven visual that evolves as features ship. Tappable for "Product Demo" mechanic (+reputation).

### Finance System
- **Displayed:** Cash, Revenue, Burn Rate, Runway, Valuation, Deltas
- **Target (not yet displayed):** CAC, LTV, Gross Margin
- **Fundraising:** Named VCs with preferences, term sheets, dilution, board seats
- **Marketing:** Spend → user growth pathway with diminishing returns

### Event System
- 50+ events across people/product/money/market/culture categories
- 26 world events (multi-quarter macro cycles: recession, boom, tariffs, regulation)
- Economy states: Bull / Neutral / Bear
- 67+ news headline templates
- Events scale by company valuation (not raw quarter count)

### Competitor System
- 86 AI competitors in `competitors.json`
- Competitors grow users, improve products, raise funding
- Market leaderboard with tappable detail popups
- Pop-culture parody names (see `docs/reference-tone-guardrails.md`)

---

## 5. CONTENT TARGETS (from Dev Bible)

| Content Type | Current | Target | Gap |
|-------------|---------|--------|-----|
| Events | ~50 | 50+ (with 3-5 variations each) | Variations needed |
| World Events | 26 | 26+ | Met |
| Employee Bios | 72 | 200 | Need ~128 more |
| Headlines | 67+ | 150 | Need ~83 more |
| Competitors | 86 | 100+ | Need ~14 more |
| Achievements | 40 | 40 | Met |
| Features (per type) | 10 | 10 | Met |
| VC Pitch Dialogue Variations | 0 | 30+ | Not started |
| Quarterly Report Templates | ~1 | 20+ | Not started |
| Game Over Postmortem Templates | 0 | 10+ | Not started |
| Competitor Description Templates | 86 | 50+ | Met |

---

## 6. DLC ROADMAP (5 Paths)

| DLC | Name | Price | Company Types | Key Mechanics |
|-----|------|-------|---------------|---------------|
| Base | Software (v1.0) | $2.99 | SaaS, Consumer, Marketplace, Dev Tools | Sales pipeline, virality, two-sided growth, DX |
| #1 | "The Intelligence Age" (AI/ML) | $2.99 | AI SaaS/API, AI App, AI Research Lab | GPU/compute budget, model quality, hype cycles |
| #2 | "Silicon Dreams" (Hardware) | $2.99 | Consumer Electronics, Chip Design, Robotics | Manufacturing, supply chain, BOM, tape-out |
| #3 | "Press Start" (Gaming) | $2.99 | Indie Studio, AA Studio, Live Service/F2P | Game projects, review scores, wishlists, crunch |
| #4 | "The Platform Play" (OS/Platform) | $2.99 | Mobile/Desktop OS, Dev Platform/Cloud | Dev ecosystem, governance, network effects |
| #5 | "Autonomous Mobility" (AV) | $2.99 | TBD | Autonomy stack, compute/edge, regulatory |
| Bundle | "Venture: Complete Collection" | $12.99 | All of the above | ~25% savings |

**Architecture:** Core engine uses a PathModule pattern. Each DLC plugs in without modifying core code. Events are JSON, UI adapts per path.

---

## 7. DESIGN PRINCIPLES (User-Stated)

These are direct quotes/paraphrases from the user across all sessions. They are non-negotiable:

1. **"Technical enough for engineers, accessible for non-tech people"** — Both audiences matter equally
2. **"Quality over quantity"** — Polish over shipping fast. User said: "I don't mind pushing out our timeline"
3. **"Nothing AI-generated-sounding"** — All player-visible text must read naturally
4. **"Not over-engineered"** — Code and UI should be clean and simple
5. **"Disney-quality visuals, Apple-level UX"** — High bar for visual polish and usability
6. **"No copyright/trademark violations"** — Parody names only, see `docs/reference-tone-guardrails.md`
7. **"Iron-clad legal documents"** — Privacy policy, ToS must be bulletproof
8. **"Addictive and fun with subtle monetization"** — Not a cash grab, but should make money
9. **"Decisions over numbers"** — Every screen should ask the player to DECIDE something
10. **"Every quarter should have tension"** — No boring/empty turns
11. **"Make it feel like you're building a real product"** — The interactive phone mockup is central
12. **"Playable over perfect"** — A working game beats a beautiful screen with no logic
13. **"One system at a time"** — Don't build fundraising until hiring works
14. **"Steal from PGM3"** — UI patterns, session structure, "just one more season" hooks
15. **"Your life is content"** — Every frustrating thing about working in tech = potential game event
16. **"Keep sprites generic enough to avoid politics"** — Characters should not bring in outside politics
17. **"Review visuals for originality"** — Don't copy artwork from referenced games/media

---

## 8. INSPIRATION GAMES (User-Referenced)

| Game | What To Take | User Quote |
|------|-------------|------------|
| **Pocket GM 3** | Simple vs. detailed view toggle, role impact, UI patterns, session structure | "simple UI similar to PG3" |
| **Startup Company (Steam)** | Hosting fees, animated employees in office, building upgrades | "how the game startup company on steam has their gameplay" |
| **Project Hospital** | Management depth feel | "I also like how Project Hospital feels" |
| **Tiny Tower** | Simple sprite animations, idle progression | "simple animations/sprites similar to tiny tower" |
| **Cities: Skylines** | Real-time control model (considered but kept quarterly) | "think we should transition to real time?" |
| **Disney / Pixar** | Visual quality and charm | "animations and visuals are as good as disney" |
| **Apple** | UX friendliness standard | "as user friendly as apple devices" |

---

## 9. CODE STANDARDS & QUALITY

Full detail in `docs/coding-conventions.md` (285 lines). Key rules inlined here so they're never missed:

### GDScript Conventions
- Godot 4.6 style guide: `snake_case` functions/variables, `PascalCase` classes, `UPPER_SNAKE` constants
- `@onready` for node references, `%UniqueName` for scene-unique nodes
- File naming: `snake_case.gd`, `snake_case.tscn`, `snake_case.json`, `kebab-case.md`

### Scene Navigation (CRITICAL)
```gdscript
# ALWAYS use this:
SceneLoader.goto_scene("res://src/ui/dashboard/quarter_dashboard.tscn")

# NEVER use this — bypasses preload cache, cleanup hooks, and transition animations:
get_tree().change_scene_to_file("res://src/ui/dashboard/quarter_dashboard.tscn")
```

### Null Safety
Any code that runs during scene init or event callbacks must guard against uninitialized state:
```gdscript
if GameState.company == null or GameState.product == null:
    return
```
`GameState.company` and `GameState.product` are null between save deletion and next `new_game()`.

### State Hygiene
Static data (e.g., `EventEngine._cooldowns`) persists across scene reloads because engine scripts stay loaded. **Always clear caches in `GameState.new_game()`:**
```gdscript
EventEngine.reset_cooldowns()
```
If you add ANY new static/module-level cache to engine scripts, add a matching reset call in `new_game()`.

### Constants Over Magic Numbers
```gdscript
# Good — derived from data, won't drift:
clampi(office_level, 0, CompanyData.OFFICE_CAPACITY.size() - 1)

# Bad — hardcoded, breaks when office tiers are added:
clampi(office_level, 0, 3)
```

### Value Clamping
Always clamp gameplay values in `clamp_all()` methods and during deserialization (`_clamp_deserialized_values()`). Key ranges:
- `revenue_mult` → `[0.1, 5.0]`
- `office_level` → `[0, OFFICE_CAPACITY.size() - 1]`
- `competitor users` → growth cap per quarter (currently `10_000_000`)
- `morale`, `skill`, `stress` → `[0, 100]`

### Shared Logic — No Duplication
If the same calculation appears in multiple places, define it once as a `static func` on the engine class that owns it:
```gdscript
# In simulation_engine.gd
static func responsibility_stage(state) -> String:
    var count := state.employees.size()
    if count <= 6: return "early"
    if count <= 20: return "growth"
    return "scale"

# In other files — call, don't reimplement:
var stage := SimulationEngine.responsibility_stage(GameState)
```

### Feature Effects Pattern
Feature effects like `reputation_bonus` must NOT apply inline during `apply_feature_effects()` — that creates tight coupling. Accumulate into pending variables and drain at the call site:
```gdscript
var _pending_reputation_bonus: int = 0

func drain_pending_reputation_bonus() -> int:
    var bonus := _pending_reputation_bonus
    _pending_reputation_bonus = 0
    return bonus
```

### UI Layout Rules
- Use `ScrollContainer` → `MarginContainer` → `VBoxContainer` for variable-length content
- Top-level scene root: `Control` or `PanelContainer` anchored full-rect
- Touch targets: minimum 44px height, 48px preferred. Call `UITouchHelper.harden_tree(self)` in `_ready()`
- Never hardcode pixel positions — use anchors, size flags (`SIZE_EXPAND_FILL`), and containers
- Keep overlay/popup nodes as siblings of the scroll, not children (prevents layout fights)

### Animation Safety
- **NEVER** use `AnimHelper.fade_in(self)` in `_ready()` — this caused position-fighting bugs on 8 screens
- **DO** use `AnimHelper.stagger_list()`, `AnimHelper.pop_in()`, or `AnimHelper.fade_in()` on individual children
- Always call `AnimHelper` AFTER `UITouchHelper.harden_tree(self)` in `_ready()`

### Player-Visible Text
- Must sound natural, not AI-generated or over-engineered
- Use parody names for all real companies/people (see `docs/reference-tone-guardrails.md`)
- Concise: 1-2 sentence descriptions, 3-10 word titles
- Dry startup humor, boardroom/newsroom tone
- No internal file paths, code syntax, or model names in player-visible text
- Use plain English ("next quarter" not "simulation", "above 97%" not ">=97%")
- Version strings: always reference `GameState.GAME_VERSION`, never hardcode
- No partisan political framing

### Comment Style
- Write comments that explain **why**, not **what**
- Avoid narration (`# increment the counter`, `# return the value`)
- Use `## Section header` for class-level documentation blocks
- Mark visual placeholders with `# VISUAL_HOOK:` so art passes can find them

### Mobile-Specific Requirements
- Touch targets >= 46px (UITouchHelper enforces this)
- No horizontal scrolling
- Thumb-reachable primary actions
- Portrait mode only (720×1280)
- Safe area / notch awareness
- Debug prints gated behind `OS.is_debug_build()`

### Memory & Performance
- Free children properly: use `SceneLoader.free_children()` pattern or `queue_free()`
- Don't create nodes in tight loops without freeing them
- Use `load()` not `preload()` for large assets that aren't always needed
- Tween references: always check if previous tween exists before creating new ones
- Particle systems: use `GPUParticles2D` with `one_shot = true` and `queue_free()` on completion
- Object pooling for frequently created/destroyed nodes (e.g., floating number popups)
- Profile with Godot's built-in Profiler and Monitors for 60fps target on mid-range devices

### Save System
- Writes go through temp file + atomic rename + checksum wrapper
- Always write `.bak` before overwriting the primary save
- On load: verify checksum first; if corrupt, fall back to `.bak`
- History and event log are compacted (windowed) during serialization to keep payload bounded
- Deep-copy all data before async writes to avoid mutation during serialization
- Auto-save after each quarter advance
- Save data location (macOS): `~/Library/Application Support/Godot/app_userdata/Venture/`

---

## 10. DEBUGGING & TESTING

### After ANY Code Change
```bash
python3 tools/backend_smoke.py
```

### What the Smoke Test Validates (19 checks)
1. JSON structure for all 13 data files
2. Feature prerequisite integrity (no dangling references)
3. Visual preset ID coverage
4. Difficulty multiplier shape (sandbox > normal > hardcore for cash, reverse for churn)
5. Monetization stability gate (`MONETIZATION_TEMP_DISABLED = true`)
6. Runtime bridge wiring in `project.godot`
7. UI button/signal contracts (12 screens)
8. Scroll container layout contracts (6 screens)
9. Glossary near-duplicate detection
10. Niche-competitor coverage (every niche has tagged rivals)
11. Headline content quality (no broken dollar amounts)
12. Version constant presence and usage
13. Event cooldown reset wiring
14. History snapshot completeness
15. SceneLoader-only scene transitions (no rogue `change_scene_to_file`)
16. Event effect key validity (every choice with reward text has matching effect)
17. Event categories use canonical set: `people`, `product`, `money`, `market`, `culture`
18. World event effect key validation
19. Feature effect key validation

### Adding New Smoke Checks
When you fix a bug or add a new contract, add a matching validator to prevent regression:
1. Write a `validate_*` function returning `List[str]` of error messages
2. Call it in `main()`
3. Update the PASSED banner text

### Balance Testing
```bash
python3 tools/balance_sim.py
```
108-run automated matrix (4 types × 3 difficulties × 3 strategies × 3 seeds). Results in `docs/balance-sim-report.md`.

### Manual QA
See `docs/qa-smoke-checklist.md` (~30-40 min full run, ~15 min quick pass on starred items).

### Edge Case Testing
See `docs/dev-edge-case-test-matrix.md` (5 preset save slots):
- Slot 1: Consumer/Sandbox (baseline UX)
- Slot 2: SaaS/Hardcore (early-economy pressure)
- Slot 3: Marketplace/Normal (funding pressure)
- Slot 4: DevTools/Hardcore (mid-game scaling stress)
- Slot 5: Consumer/Normal (late-game reliability)

### Mobile QA (Section 23 of QA checklist)
- 23.1: Portrait lock
- 23.2: Touch targets >= 44pt
- 23.3: Android back button
- 23.4: Backgrounding/foregrounding
- 23.5: Kill and relaunch (auto-save recovery)
- 23.7-23.8: Small screen (iPhone SE) and large screen (iPad)
- 23.9: Notch/safe area
- 23.10: 60fps performance
- 23.14: Scroll touch behavior

### Event & Content Data Quality Checks
Before committing any content changes:
- Every event choice that promises a reward in its label/outcome text must have a matching effect key
- Event categories must use the canonical set: `people`, `product`, `money`, `market`, `culture` (not aliases like "finance")
- Headlines with dollar amounts must include the actual number
- Every niche ID in `niches.json` must have at least one competitor tagged with it
- Glossary keys must be unique case-insensitively

### How to Add New Content Safely

**New Event:**
1. Add to `src/data/events.json` with all required fields (`id`, `title`, `description`, `choices`, `category`, `weight`)
2. Ensure every choice has `effects` dict with valid keys
3. If niche-specific, add `"niches": ["niche_id"]`
4. Run `python3 tools/backend_smoke.py`

**New Feature:**
1. Add to relevant company type array in `src/data/features.json`
2. Include `id`, `name`, `cost`, `effects` (valid keys only)
3. If has prerequisites, verify they exist in the same type
4. If needs visual preset, add ID to `VISUAL_PRESET_FEATURES` in `product_overview.gd`
5. Run `python3 tools/backend_smoke.py`

**New Competitor:**
1. Add to `src/data/competitors.json` with `name`, `focus`, `size`, `tagline`
2. Tag relevant `niches` for coverage
3. Run `python3 tools/backend_smoke.py`

**New Niche:**
1. Add to relevant company type in `src/data/niches.json` with `id`, `name`, `description`, `modifiers`
2. Tag at least one competitor with the new niche ID
3. Run `python3 tools/backend_smoke.py`

**New World Event:**
1. Add to `src/data/world_events.json` with required fields
2. Effects must use keys from `WORLD_EVENT_EFFECT_KEYS`
3. Run `python3 tools/backend_smoke.py`

### Known Bug Patterns (Previously Fixed — Don't Reintroduce)

| Bug | Root Cause | Fix Pattern |
|-----|-----------|-------------|
| SceneLoader._transitioning stuck forever | No timeout on transition lock | Safety timeout added; never bypass |
| Position-fighting on screen load | `fade_in(self)` in `_ready()` fights container layout | Use `AnimHelper` on children only, never on root |
| Old run data in new game | Static caches not cleared | Add reset in `GameState.new_game()` for any new cache |
| Paywall accidentally granting access | `on_unlock` called in fallback | Fallback must call `on_cancel`, not `on_unlock` |
| Unbounded multiplier stacking | `revenue_mult` grows infinitely | Clamp in `apply_feature_effects()` and `clamp_all()` |
| Board patience never drops | Feature count checked as `> 0` instead of delta | Compare `feature_count()` to history snapshot |
| Duplicate glossary entries | Case-insensitive duplicates in JSON | Smoke test catches near-dupes |
| Missing effect on event choice | Label says "grant money" but no `cash` effect key | Smoke test validates label-to-effect consistency |
| 13 bare print() statements shipped | No gating on debug output | Gate behind `OS.is_debug_build()`, smoke test checks |
| Variant type inference warnings | Untyped variable initialized from Variant | Use explicit type annotations: `var x: int = dict.get("key", 0)` |

---

## 11. KEY FILES (Quick Reference)

### Balance Tuning
| What | Where |
|------|-------|
| Difficulty multipliers | `src/autoload/game_state.gd` lines ~118-143 (`DIFFICULTY_MULTS`) |
| Growth constants per company type | `src/engine/simulation_engine.gd` lines ~136-183 |
| Interview costs & difficulty multipliers | `src/ui/people/employee_list.gd` lines ~34-65 |
| Monetization toggle | `src/autoload/ad_manager.gd` line ~32 (`MONETIZATION_TEMP_DISABLED`) |
| IAP product ID | `src/autoload/ad_manager.gd` line ~30 |
| Marketing user multiplier | Search for `MARKETING_USER_MULT` |

### Legal
| What | Where |
|------|-------|
| Privacy Policy | `PRIVACY_POLICY.txt` (GDPR Art. 13, CCPA, COPPA) |
| Terms of Service | `TERMS_OF_SERVICE.txt` (16 sections) |
| Support | `SUPPORT.txt` |
| Tone guardrails | `docs/reference-tone-guardrails.md` |

### Documentation
| What | Where |
|------|-------|
| **Feature tracker (SOURCE OF TRUTH)** | `docs/complete-feature-tracker.md` (~350 items) |
| Game design doc | `docs/game-design.md` |
| Content schemas | `docs/content-schemas.md` |
| AI integration spec | `docs/ai-integration.md` |
| Monetization strategy | `docs/monetization.md` |
| Roadmap | `docs/roadmap.md` |
| Art asset brief | `docs/art-asset-brief.md` |
| QA checklist | `docs/qa-smoke-checklist.md` |
| Balance sim report | `docs/balance-sim-report.md` |
| Coding conventions | `docs/coding-conventions.md` |
| Difficulty matrix | `docs/difficulty-playtest-matrix.md` |
| Edge case tests | `docs/dev-edge-case-test-matrix.md` |
| Execution path | `docs/current-execution-path.md` |
| AI tech opportunities | `docs/AI_TECH_OPPORTUNITIES.md` |
| **Tier 1 launch punch list** | `docs/tier1-launch-punchlist.md` |
| **Builder slots + rush design** | `docs/design-builder-slots-rush.md` |
| **Cursor art prompt guide** | `docs/cursor-prompt-guide.md` |
| **Visual asset brief** | `docs/visual-asset-brief-v1.md` |

### Session History & Source Material
| What | Where |
|------|-------|
| Launch plan | `~/.claude/plans/synthetic-hugging-treehouse.md` |
| Dev Bible (full extracted) | `~/.claude/projects/-Users-jloo-Documents-GitHub-startup-mobile-game/2a6d5958-cbba-4fd9-ba3b-ddf957a71b6b/tool-results/benk16z0n.txt` |
| All human messages (full) | `~/.claude/projects/-Users-jloo-Documents-GitHub-startup-mobile-game/2a6d5958-cbba-4fd9-ba3b-ddf957a71b6b/tool-results/bmpzdydab.txt` |
| Memory files | `~/.claude/projects/-Users-jloo-Documents-GitHub-startup-mobile-game/memory/` (6 files) |
| Cursor S1 transcript | `~/.cursor/projects/Users-jloo-Documents-GitHub-startup-mobile-game/agent-transcripts/fcb354b8-.../fcb354b8-...jsonl` (97 human msgs) |
| Cursor S2 transcript | `~/.cursor/projects/Users-jloo-Documents-GitHub-startup-mobile-game/agent-transcripts/43c8c110-.../43c8c110-...jsonl` (142 human msgs) |

---

## 12. CURRENT STATUS (Update this section as work progresses)

**As of April 13, 2026:**

### What's Done (~220 items)
- Full core gameplay loop (quarterly simulation, 12-step engine)
- All 4 company types with unique growth curves and features
- Employee system (hire, fire, interview, assign, bios, avatars, detail view)
- Product system (features, ETA, synergies, interactive phone mockup)
- **Builder Slots system** — multi-slot parallel feature builds (1-4 slots)
- **Rush mechanics** — VC Chip rush (quarter skip + instant), ad rush (stacking diminishing returns), crunch mode (free rush with morale cost)
- **Feature upgrade tiers** — Scaled/Optimized/Enterprise-Grade per feature
- Finance system (fundraising, burn/revenue/runway, marketing spend, deltas)
- Event system (50+ events, 26 world events, 67+ headlines)
- Competitor system (86 competitors, market leaderboard)
- Save/load (atomic writes, checksums, backup recovery, auto-save, build-queue migration)
- Tutorial (5-step overlay), Achievements (40), Founder Score (6-axis)
- VC Chips currency with **8 spend actions** (original 4 + rush quarter + rush instant + slot unlock + legacy boost)
- 22 SFX, haptics, screen shake, floating numbers, confetti
- All legal docs, privacy policy, ToS, support file
- Dev panel, smoke test, balance sim, QA checklist
- **16 pixel art UI icons** wired into product mockup (replacing emoji)
- **6 founder archetype portraits** wired into new game setup screen
- **13 consumer app component images** (thumbnails, stories, recommendations, brand badge, avatar)
- **Store listing copy** drafted (App Store + Google Play descriptions, keywords, categories)
- **Tier 1 launch punch list** with phased timeline (see `docs/tier1-launch-punchlist.md`)

### What's Blocking Launch
1. Apple Developer enrollment ($99) — user hasn't done this yet
2. Google Play Console enrollment ($25) — user hasn't done this yet
3. First device build — never run on a real phone
4. `MONETIZATION_TEMP_DISABLED = false` + IAP plugin wiring
5. Store listing assets (screenshots — copy is done)
6. Beta testing (TestFlight / Play Store internal track)
7. Build Queue UI — backend done, product overview screen needs multi-slot display
8. **founder_hustler.png** has real social media logos (LinkedIn, Instagram, Twitter) — needs regeneration with generic icons

### What Needs Content Work
- Employee bios: 72 → 200 (need 128 more)
- Headlines: 67 → 150 (need 83 more)
- VC dialogue variations: 0 → 30+
- Quarterly report templates: ~1 → 20+
- Game over postmortem templates: 0 → 10+
- Event description variations: 1 each → 3-5 each

### What Needs Art Work (see `docs/cursor-prompt-guide.md`)
- SaaS component images: 3 needed (chart, integrations, audit log)
- Marketplace component images: 4 needed (3 products, tracking bar)
- Dev Tools component images: 3 needed (CLI snippet, docs panel, usage chart)
- Employee specialty portraits: 18 needed (9 specialties × 2 variants)
- Store marketing assets: 8+ needed (screenshots, feature graphic, etc.)

### Balance Status
- Sandbox: All 4 types, 0 losses across 36 runs
- Normal: Marketplace viable (1/9 loss), other types challenging
- Hardcore: Intentionally brutal (all losses by Q3-4)
- Remaining concern: 6-quarter profit streak is the binding constraint for Sustainable win

### New Systems Added (April 13, 2026)

#### Builder Slots (`product_data.gd`)
Multi-slot parallel feature build system. Players start with 1 slot (2 if premium). Unlock up to 4 via team size or VC Chips. Build queue stored as `Array[Dictionary]` with feature_id, progress, crunched flag. Backward-compatible with old saves via `deserialize_build_state()` migration.

Key constants:
- `MAX_BUILD_SLOTS = 4`
- `SLOT_UNLOCK_ENGINEER_THRESHOLDS = [5, 12, 20]`
- `CRUNCH_PROGRESS_MULT = 1.5`, `CRUNCH_STRESS_COST = 15`, `CRUNCH_MORALE_COST = 10`

#### Ad Rush (Stacking Diminishing Returns)
Up to 3 ads per feature per day. Each reduces REMAINING build time: 25% → 15% → 10%. Net max acceleration ~42%. Resets daily. Themed as "Watch a Pitch" / "Attend a Meetup" / "Sponsor Coffee".

#### Feature Upgrade Tiers
After shipping a feature, upgrade it: Base → Scaled (+50% effects) → Optimized (+100%) → Enterprise-Grade (+150%). Each tier costs more progress. Tracked in `feature_upgrades` dict.

#### Icon System (`product_visual.gd`)
New `_icon_or_lbl()` helper loads pixel art PNGs from `assets/icons/` with automatic fallback to emoji/text labels if the file is missing. `_load_icon()` reads from `_ICON_BASE = "res://assets/icons/"`. 16 icons wired into product mockup replacing emoji.

#### Founder Portraits (`new_game.gd`)
`FOUNDER_PORTRAIT_PATHS` dict maps `FounderBackground` enum to PNGs in `assets/illustrations/founders/`. Portrait `TextureRect` created dynamically and inserted into the setup VBox after the background selector.

---

## 13. USER CONTEXT

- **Experience level:** First game project. Familiar with tech/startups (NVIDIA background). Not familiar with Xcode, Godot export, or device testing — needs step-by-step guidance for build/deploy.
- **Test devices:** iPhone 14, Galaxy S20 Ultra, iPad Pro 11"
- **Working style:** Wants comprehensive tracking of every idea. Gets frustrated when items are missed or work is shallow. Values thoroughness over speed. Will push back if quality is lacking — and is usually right when they do.
- **Key concern:** "I am super skeptical that you actually looked through our entire chat." — Trust has been damaged by prior sloppy work. Rebuild it by being verifiably thorough every time.

---

## 14. DEV MODE (Testing Guide)

### What Is Dev Mode?

Dev mode is controlled by `AdManager.current_build_mode()`. It's automatically active when running from the Godot Editor or a debug build (`OS.is_debug_build()`). In release/export builds, it's off unless `BUILD_MODE_OVERRIDE` is set.

**When dev mode is active:**
- `AdManager.is_premium()` returns `true` — all premium features unlocked
- `AdManager.is_game_locked()` returns `false` — paywall never triggers
- Purchase flows skip the real store and call `_complete_premium_unlock()` directly
- The **DEV button** appears in the top-right corner of the Quarter Dashboard
- Premium players start with 2 build slots (dev mode counts as premium)

### How to Access the Dev Panel

1. Run the game in Godot Editor (dev mode is automatic)
2. Start or load any game
3. On the Quarter Dashboard, tap the orange **"DEV"** button (top-right)
4. The Dev Panel overlay opens — press **Escape** to close

### What the Dev Panel Can Do

| Section | Actions |
|---------|---------|
| **Restore** | Set Energy=100, Board patience=4, All morale=80 |
| **People** | Hire Random, Hire 5 Random, Fire Last, Skill All +10 |
| **Product** | Debt/Bugs=0, Stability=100, UX=80, Ship Feature instantly |
| **Sabotage** | Debt=80, Bugs=50, Cash=$0, Energy=5 (for testing failure states) |
| **Quick Build** | Ship current feature at quality 80, Quality Max, Bugs=0 |
| **Hosting** | Max all hosting upgrades, Set reliability to 99.99% |
| **Fundraising** | Generate VC offer, Accept offer, Force next round |
| **Economy** | Toggle Bull/Neutral/Bear markets |
| **World Events** | Trigger random world event, Clear active world event |
| **Events** | Trigger random narrative event, Clear cooldowns, Clear fired events |
| **VC Chips** | +10, +50, +100, Reset to 0 |
| **God Mode** | Toggle invincibility (no bankruptcy, no burnout) |
| **Export** | Print full game state as JSON to console |
| **Save/Load** | Quick save to any slot, Load from any slot |

### Testing the New Builder Slots System

To test builder slots + rush in dev mode:
1. Start a new game (you'll have 2 slots since dev mode = premium)
2. Select a feature to build (slot 1 fills)
3. Use Dev Panel → VC Chips → +50 to give yourself chips
4. In CurrencyManager (via code or debug), call `spend_slot_unlock()` to get slot 3
5. Select another feature (slot 2 fills)
6. Advance quarters and observe both features building in parallel
7. Test `spend_rush_quarter(0)` to skip a quarter on slot 0
8. Test crunch by setting `GameState.product.set_slot_crunched(0, true)` before advancing

### Forcing Release Mode in Editor

To test the paywall, ads, and IAP flow as a non-paying user:
```gdscript
# In src/autoload/ad_manager.gd line 39:
const BUILD_MODE_OVERRIDE := "release"   # Forces release behavior in editor
```
**Remember to revert this before committing.** The smoke test checks that `MONETIZATION_TEMP_DISABLED = true` for safety.

### MONETIZATION_TEMP_DISABLED Flag

This master kill switch (`ad_manager.gd` line 32) is currently `true`. When true:
- All ad calls return false/empty
- `is_premium()` returns true (everything unlocked)
- `is_game_locked()` returns false (paywall disabled)
- Purchase flows call `on_unlock` immediately (no store)

**Flip to `false` only after IAP plugin is wired and tested.**

---

## 15. COMMON PITFALLS TO AVOID

1. **Don't skim the Dev Bible.** It's 85,672 characters across 12 sections. Items like "onboarding takes 1-2 weeks" and "Speed (1-100)" are buried in paragraphs, not headers. Read line by line.
2. **Don't assume the tracker is complete.** Always check against source material when making claims about what's tracked.
3. **Don't break SceneLoader.** All scene transitions must go through `SceneLoader.goto_scene()`. Direct `get_tree().change_scene_to_packed()` calls will bypass transition safety.
4. **Don't use `fade_in(self)` in `_ready()`.** This caused position-fighting bugs on 8 screens. Use `AnimHelper.stagger_list()`, `AnimHelper.pop_in()`, or `AnimHelper.fade_in()` on individual children instead.
5. **Don't add bare `print()` statements.** Gate all debug output behind `OS.is_debug_build()`.
6. **Don't forget UITouchHelper.** Call `UITouchHelper.harden_tree(self)` in `_ready()` on every screen to enforce touch target minimums.
7. **Don't commit without smoke test.** Run `python3 tools/backend_smoke.py` after any change to data files or engine logic.
8. **Don't use real company names.** Everything must be parody. Check `docs/reference-tone-guardrails.md` before adding any reference content.
9. **Don't modify the feature tracker casually.** It's the source of truth for ~350 items. When adding items, include the source (Dev Bible section, Cursor S2 message, etc.) in the Notes column.
10. **Don't ignore the user's playtester feedback.** Items from Cursor S2 with "Playtester:" or "User:" prefixes in the tracker are real player pain points, not theoretical nice-to-haves.
