# Current Execution Path (Quality -> Phone Testing -> Launch)

Last updated: April 2026

This is the active path for the project right now. It intentionally prioritizes quality, stability, and mobile readiness over adding major new systems.

## North Star

- Ship a stable, readable, high-trust core loop on real iOS/Android devices.
- Minimize regressions while tightening balance and UX clarity.
- Enter internal mobile beta only after objective quality gates pass.
- Target: public launch by mid-May 2026.

## Scope Rule (Current)

- Focus on: bug fixes, performance, balance tuning, save reliability, mobile UX polish, and release-readiness gates.
- Defer: large new systems that expand scope but do not directly improve near-term device readiness.

## Sequence (Smartest Path Right Now)

1. **Stability hardening** (DONE — April 2026)
   - `python3 tools/backend_smoke.py` passes consistently.
   - QA bug audit complete: 7 critical bugs fixed (SceneLoader race, double-collect, null guards, await safety, scale reset).
   - Developer tools panel built for testing (god mode, time skip, quick save/load).
   - Follow conventions in `docs/coding-conventions.md` for consistent patterns.

2. **Balance + Content Polish** (IN PROGRESS — April 2026)
   - Idle-game progression curve implemented (exponential feature cost scaling).
   - Interactive product mockup ("Product Demo" tap mechanic with gameplay effects).
   - Balance simulation runner built (`tools/balance_sim.py`) — 108-run automated matrix.
   - **Critical findings** (see `docs/balance-sim-report.md`):
     - Early cash hemorrhage: Garage scenario bankrupt in 2-3 quarters
     - `MARKETING_USER_MULT` defined but unused — no marketing → growth path
     - Consumer revenue model needs buffing (344K users needed for sustainable win)
     - User growth too slow for win thresholds even at 40 quarters
   - **Next**: Tune `DIFFICULTY_MULTS`, implement marketing spend, lower Consumer win thresholds, add tutorial fundraise prompt.

3. **Phone-readiness gates** (NEXT — Phase 2)
   - Test devices: iPhone 14, Galaxy S20 Ultra, iPad Pro 11"
   - Xcode Simulator for iPhone SE small-screen testing
   - Run QA Section 23 (`docs/qa-smoke-checklist.md:435-457`) on real hardware
   - Fix safe area, touch targets, performance, scroll behavior
   - Ensure pre-release gates `R.1` through `R.5` are green

4. **Monetization wiring** (Phase 3)
   - Ship premium-only for v1.0 ($2.99, no ads)
   - Set `MONETIZATION_TEMP_DISABLED = false`, test all IAP flows
   - Privacy policy fields need legal name/email/address from founder

5. **Internal beta** (Phase 4)
   - TestFlight / Play Store internal track with 10-20 testers
   - Triage feedback into P0/P1/P2, fix P0/P1 first
   - 5-7 days of beta, 5+ testers completing full runs

6. **Public launch** (Phase 5)
   - Store listing, screenshots, soft launch in 1-2 markets
   - Monitor crash-free rate (>99.5%), D1/D7 retention
   - Go worldwide

## Exit Criteria To Start Phone Testing

- Backend smoke passes consistently after recent changes.
- No known P0 regressions in core loop (new game -> play -> events -> save/load -> continue).
- Balance simulation shows no unwinnable Normal cells.
- Critical balance issues from sim report addressed.

## Deferred Until After First Internal Beta

- Dynamic org structures
- Time progression alternatives (real-time/monthly mode)
- Hybrid real-time operations monetization experiment
- Large net-new systems (executive poaching, stock-market endgame, CVC program)
- DLC path systems (AI, gaming, hardware, platform, mobility)

These are valuable, but they should not block near-term quality and phone readiness.
