# VENTURE

A premium mobile management sim where you build a tech startup from garage to IPO. *Pocket GM 3, but for tech startups.* Each run spans 20–40 quarters of strategic CEO decisions — hiring, product allocation, fundraising, and navigating the chaos of startup life.

Built with **Godot 4.3** (GDScript). Targets iOS and Android first, with Steam/desktop as a future option.

---

## Quick facts

| | |
|---|---|
| **Engine** | Godot 4.3 (Forward Plus) |
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
│   │   └── game_state.gd             # Singleton — all run state
│   ├── models/
│   │   ├── company_data.gd           # Company type, cash, valuation
│   │   ├── employee_data.gd          # Skills, morale, assignment
│   │   ├── product_data.gd           # Features, tech debt, users
│   │   ├── financials_data.gd        # Revenue, burn rate, funding
│   │   ├── market_data.gd            # Competitors, trends
│   │   └── event_data.gd             # Event definitions
│   ├── engine/
│   │   ├── simulation_engine.gd      # Core quarterly sim loop
│   │   ├── hiring_engine.gd          # Candidate generation
│   │   ├── revenue_engine.gd         # Revenue calc by company type
│   │   ├── competitor_ai.gd          # AI competitor behavior
│   │   └── event_engine.gd           # Event triggers and resolution
│   ├── ui/
│   │   ├── main_menu/
│   │   ├── setup/                    # New game config
│   │   ├── dashboard/                # Quarter hub screen
│   │   ├── people/                   # Employee management (TBD)
│   │   ├── product/                  # Product allocation (TBD)
│   │   ├── finance/                  # Financial overview (TBD)
│   │   └── events/                   # Event resolution (TBD)
│   └── data/
│       ├── events.json               # Event definitions
│       └── names.json                # Name generation pools
├── docs/
│   ├── game-design.md                # Full GDD
│   ├── roadmap.md                    # Development phases & checklist
│   └── monetization.md               # DLC strategy & pricing
└── tests/                            # GdUnit / GUT tests (TBD)
```

---

## Docs

- **Game design** — [`docs/game-design.md`](docs/game-design.md) — Full GDD: vision, core loop, all game systems, data model, simulation engine, balance guidelines
- **Roadmap** — [`docs/roadmap.md`](docs/roadmap.md) — Development phases, priority checklist, workflow tips
- **Monetization** — [`docs/monetization.md`](docs/monetization.md) — DLC strategy, pricing, release cadence, technical architecture for expansion packs
- **Difficulty playtest matrix** — [`docs/difficulty-playtest-matrix.md`](docs/difficulty-playtest-matrix.md) — Manual run capture template for 12-run balance validation (all types x all difficulties)

---

## Recent changes

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
