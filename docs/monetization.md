# Venture — Monetization & DLC Strategy

---

## Revenue Model — Dual Track

Players choose how they want to play. Both options fund development.

### Free-to-Play (Ad-Supported)

Current implementation: free tier is playable through **Year 2** (8 quarters),
then prompts for full-game unlock. Ads appear at natural break points so they
don't interrupt gameplay flow.

**Ad placements (non-intrusive, thematic where possible):**
- **Between quarters** — After hitting "Advance Quarter" and before results show.
  Framed as a loading beat: "Simulating Q3..." with a short ad. Natural pause.
- **After game over** — Before the postmortem screen. Player is already pausing.
- **Optional rewarded ads** — "Watch a short ad to get an extra candidate in your
  hiring pool" or "Watch to reveal a hidden stat on a candidate." Feels like a
  small in-game perk, not a dark pattern.

**What F2P players get:**
- Full Software path onboarding and core systems through Year 2
- All foundational loops (people, product, money, events, competitors)
- First-run tutorial and guided progression
- Current build uses the same save-slot count as premium (5) until entitlement-based slot limits are added

**What F2P players don't get:**
- Year 3+ progression (locked behind full unlock)
- Ad-free experience
- DLC paths (locked behind purchase, same as premium)

**Upgrade path (current UI):** A single "Unlock Full Game — $2.99" purchase.
Desktop/dev unlock path is active; mobile purchase callbacks are scaffolded and
still need StoreKit/Google Play billing integration.

### Premium — $2.99 (current target)

- No ads, ever
- Full run length (beyond Year 2)
- Current build: 5 save slots (shared with free until slot entitlements ship)
- Software Path: 4 company types
- Full core engine
- All difficulty modes, starting scenarios, win conditions

### Ad Revenue Estimates

Conservative estimates at scale:
- Interstitial eCPM: ~$5-10 (iOS), ~$2-5 (Android)
- 1-2 ads per session × 10-minute sessions
- At 10K DAU: ~$150-500/month from ads alone
- Rewarded ads convert ~5-15% of impressions, higher eCPM ($15-30)

Even modest ad revenue provides a baseline while premium purchases and DLC
drive the real revenue. The F2P track primarily serves as a discovery funnel —
players try it free, enjoy it, and either upgrade to premium or buy DLC.

---

### DLC Packs (available to both F2P and Premium players)

### DLC Pack #1 — "The Intelligence Age" (AI/ML Path) — $2.99

- 3 company types (AI SaaS/API, AI-Powered App, AI Research Lab)
- GPU/Compute resource management system
- Model quality training mechanic
- Hype cycle market events
- 40+ AI-specific events
- AI-specific employee types (ML Engineer, Research Scientist, Data Engineer)

### DLC Pack #2 — "Silicon Dreams" (Hardware Path) — $2.99

- 3 company types (Consumer Electronics, Chip Design, Robotics)
- Manufacturing & supply chain system
- BOM and inventory management
- R&D cycle / tape-out mechanics
- Certification & compliance system
- 40+ hardware-specific events
- Hardware-specific employee types (RTL Designer, MechE, Supply Chain Ops)

### DLC Pack #3 — "Press Start" (Gaming Path) — $2.99

- 3 company types (Indie Studio, AA Studio, Live Service/F2P)
- Project-based development system (multiple games in flight)
- Review score simulation
- Wishlist / hype marketing mechanic
- Crunch culture morale system
- 40+ gaming-specific events
- Gaming-specific employee types (Game Designer, QA Lead, Community Manager)

### DLC Pack #4 — "The Platform Play" (OS & Platform Path) — $2.99

- 2 company types (Mobile/Desktop OS, Developer Platform/Cloud)
- Developer ecosystem health mechanic
- Platform governance decisions
- Network effects simulation
- App store / marketplace revenue system
- 30+ platform-specific events
- Platform-specific employee types (DevRel, Platform Engineer, Partner Manager)

### Bundle — "Venture: Complete Collection" — $12.99

Base + all 4 DLCs (~25% savings).

---

## DLC Release Cadence

Do NOT build all DLCs before shipping. Release schedule:

