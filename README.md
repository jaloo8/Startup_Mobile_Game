# VENTURE

A premium mobile management sim where you build a tech startup from garage to IPO. *Pocket GM 3, but for tech startups.* Each run spans 20–40 quarters of strategic CEO decisions — hiring, product allocation, fundraising, and navigating the chaos of startup life.

Built with **Godot 4.6** (GDScript). Targets iOS and Android first, with Steam/desktop as a future option.

---

## Quick facts

| | |
|---|---|
| **Engine** | Godot 4.6 (Forward Plus) |
| **Language** | GDScript |
| **Platforms** | iOS, Android, Steam (future) |
| **Price** | Free through Year 2, then $2.99 full unlock (mobile) |
| **Session** | 10–20 min (one quarter per session) |
| **Run length** | 20–40 quarters (5–10 startup years) |
| **Architecture** | Autoload singletons, Resource-based data model |
| **Data** | Godot Resources + JSON for content |

---

## Repo structure

```
startup_mobile_game/
├── project.godot
├── src/
│   ├── autoload/
│   │   ├── game_state.gd             # Singleton — all run state
│   │   ├── scene_loader.gd           # Scene transitions + helpers
│   │   ├── glossary.gd               # Term lookup popup system
│   │   ├── analytics.gd              # GameAnalytics + settings I/O
│   │   ├── ad_manager.gd             # Ads, IAP, paywall gating
│   │   ├── tutorial_manager.gd       # First-run tutorial overlay
│   │   ├── ui_touch_helper_bridge.gd # Runtime bridge for UITouchHelper
│   │   └── world_event_engine_bridge.gd
│   ├── models/
│   │   ├── company_data.gd           # Company type, cash, hosting
│   │   ├── employee_data.gd          # Skills, morale, personality
│   │   ├── product_data.gd           # Features, tech debt, users
│   │   ├── financials_data.gd        # Revenue, burn rate, funding
│   │   ├── market_data.gd            # Competitors, economy state
│   │   └── event_data.gd             # Event definitions
│   ├── engine/
│   │   ├── simulation_engine.gd      # Core quarterly sim loop
│   │   ├── event_engine.gd           # Event triggers and resolution
│   │   ├── revenue_engine.gd         # Revenue calc by company type
│   │   ├── competitor_ai.gd          # AI competitor behavior
│   │   ├── fundraising_engine.gd     # VC offers and dilution
│   │   ├── valuation_engine.gd       # Company valuation model
│   │   ├── hiring_engine.gd          # Candidate generation
│   │   ├── headline_engine.gd        # News ticker headlines
│   │   ├── template_engine.gd        # Text template resolution
│   │   ├── quarterly_report.gd       # End-of-quarter summary
│   │   └── world_event_engine.gd     # Multi-quarter macro events
│   ├── ui/
│   │   ├── main_menu/                # Title screen
│   │   ├── setup/                    # New game + niche picker
│   │   ├── saves/                    # Save slot management
│   │   ├── dashboard/                # Quarter hub screen
│   │   ├── people/                   # Employees + interviews
│   │   ├── product/                  # Product + visuals
│   │   ├── finance/                  # Finances + fundraising
│   │   ├── logistics/                # Hosting ops + upgrades
│   │   ├── market/                   # Competitor leaderboard
│   │   ├── settings/                 # Settings + premium
│   │   ├── components/               # Shared (popup, glossary, chart)
│   │   ├── victory/                  # Win screen + continue
│   │   └── game_over/                # Loss screen + angel bailout
│   └── data/
│       ├── events.json               # Event definitions
│       ├── features.json             # Feature trees per type
│       ├── headlines.json            # News ticker templates
│       ├── competitors.json          # Rival company pool
│       ├── vcs.json                  # VC firm pool
│       ├── glossary.json             # Term definitions
│       ├── names.json                # Name generation pools
│       ├── niches.json               # Per-type niche definitions
│       ├── product_preview_prototypes.json
│       └── world_events.json         # Macro event definitions
├── tools/
│   ├── backend_smoke.py              # Offline structural validation
│   └── balance_sim.py                # Balance simulation runner (12-cell matrix)
├── docs/                             # GDD, roadmap, QA, guardrails
└── assets/                           # Illustrations, icons, avatars
```

---

## Docs

