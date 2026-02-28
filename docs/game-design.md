# Roguelike GM — Game Design Document (GDD)

## Elevator pitch

**Roguelike GM** is a Balatro-style deckbuilder meets sports management. Each run is a season: you draft a hand of player cards, make roster decisions through card plays, and face escalating opponent teams (blinds). Joker-equivalent cards are coaching staff, stadium upgrades, and tactical schemes that multiply your team's stats. Balatro's compounding math loop, but instead of poker hands you're assembling offensive/defensive lineups.

## Core loop

1. **Draft / shop** — Acquire player cards and “Joker” equivalents (coaches, stadiums, schemes).
2. **Build** — Arrange lineups; synergies and multipliers compound.
3. **Face opponent (blind)** — Resolve matchup; score is derived from your lineup + modifiers.
4. **Advance** — Win to progress; lose and the run ends. Difficulty escalates each opponent.
5. **Repeat** — One more run; ~20–30 min per run, mobile-friendly.

## Key systems

- **Player cards** — Base stats (e.g. offense/defense), positions, traits. Played into offensive/defensive slots.
- **Coaching staff / stadiums / schemes** — Multipliers and conditions (e.g. “+1.5x if 3+ guards”, “stadium: +20% home games”). The “Joker” layer that makes runs feel different.
- **Blinds (opponents)** — Themed opponent teams with modifiers (e.g. “defense +50%”, “no subs”). Escalate in difficulty and variety.
- **Scoring** — Formula combining lineup stats × multipliers; beat the blind’s threshold to win the “game” and advance.

## Design goals

- **Short sessions** — 20–30 min per run; suitable for mobile.
- **“One more run”** — Clear progression, visible synergies, meaningful choices each run.
- **Sports GM + Balatro audience** — Deep but snappy; not spreadsheet-y. Polished UI and feedback.

## Risks & mitigations

- **Balance** — Card and multiplier balance is hard. Mitigation: extensive playtesting; unit tests for scoring and deck logic (GdUnit4); data-driven tuning (resources/scripts).
- **Scope** — Avoid feature creep. Mitigation: MVP first (single sport, minimal card set), then expand.

## MVP scope (for prototype)

- One sport (e.g. basketball or generic “team sport”).
- Small set of player cards and 3–5 “Joker” modifiers.
- 3–5 blinds with increasing difficulty.
- Core loop only: draft → build lineup → resolve vs blind → win/lose → next blind or game over.
- Placeholder art and UI; focus on feel of the loop.

---

*Living document. Update as you lock mechanics and scope.*
