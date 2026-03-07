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