| Release | Content | Target |
|---------|---------|--------|
| v1.0 | Base game (Software path) | Week 13 (ship day) |
| v1.1 | Bug fixes, balance patches, QoL from player feedback | Week 15 |
| v1.2 | "The Intelligence Age" (AI/ML DLC) | Week 20 |
| v1.3 | "Press Start" (Gaming DLC) | Week 28 |
| v1.4 | "Silicon Dreams" (Hardware DLC) | Week 36 |
| v1.5 | "The Platform Play" (OS/Platform DLC) | Week 44 |

### Why this order

1. **AI/ML first** — Most timely, you have domain knowledge from NVIDIA, highest market interest
2. **Gaming second** — Most meta (game about making games), strong community appeal
3. **Hardware third** — You know this world from NVIDIA, most mechanically unique
4. **Platform last** — Most ambitious design, benefits from lessons learned on other DLCs

---

## DLC Architecture (Technical)

Each DLC is a module that plugs into the core engine:

```
src/
├── engine/                              (shared core — always installed)
│   ├── simulation_engine.gd             (shared quarterly sim loop)
│   ├── hiring_engine.gd                 (shared people management)
│   ├── revenue_engine.gd                (shared money systems)
│   └── event_engine.gd                  (shared event dispatch)
├── paths/
│   └── software/                        (included in base)
│       ├── software_product_system.gd
│       ├── software_revenue_model.gd
│       ├── software_events.json
│       └── software_features.json

DLC Packs (unlocked via IAP):
├── paths/
│   ├── ai/                              (DLC #1)
│   │   ├── ai_product_system.gd
│   │   ├── compute_budget_system.gd     ← unique mechanic
│   │   ├── model_training_system.gd     ← unique mechanic
│   │   ├── ai_revenue_model.gd
│   │   ├── ai_events.json
│   │   └── ai_features.json
│   ├── hardware/                        (DLC #2)
│   │   ├── hardware_product_system.gd
│   │   ├── manufacturing_system.gd      ← unique mechanic
│   │   ├── supply_chain_system.gd       ← unique mechanic
│   │   ├── hardware_revenue_model.gd
│   │   ├── hardware_events.json
│   │   └── hardware_features.json
│   ├── gaming/                          (DLC #3)
│   │   ├── gaming_product_system.gd
│   │   ├── game_project_system.gd       ← unique mechanic
│   │   ├── review_score_system.gd       ← unique mechanic
│   │   ├── gaming_revenue_model.gd
│   │   ├── gaming_events.json
│   │   └── gaming_features.json
│   └── platform/                        (DLC #4)
│       ├── platform_product_system.gd
│       ├── ecosystem_health_system.gd   ← unique mechanic
│       ├── platform_revenue_model.gd
│       ├── platform_events.json
│       └── platform_features.json
```

### Key design principle

The core `SimulationEngine` calls methods on a path module script. Each path implements the same interface (duck-typed or via a base class). When the player starts a new game, the engine loads the appropriate path module. This means:
- Adding a DLC never requires changing core engine code
- Each path can have wildly different product/revenue mechanics
- Events are loaded from JSON, so adding 40 events per DLC is just data, not code
- The UI adapts based on which path-specific scenes are needed

---

## Cross-Path Synergies (Future — v2.0+)

Once all paths exist, you could add late-game mechanics where paths interact:

- Software company acquires a hardware startup to build custom chips
- AI company partners with a gaming studio for AI NPCs
- Hardware company builds an OS to control their ecosystem
- Platform company acquires an AI lab for intelligent features

This creates a "conglomerate" endgame that dramatically extends replayability. But this is post-launch, post-DLC territory. Don't think about it now.

---

## Notes

- Apple: 30% cut (15% for Small Business Program under $1M/yr revenue)
- Google Play: 15% for first $1M/yr, 30% after
- Steam: 30% cut (drops at $10M+ and $50M+ thresholds)
- Consider pricing and paywall placement carefully for DLC IAP
- TestFlight and soft launch are good places to test price sensitivity
- Godot's export templates handle platform-specific IAP integration

---

*Update when you choose final price points or add concrete IAP SKUs.*
