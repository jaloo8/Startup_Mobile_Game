# Balance Simulation Report

Generated: 2026-04-06 (updated after tuning pass)
Tool: `tools/balance_sim.py`

## Summary

The balance simulation runner tests 4 company types x 3 difficulties x 3 AI strategies x 3 seeds = 108 runs per scenario. After the tuning pass, all sandbox cells survive 40 quarters and Normal difficulty shows viable growth paths.

## Changes Made This Session

1. **Marketing spend mechanic implemented** — `MARKETING_USER_MULT` (0.5) now wired to user growth via `sqrt(budget) * 0.5 * biz_bonus`. Finance UI has 6-tier marketing budget selector.
2. **Base organic growth increased** — `BASE_ORGANIC_USERS_PER_QUARTER` raised from 20 to 35.
3. **Junior salary costs lowered** — Range changed from $12K-$20K to $9K-$16K/quarter for more early runway.
4. **Consumer revenue buffed** — Ad CPM 0.025→0.06, premium conversion 4%→6%, premium ARPU $5→$8/month.
5. **Consumer win thresholds lowered** — Users 16K→8K, features 9→7, revenue/Q $240K→$40K.
6. **Fundraise thresholds eased** — Tier thresholds lowered (emerging 0.10→0.08, mid 0.25→0.15, top 0.40→0.30, elite 0.55→0.45).
7. **Tutorial angel event added** — One-time "An Angel Appears" event at Q3+ for unfunded companies: $50K cash + 5 reputation.

## Current Results (Post-Tuning)

### Sandbox Difficulty

| Type | Losses | Avg Users (Q40) | Avg Revenue/Q | Status |
|------|--------|-----------------|---------------|--------|
| SaaS | 0/9 | 5,761 | $50,356 | Healthy |
| Consumer | 0/9 | 10,353 | $41,142 | Healthy |
| Marketplace | 0/9 | 9,273 | $227,846 | Healthy |
| Dev Tools | 0/9 | 6,446 | $32,998 | Healthy |

**All sandbox cells now survive 40 quarters with zero losses.** Consumer reaches 10K+ users and $41K revenue, exceeding the sustainable win thresholds (8K users, $40K revenue).

### Normal Difficulty

| Type | Losses | Avg Q Reached | Avg Users | Status |
|------|--------|---------------|-----------|--------|
| SaaS | 8/9 | Q18 | 1,519 | Challenging |
| Consumer | 8/9 | Q16 | 1,881 | Challenging |
| Marketplace | 1/9 | Q36 | 6,165 | Viable |
| Dev Tools | 6/9 | Q22 | 2,677 | Moderate |

Marketplace on Normal has only 1 loss out of 9 runs with strong growth trajectories. Other types are harder but the sim AI doesn't model: events, world events, employee skill growth, niche bonuses, or optimal player strategy.

### Hardcore Difficulty

All types bankrupt by Q3-4. Intended — Hardcore is designed to be punishing.

## Sim Limitations (Conservative Bias)

The sim does NOT model:
- Random events (which give cash, reputation, user bonuses)
- World events (growth/cost multipliers)
- Employee skill growth over time
- Niche revenue/growth multipliers
- Optimal feature selection (sim picks sequentially)
- Adaptive player strategy (real players fire when burning)

These factors mean the real game is more forgiving than the sim suggests.

## Remaining Recommendations

1. **Profit streak is the binding constraint for sustainable win** — Companies can reach user/revenue thresholds but rarely become profitable for 6 consecutive quarters because team costs exceed revenue. Consider either: (a) lowering profit_streak from 6 to 4, or (b) checking revenue vs a fixed "viable revenue" target instead of vs total burn.
2. **Hardcore may need a small buff** — Currently impossible even with fundraising. Consider starting Hardcore with 1 pre-hired junior or giving a small cash buffer.
3. **SaaS and Dev Tools on Normal are hard** — Real players should be OK with events/bonuses, but monitor beta feedback.

## Running the Simulation

```bash
python3 tools/balance_sim.py                          # all 108 runs
python3 tools/balance_sim.py --type saas --diff normal # one cell
python3 tools/balance_sim.py --scenario vc_backed -v   # verbose VC-backed
python3 tools/balance_sim.py --runs 10                 # more seeds for variance
```
