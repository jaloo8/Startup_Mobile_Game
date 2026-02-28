# Roguelike GM

A Balatro-style deckbuilder meets sports management. Each run is a season: draft player cards, build lineups, face escalating opponent teams (blinds), and multiply your stats with coaching staff and stadium upgrades. Built in **Godot 4** (GDScript) for iPhone and desktop.

---

## Repo structure

```
roguelike-gm/
├── README.md
├── .gitignore
├── LICENSE
├── project.godot              # Godot project file
├── docs/
│   ├── game-design.md         # GDD (game design doc)
│   ├── monetization.md        # Monetization plan
│   └── roadmap.md             # Feature milestones
├── src/
│   ├── scenes/                # Godot scenes (.tscn)
│   │   ├── main_menu.tscn
│   │   ├── game_board.tscn
│   │   └── card.tscn
│   ├── scripts/               # GDScript
│   │   ├── game_manager.gd
│   │   ├── card.gd
│   │   ├── deck.gd
│   │   ├── scoring.gd
│   │   └── main_menu.gd
│   └── resources/             # Godot resources
├── assets/
│   ├── art/
│   ├── audio/
│   └── fonts/
├── tests/                     # Unit tests (GdUnit4)
│   ├── test_scoring.gd
│   └── test_deck.gd
└── export/                    # Build configs (gitignored)
```

---

## Running the project

1. Install [Godot 4.x](https://godotengine.org/download) (4.2+).
2. Clone this repo and open the folder in Godot (**Project → Import**, then select `project.godot`, or open the folder as project).
3. Press **F5** or **Play** to run. Main scene is the main menu; it currently switches to the game board when you wire up the Start button.

**Develop and test on desktop first.** Godot runs the game natively on Mac/PC — you’ll do most of your iteration here with fast run times and no device compile waits.

---

## Testing on iPhone

### Pipeline

1. **Desktop** — Most development and testing. Fast iteration.
2. **Mac required** — iOS builds need Xcode, which only runs on macOS.
3. **Apple Developer Account** — $99/year. Needed to run on your own device and to publish on the App Store.
4. **Godot → iOS:**
   - In Godot: **Project → Export**, add **iOS** template, configure signing.
   - Export to get an Xcode project.
   - Open in Xcode on your Mac, build and run on a physical iPhone (USB).
   - Test touch input, performance, and screen sizes.
5. **TestFlight** — Upload a build for beta testers (up to 10,000 external). Use this for real feedback before release.

### Unit tests (GdUnit4)

Godot doesn’t ship a test runner; use **[GdUnit4](https://github.com/MikeSchulze/gdUnit4)** (install as an addon). Use it for:

- **Scoring** — Formula, multipliers, edge cases.
- **Deck logic** — Draw, shuffle, discard, deck building rules.

Focus tests on the math and systems that are painful to debug by hand. Don’t spend time on full UI automation early; it’s usually not worth it for a solo dev.

After installing GdUnit4, open the GdUnit panel and run the suites in `tests/` (e.g. `test_scoring.gd`, `test_deck.gd`). The test files reference `Scoring` and `Deck`; ensure the addon can see your project’s `class_name` scripts (e.g. add `tests/` or project root to the test path in GdUnit4 if required).

---

## One game, one repo

This repo is for **Roguelike GM** only. Get a playable prototype (2–4 weeks) with placeholder art and a fun core loop before adding content or polish. If the loop isn’t fun in a bare-bones build, polish won’t fix it.

---

## Timeline & objectives (nothing → ship)

Work through these in order. Don’t skip ahead — especially don’t polish before the core loop is fun.

| Phase | Focus | Goal |
|-------|--------|------|
| **0** | Setup | Project runs, GdUnit4 works, design locked, main menu → game board |
| **1** | Vertical slice (1–2 weeks) | One full run: start → hand → lineup → one blind → win/lose → summary |
| **2** | Full core loop (2–3 weeks) | 3–5 blinds, modifiers, draft/shop; “one more run” feels good |
| **3** | On device (1–2 weeks) | iOS export, Xcode build to iPhone, TestFlight for testers |
| **4** | Content & balance (2–3 weeks) | More cards/blinds, balance pass, data-driven content |
| **5** | Polish (2–3 weeks) | Art, audio, fonts, UX feedback |
| **6** | Monetization & store (1–2 weeks) | IAP/store decision, App Store listing, screenshots |
| **7** | Ship | Submit, review, release |

**Full checklist with checkboxes:** see **`docs/roadmap.md`**. Update the Status column as you complete each objective.

---

## Docs

- **Game design** — `docs/game-design.md`
- **Monetization** — `docs/monetization.md`
- **Roadmap** — `docs/roadmap.md`