- **Game design** — [`docs/game-design.md`](docs/game-design.md) — Full GDD: vision, core loop, all game systems, data model, simulation engine, balance guidelines
- **Roadmap** — [`docs/roadmap.md`](docs/roadmap.md) — Development phases, priority checklist, workflow tips
- **Current execution path** — [`docs/current-execution-path.md`](docs/current-execution-path.md) — Active quality-first plan (stability -> balance -> phone readiness -> internal beta)
- **Monetization** — [`docs/monetization.md`](docs/monetization.md) — DLC strategy, pricing, release cadence, technical architecture for expansion packs
- **Balance simulation report** — [`docs/balance-sim-report.md`](docs/balance-sim-report.md) — Automated balance findings from 108-run simulation (critical: early cash hemorrhage, user growth too slow, Consumer revenue model needs buff)
- **Difficulty playtest matrix** — [`docs/difficulty-playtest-matrix.md`](docs/difficulty-playtest-matrix.md) — Manual run capture template for 12-run balance validation (all types x all difficulties)
- **Dev edge-case matrix** — [`docs/dev-edge-case-test-matrix.md`](docs/dev-edge-case-test-matrix.md) — 5-slot repeatable test setup for regression and stress coverage
- **Reference tone guardrails** — [`docs/reference-tone-guardrails.md`](docs/reference-tone-guardrails.md) — Writing safety rules for parody/world-event content
- **Coding conventions** — [`docs/coding-conventions.md`](docs/coding-conventions.md) — Architecture overview, coding rules, common pitfalls, and how to add content

---

## Recent changes

