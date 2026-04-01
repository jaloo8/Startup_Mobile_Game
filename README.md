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
| **Price** | $4.99 base (Software path) + $2.99 DLC packs |
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

---

## Recent changes

- **Interview tuning + readability pass** — Interview costs and lock durations now scale by company stage (early/growth/late) and difficulty to reduce early cash pressure without flattening late-game decisions; interviewer picker now uses compact visual chips (cost/lock/confidence) plus explicit disabled-state hints.
- **Gameplay pacing tuning (type-aware)** — Late-stage growth headwinds and retention pressure are now tuned per company type, and sustainable-win scale checks are now type-specific for fairer timing across SaaS, Consumer, Marketplace, and Dev Tools runs.
- **Difficulty pass (backend)** — Difficulty now affects more than starting cash: churn pressure, competitor growth, fundraising thresholds/offer sizes, and event pressure are all tuned through `DIFFICULTY_MULTS` to better separate Sandbox/Normal/Hardcore.
- **Finance trend chart** — Finances screen now includes a lightweight trend chart for cash, revenue, and users (last 12 quarters, normalized per metric) to make long-run momentum easier to read.
- **Save stability fix** — `feature_progress` serialization now writes as a numeric value (not a duplicated container call), preventing save-time variant errors in quarter autosaves.
- **Automated backend smoke runner** — Added `tools/backend_smoke.py` to validate core JSON content integrity and feature-ID wiring (including product visual preset IDs) without needing the Godot runtime.
- **First-run tutorial system** — Added a lightweight 5-step guided overlay (`TutorialManager`) that introduces cash/runway, hiring, and quarter advance flow; supports skip, auto-step triggers, and replay from Settings.
- **Free vs paid flow** — Added a free-tier lock at end of Year 2 (8 quarters) with a full-game paywall overlay in `AdManager`; desktop/dev unlock path is active now, mobile IAP provider callbacks are stubbed for StoreKit/Google Play wiring.
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

## Development mantras

1. **Playable over perfect.** A working game with placeholder UI beats a beautiful screen with no logic behind it.
2. **One system at a time.** Don't build the fundraising system until hiring works.
3. **Decisions over numbers.** If a screen shows stats but doesn't ask the player to DECIDE something, it's not gameplay.
4. **Every quarter should have tension.** If a quarter passes with nothing interesting happening, add more events.
5. **Steal from PGM3.** Its UI patterns, session structure, and "just one more season" hooks are your north star.
6. **Your life is content.** Every frustrating thing about working in tech is a potential game event.
7. **Ship in 3 months.** Not 6. Not 12. Scope to what one person can build in 13 weeks with AI assistance. Cut ruthlessly.

---

## License

MIT — see [LICENSE](LICENSE).
