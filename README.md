# VENTURE

A premium mobile management sim where you build a tech startup from garage to IPO. *Pocket GM 3, but for tech startups.* Each run spans 20–40 quarters of strategic CEO decisions — hiring, product allocation, fundraising, and navigating the chaos of startup life.

Built with **Swift/SwiftUI** for iOS (Android follow-up planned).

---

## Quick facts

| | |
|---|---|
| **Platform** | iOS first (Swift/SwiftUI), Android later |
| **Price** | $4.99 base (Software path) + $2.99 DLC packs |
| **Session** | 10–20 min (one quarter per session) |
| **Run length** | 20–40 quarters (5–10 startup years) |
| **Architecture** | MVVM, local-only (no server), single serializable GameState |
| **Data** | SQLite or CoreData |

---

## Repo structure

```
VentureApp/
├── Models/
│   ├── GameState.swift
│   ├── Company.swift
│   ├── Employee.swift
│   ├── Product.swift
│   ├── Financials.swift
│   ├── Market.swift
│   └── Event.swift
├── Engine/
│   ├── SimulationEngine.swift
│   ├── HiringEngine.swift
│   ├── RevenueEngine.swift
│   ├── CompetitorAI.swift
│   └── EventEngine.swift
├── Views/
│   ├── Setup/
│   │   └── NewGameView.swift
│   ├── Dashboard/
│   │   └── QuarterDashboardView.swift
│   ├── People/
│   │   ├── EmployeeListView.swift
│   │   ├── EmployeeDetailView.swift
│   │   └── HiringView.swift
│   ├── Product/
│   │   ├── ProductOverviewView.swift
│   │   └── FeatureListView.swift
│   ├── Finance/
│   │   ├── FinanceOverviewView.swift
│   │   └── FundraisingView.swift
│   ├── Events/
│   │   └── EventView.swift
│   └── Reports/
│       └── QuarterlyReportView.swift
├── ViewModels/
│   └── GameViewModel.swift
├── Data/
│   ├── events.json
│   ├── features.json
│   ├── names.json
│   └── competitors.json
└── Utils/
    ├── RandomGenerator.swift
    └── Formatters.swift
```

---

## Docs

- **Game design** — [`docs/game-design.md`](docs/game-design.md) — Full GDD: vision, core loop, all game systems, data model, simulation engine, balance guidelines
- **Roadmap** — [`docs/roadmap.md`](docs/roadmap.md) — Development phases, priority checklist, Cursor workflow tips
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