- **Interactive product mockup + idle-game progression** — Shipped features on the product phone-screen mockup are now tappable ("Product Demo" mechanic: bounce animation + floating tooltip + reputation bonus with diminishing returns). Feature costs now scale with an idle-game exponential curve (0.7x for first features, up to 4x for late features), creating the "easy early, grindy late" progression feel. All UI cost displays updated to show scaled costs.
- **Balance simulation runner** — New `tools/balance_sim.py` runs a 108-cell automated playtest matrix (4 types x 3 difficulties x 3 strategies x 3 seeds) across multiple starting scenarios. Identified critical balance issues: early cash hemorrhage, fundraising dependency, sluggish user growth, unused `MARKETING_USER_MULT` constant. See `docs/balance-sim-report.md`.
- **QA bug audit (7 fixes)** — Fixed SceneLoader transition race condition, OfflineSummary double-collect, Dashboard first-refresh false positive, PixelCharacter null guard, IdleEngine null company guard, Dashboard await safety, EventPopup scale reset.
- **Developer tools panel** — Full-screen code-only dev overlay (gated behind `AdManager.is_dev_mode()`): state inspector, cash/user injection, time skip, god mode, difficulty swap, team management, product controls, fundraising tools, economy toggles, event triggers, 5-slot quick save/load.
- **Comprehensive code audit + smoke test expansion** — Fixed 10 critical bugs (government grant effect, glossary dupes, headline templates, board patience logic, reputation bonus wiring, event cooldown leak, SceneLoader usage, null guards, office level clamping, paywall fallback), 3 data issues, 5 user-facing text issues, consolidated duplicated logic, added future-proofing clamps. Expanded `backend_smoke.py` with 7 new validators (glossary near-dupes, niche-competitor coverage, headline quality, version constant, event cooldown reset, history snapshots, SceneLoader-only enforcement). Added `docs/coding-conventions.md` as a reference for future sessions.
- **Main-menu/button input regression fix** — Added runtime autoload bridges for `UITouchHelper` and `WorldEventEngine` (`src/autoload/ui_touch_helper_bridge.gd`, `src/autoload/world_event_engine_bridge.gd`) and wired them in `project.godot` so UI/button scripts compile reliably even when class-name cache metadata is stale.
- **Role mesh + stage-aware responsibilities** — Work allocation now follows startup maturity: early teams stay cross-functional (non-feature lanes still provide partial feature support), while growth/scale runs require specialization. Dedicated `Bugs`, `Tech Debt`, `Infrastructure`, and `R&D` assignments now have stronger impact, and cross-role mesh bonuses reward balanced teams with better quality, steadier retention, and lower operational drag.
- **Expanded start scenarios** — New game now includes jump-in presets beyond bootstrap (`Growth Operator`, `Scale Chief`) so players can run mid-size or large companies immediately, each seeded with a realistic team mix, product state, and funding context.
- **World events system (multi-quarter macro cycles)** — Added `WorldEventEngine` + `src/data/world_events.json` with persistent market pulses (risk-off cycles, supply bottlenecks, regulation waves, creator booms, capital reopenings). Active world events now influence growth/churn/revenue/costs/fundraising, persist through save/load, and surface in dashboard + quarterly report.
- **Parody reference content pack (events/headlines/rivals)** — Added a broader startup-media parody layer across `src/data/events.json`, `src/data/headlines.json`, and `src/data/competitors.json` with subtle references to pivot culture, term-sheet dynamics, cofounder narrative tension, launch theatrics, and memo-leak cycles, while keeping text quote-free and legally safer.
- **Event cadence balance pass (stage + difficulty aware)** — Quarter-event selection now adapts by company stage and difficulty: early/sandbox runs stay less spammy with longer effective cooldowns, while late/hardcore runs sustain denser pressure with shorter repeats; event category weighting now shifts by stage/difficulty and adds same-category dampening inside a quarter to reduce repetitive macro-story beats.
- **Event effect wiring hardening** — Event choices now apply all supported effect keys end-to-end (including salary raises, equity grants, forced attrition, and fundraising-opportunity boosts), and backend smoke now fails fast on unknown `events.json` effect keys to prevent silent no-op outcomes.
- **Runtime + storage optimization pass** — Event/headline/world-event weighted picks now avoid duplicate weight computation, founder-energy quit counting now scans only current-quarter tail events, save serialization stores compact windows for `history`/`event_log`, and UI cleanup hooks were added for animation-heavy components to reduce lingering tween state on scene transitions.
- **Touch-target hardening + UI polish hooks** — Added centralized `UITouchHelper` (`src/ui/ui_touch_helper.gd`) and SceneLoader integration to enforce mobile-friendly 44-48px interaction targets and spacing across scenes (including dynamic buttons). The helper also tags lightweight visual hook metadata with comments so future Sonnet/Opus animation passes can layer richer press/ripple/haptic effects without broad refactors.
- **Key metric info clarity (DAU/MAU and peers)** — Dashboard `Key Metric` title is now an info button with click + hover glossary behavior; metric help text switches by company type (`MRR`, `DAU/MAU`, `GMV`, `API Calls`, `Valuation`) so players can quickly understand what each metric means.
- **Product page overlap/readability fix** — Bottom-of-page roadmap + ship-celebration widgets now render outside the shipped-features scroll region, and build/ETA text wrapping was tightened to prevent overlap while quarter trends update.
- **Hosting capacity actions (v2)** — Logistics now includes explicit player-facing infra upgrades: `Scale Web`, `Scale Cache`, `Scale Data`, and `Optimize request pipeline`, each with level caps, escalating one-time purchase costs, autosave hooks, and event-log traces.
- **Hosting simulation tuning pass** — Hosting now applies lane-upgrade capacity multipliers and optimization demand reduction, with smoother reliability/incident curves and difficulty-aware pressure scaling to reduce early-run randomness while preserving late-run infra risk.
- **Workload-aware hosting pressure** — Hosting demand now reacts to what you are actually building (AI/ML, streaming, marketplace, API/realtime) and surfaces a live workload profile (`General Cloud` / `Scale-Intensive` / `Data-Center Heavy`) across dashboard, finance, and logistics hints.
- **Quarter transition polish + SFX hooks** — Advancing quarter now runs a richer full-screen transition (period label + sweep + eased fade). Audio now supports optional whoosh/chime files with a synthesized fallback tone so the flow still feels responsive before final sound assets are dropped in.
- **Finance drill-down guidance** — Finances now includes a `Driver read` line that explains why cash moved quarter-over-quarter (revenue change + cost drivers + hosting incidents) instead of only showing deltas.
- **Office worker scene v2** — Dashboard office banner now renders desk-aware pseudo-sprite workers (head/body badge style), desk/monitor placement, and office customization accents by company type/plan for a more readable "busy office" feel.
- **Monetization stability gate contract** — `MONETIZATION_TEMP_DISABLED` remains explicitly enforced for gameplay stability work, and backend smoke now validates this guard so monetization cannot be re-enabled accidentally before QA signoff.
- **Hosting economics + reliability pass** — Added a quarter-based hosting model with per-plan behavior (`Managed Cloud`, `Hybrid`, `In-house`), lane-level demand/capacity tracking (web/cache/data), overage costs, and reliability-driven incident pressure that can impact stability/churn when infrastructure is overloaded.
- **Player-facing hosting controls** — Finances now includes a `Hosting Plan` selector, hosting cost line item, and live reliability/load/overage feedback so infra decisions are visible and actionable.
- **Logistics screen (v1)** — Added a dedicated Logistics view from Finances with lane utilization bars, hosting cost breakdown, reliability status, and milestone-style operations objectives for infra planning.
- **Finance wording clarity pass** — Dashboard and Finances now use plain-English metric names (`Cash in Bank`, `Money In / Q`, `Money Out / Q`, `Time Left`) with clearer glossary entries and an inline "Plain English" cashflow explanation on the dashboard.
- **Office worker ambient animation (v1)** — Dashboard office banner now renders lightweight assignment-colored worker markers with subtle sitting/working bob animation so the office feels more alive between quarter advances.
- **Quarter-feedback clarity pass** — Dashboard now surfaces a "Last quarter" momentum strip (cash/revenue/users/valuation deltas), explicit event-count + resolve messaging, a persistent "Next best action" hint, and a lightweight quarter-entry toast (`Now in Year X QY · Cash Δ · Users Δ`); the advance button now labels the exact next period (`Advance to Yx Qy`) for clearer turn flow.
- **Finance decision guidance pass** — Finances screen now includes an inline quarter-delta strip (cash/revenue/users) plus a natural-language "Next best move" recommendation based on runway, burn/revenue pressure, and dilution posture.
- **Product throughput readability pass** — Product ETA copy now includes estimated effort throughput per quarter so multi-person scaling is easier to read at a glance.
- **Core v1 polish pass (niche + personality depth)** — Added niche-aware event weighting (including stage awareness), weighted niche-aware headlines (with optional `niches` / `company_types` filters), niche-biased competitor seeding, and team personality composition effects on collaboration + morale.
- **Continue Last Run shortcut** — Main menu now includes a `Continue Last Run` button that loads the most recently modified valid save slot directly into gameplay, with safe fallback to the save-slot screen.
- **Quit/autosave reliability pass** — Added lifecycle safety autosave hooks in `GameState` (close request + app pause/focus-out) and a quit-path save from main menu, so runs are less likely to lose progress when exiting.
- **Product prototype preview foundation** — Product screen now has a data-driven `Prototype Concept` switcher (backed by `src/data/product_preview_prototypes.json`) so future visual concept ideas can be previewed quickly without additional code changes.
- **IAP + entitlement wiring pass** — `AdManager` now includes mobile purchase/restore bridge hooks (StoreKit / Google Play singleton detection, callback wiring, restore path) plus save-slot entitlement enforcement (`2` free slots vs `5` premium slots) in the save screen.
- **Employee detail view shipped** — Added a dedicated People detail screen with role/profile metadata, trajectory chart (Skill/Morale/Stress), and quarter history log; employee cards now include a `Details` action.
- **Niche system (P1)** — New game now includes per-company-type niche selection via `src/data/niches.json`; niche modifiers (growth/churn/revenue) are applied in simulation and revenue engines.
- **Early economy hiring revamp** — Candidate generation now includes employment type (full-time/contractor/intern) and one personality trait, with meaningful differences in compensation, retention risk, and development behavior.
- **Finance chart expansion** — Finance dashboard now includes a second trend panel (valuation/team size/avg morale), backed by richer history snapshots.
- **Visual hook layer pass** — Added lightweight placeholder FX hooks for quarter transitions and product feature-ship flashes so art/animation drops can plug in without gameplay rewrites.
- **Interview tuning + readability pass** — Interview costs and lock durations now scale by company stage (early/growth/late) and difficulty to reduce early cash pressure without flattening late-game decisions; interviewer picker now uses compact visual chips (cost/lock/confidence) plus explicit disabled-state hints.
- **Gameplay pacing tuning (type-aware)** — Late-stage growth headwinds and retention pressure are now tuned per company type, and sustainable-win scale checks are now type-specific for fairer timing across SaaS, Consumer, Marketplace, and Dev Tools runs.
- **Difficulty pass (backend)** — Difficulty now affects more than starting cash: churn pressure, competitor growth, fundraising thresholds/offer sizes, and event pressure are all tuned through `DIFFICULTY_MULTS` to better separate Sandbox/Normal/Hardcore.
- **Finance trend chart** — Finances screen now includes a lightweight trend chart for cash, revenue, and users (last 12 quarters, normalized per metric) to make long-run momentum easier to read.
- **Save stability fix** — `feature_progress` serialization now writes as a numeric value (not a duplicated container call), preventing save-time variant errors in quarter autosaves.
- **Automated backend smoke runner** — Added `tools/backend_smoke.py` to validate core JSON content integrity and feature-ID wiring (including product visual preset IDs) without needing the Godot runtime.
- **First-run tutorial system** — Added a lightweight 5-step guided overlay (`TutorialManager`) that introduces cash/runway, hiring, and quarter advance flow; supports skip, auto-step triggers, and replay from Settings.
- **Free vs paid flow** — Added a free-tier lock at end of Year 2 (8 quarters), premium paywall overlay, restore-purchases path, and save-slot entitlements; desktop/dev unlock path remains instant for local testing.
- **Deep interviews** — Candidate interviews now require choosing an interviewer (Founder/VP/Director/Manager/Engineer tiers), with confidence-based stat estimates, culture-fit uncertainty when interviewer people-skill is weak, and opportunity-cost locks that can sideline interviewers for upcoming quarters.
- **Longer-run pacing** — Sustainable victory now requires longer proof (6 profitable quarters + scale checks after Year 5), while feature build speed stays fast; victory screen now includes a "Keep Building" path for post-victory sandbox continuation.
- **Save/security hardening** — Save files now write through temp + checksum wrapper + `.bak` backup recovery; loader enforces checksum and falls back to backup on corruption/deserialize failures.
- **Settings storage hardening** — `settings.json` now writes atomically with size limits and backup fallback to prevent data loss from interrupted writes.
- **Employee avatars** — 8 expressive Pixar-inspired 3D cartoon characters, each with a distinct look and personality. Displayed on candidate cards, team lists, and the new hire badge. Hashed deterministically per employee name so the same character always gets the same face.
- **Employee ID badge** — Pop-in modal shown immediately after a hire; displays the avatar, name, title, key stats (Skill / Morale / Speed), employee number, and hire date before flowing into the assignment prompt. Animated spring scale-in for gratification.
- **Visual asset set** — 4 office banners (garage → co-working → small office → HQ), 4 product mockup illustrations (one per company type), 5 assignment-category icons (Features / Bugs / Tech Debt / Infra / R&D), and app icon — all integrated into the dashboard, product, people, and new-game screens.
- **Specialty system** — Employee specialties now drive real productivity. Mobile/Design excel at Consumer App features, Backend at SaaS/Dev Tools, DevOps at Infra, etc. Multipliers range 0.9×–1.4× and surface as "⚡ Great fit / ✓ Good fit" badges on hire and team cards.
- **Feature build speed** — Progress multiplier increased 3× (0.15 → 0.5). First features now complete in 1–3 quarters with a small team.
- **Feature ETA** — Product screen shows estimated quarters to completion, how many engineers are on it, and a specialty-fit summary that updates live.
- **Feature celebration** — A colour-coded banner fades in on both the Product and Dashboard screens when a feature ships.
- **Quarter deltas** — Cash, Revenue, and Burn Rate now show `+$X / -$X vs last Q` in green/red.
- **Milestone roadmap** — Product screen shows a visual progress strip toward the next user, features-shipped, and revenue goals.
- **Nav tabs moved to top** — People / Product / Finances / Market row is now at the top of the dashboard.
- **Valuation-based event pacing** — Early game gets max 1 event per quarter; scales to 3 as valuation grows past $2M.
- **Salary negotiation** — New "Negotiate Salary (−15%)" button in the hiring flow; low-fit candidates may walk.
- **New game UX** — Consumer App is the recommended default (★ badge + description). Each company type and difficulty now shows a plain-English description.
- **Office-full guidance** — When full, the hire button and a tip card explain exactly how and where to upgrade.

---

## Development mantra

**Make the next quarter feel clear, rewarding, and worth coming back for.**

Supporting principles:

1. **Clarity before complexity.** If a player cannot explain what happened and why, simplify the mechanic or the UI.
2. **Reward effort quickly.** Every 1-2 quarters should show visible progress (feature shipped, team growth, or financial momentum).
3. **Small slices, fully done.** Finish vertical slices end-to-end (logic, UI, save/load, edge cases) before expanding scope.
4. **Decisions, not dashboards.** Stats should drive a choice; if they do not change behavior, cut or rework them.
5. **Balance with evidence.** Tune from repeated runs and logs, not gut feel from one session.
6. **Protect trust.** Stable saves, predictable rules, and natural UX text matter more than flashy extras.
7. **Polish where players feel it.** Focus polish on onboarding, quarter advance feedback, and hire/product moments first.

---

## License

MIT — see [LICENSE](LICENSE).
