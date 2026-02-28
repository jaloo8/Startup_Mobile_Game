# Roguelike GM — Roadmap & Timeline

**Goal:** Nothing → shipped game, in order. Work through phases sequentially; don’t skip to polish before the loop is fun.

---

## Phase 0: Setup (Week 0)

**Objective:** Project runs, design is locked, tests can run.

| # | Objective | Status |
|---|-----------|--------|
| 0.1 | Godot 4 installed; project opens and runs (F5) | Done |
| 0.2 | Repo structure in place (docs, src, assets, tests) | Done |
| 0.3 | GdUnit4 addon installed and at least one test runs | |
| 0.4 | GDD and MVP scope locked (sport, core loop, 3–5 cards/blinds) | |
| 0.5 | Main menu has a working “Start run” that loads game board | |

---

## Phase 1: Vertical slice (Weeks 1–2)

**Objective:** One complete run, start to finish, with placeholders. No content depth yet — just prove the loop.

| # | Objective | Status |
|---|-----------|--------|
| 1.1 | Start run: game board loads with a deck and initial hand | |
| 1.2 | Hand displays as cards (placeholder art OK); can select a card | |
| 1.3 | Play card to lineup (offense/defense slots); lineup visible | |
| 1.4 | “Confirm lineup” or “Face blind” button; one blind with a score threshold | |
| 1.5 | Scoring formula implemented; win if score ≥ threshold, else lose | |
| 1.6 | Win → “Next blind” or “Run complete”; lose → “Run over” + summary | |
| 1.7 | Run summary screen: score, blinds beaten; option to start new run | |
| 1.8 | Unit tests for scoring and deck (GdUnit4) passing | |

**Exit condition:** You can play one full run (start → lineup → one blind → win/lose → summary) on desktop.

---

## Phase 2: Full core loop (Weeks 3–4)

**Objective:** Multiple blinds, modifiers, and enough content to feel like a real run.

| # | Objective | Status |
|---|-----------|--------|
| 2.1 | 3–5 blinds in order; escalating score thresholds | |
| 2.2 | 3–5 “Joker” modifiers (coaches/schemes) that affect score | |
| 2.3 | Modifiers applied correctly in scoring (unit tests updated) | |
| 2.4 | Between blinds: optional draft/shop (add 1–2 cards to deck) or keep minimal | |
| 2.5 | Run length feels right (~15–25 min); tune blind count/difficulty | |
| 2.6 | Playtest: core loop is fun with placeholder art; document what to fix | |

**Exit condition:** “One more run” is believable; you want to play again after a run ends.

---

## Phase 3: On device (Weeks 5–6)

**Objective:** Game runs on your iPhone and is shareable via TestFlight.

| # | Objective | Status |
|---|-----------|--------|
| 3.1 | Apple Developer account ($99/year) and Mac with Xcode | |
| 3.2 | Godot iOS export preset configured; export produces Xcode project | |
| 3.3 | Build from Xcode to physical iPhone via USB; game launches | |
| 3.4 | Touch input works; UI readable and usable on phone (layout/safe area) | |
| 3.5 | TestFlight build uploaded; install and play on device from TestFlight | |
| 3.6 | One or two testers try a build; collect feedback | |

**Exit condition:** You and a tester can play a full run on iPhone.

---

## Phase 4: Content & balance (Weeks 7–9)

**Objective:** More variety, balanced numbers, no placeholder-dependent design.

| # | Objective | Status |
|---|-----------|--------|
| 4.1 | Expand to 10+ player cards and 5+ modifiers (or your target counts) | |
| 4.2 | 5–8 blinds with distinct themes/modifiers | |
| 4.3 | Balance pass: win rate and run length in target range | |
| 4.4 | Data-driven where possible (cards/blinds in resources or JSON) | |
| 4.5 | Bug list from playtests addressed | |

---

## Phase 5: Polish (Weeks 10–12)

**Objective:** Replace placeholders; game looks and sounds like a real product.

| # | Objective | Status |
|---|-----------|--------|
| 5.1 | Art pass: card art, UI, main menu, run summary | |
| 5.2 | Audio: menu, card play, win/lose, ambient (or minimal SFX) | |
| 5.3 | Fonts and readability on small screens | |
| 5.4 | UX polish: feedback on actions, transitions, no dead-ends | |
| 5.5 | Settings: volume, maybe accessibility (e.g. text size) | |

---

## Phase 6: Monetization & store (Weeks 13–14)

**Objective:** Business model in place (if any) and store listing ready.

| # | Objective | Status |
|---|-----------|--------|
| 6.1 | Monetization decided and implemented (see `docs/monetization.md`) | |
| 6.2 | App Store listing: name, description, keywords, category | |
| 6.3 | Screenshots and preview video for store page | |
| 6.4 | Privacy policy / support URL if required | |
| 6.5 | Final TestFlight round; fix showstopper bugs | |

---

## Phase 7: Ship (Week 15+)

| # | Objective | Status |
|---|-----------|--------|
| 7.1 | Submit for App Review | |
| 7.2 | Handle review feedback; resubmit if needed | |
| 7.3 | Release; post-launch plan (patches, first content update) | |

---

## Summary timeline (approximate)

| Phase | Focus | Weeks |
|-------|--------|-------|
| 0 | Setup | 0 |
| 1 | Vertical slice (one run) | 1–2 |
| 2 | Full core loop | 3–4 |
| 3 | On device + TestFlight | 5–6 |
| 4 | Content & balance | 7–9 |
| 5 | Polish | 10–12 |
| 6 | Monetization & store | 13–14 |
| 7 | Ship | 15+ |

Adjust weeks to your pace. Don’t move to the next phase until the exit condition is met — especially Phase 1 → 2 (loop must feel good before content).
