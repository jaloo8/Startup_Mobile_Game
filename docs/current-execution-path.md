# Current Execution Path (Quality -> Phone Testing)

Last updated: March 2026

This is the active path for the project right now. It intentionally prioritizes quality, stability, and mobile readiness over adding major new systems.

## North Star

- Ship a stable, readable, high-trust core loop on real iOS/Android devices.
- Minimize regressions while tightening balance and UX clarity.
- Enter internal mobile beta only after objective quality gates pass.

## Scope Rule (Current)

- Focus on: bug fixes, performance, balance tuning, save reliability, mobile UX polish, and release-readiness gates.
- Defer: large new systems that expand scope but do not directly improve near-term device readiness.

## Sequence (Smartest Path Right Now)

1. **Stability hardening**
   - Keep running `python3 tools/backend_smoke.py` after meaningful changes.
   - Keep lints clean on touched files.
   - Eliminate silent no-op behavior and data/code contract drift.
   - Preserve save/load safety under long runs and repeated scene transitions.

2. **Empirical balance pass**
   - Execute the 12-run matrix in `docs/difficulty-playtest-matrix.md`.
   - Tune only the highest leverage knobs first (`DIFFICULTY_MULTS`, event pressure/cadence, early-economy pressure points).
   - Re-run unstable cells until outcomes are directionally consistent.

3. **Phone-readiness gates**
   - Run QA core path + mobile path from `docs/qa-smoke-checklist.md`:
     - All star items
     - Section 23 on real iOS and Android hardware
     - Save/load round-trip if persistence code changed
   - Ensure pre-release gates `R.1` through `R.5` are green before inviting beta testers.

4. **Internal beta (small cohort)**
   - TestFlight / internal track with 10-20 testers.
   - Triage feedback into P0/P1/P2, fix P0/P1 first, then re-run core QA + Section 23.

## Exit Criteria To Start Phone Testing

- Backend smoke passes consistently after recent changes.
- No known P0 regressions in core loop (new game -> play -> events -> save/load -> continue).
- Difficulty shape is sane across all 12 matrix cells.
- Mobile touch targets and navigation pass Section 23 checks on real devices.

## Deferred Until After First Internal Beta

- Dynamic org structures
- Time progression alternatives (real-time/monthly mode)
- Large net-new systems (executive poaching, stock-market endgame, CVC program)
- DLC path systems (AI, gaming, hardware, platform, mobility)

These are valuable, but they should not block near-term quality and phone readiness.
