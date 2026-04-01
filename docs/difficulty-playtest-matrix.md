# Difficulty Playtest Matrix

Use this during manual balance passes (real gameplay runs).  
Goal: validate that Sandbox/Normal/Hardcore feel distinct and fair across all company types.

## Run Plan

- 4 company types x 3 difficulties = 12 core runs
- At least 1 full run per cell (win or loss)
- Optional: repeat unstable cells until outcomes are consistent

## Capture Per Run

| Metric | Target Notes |
|---|---|
| Quarter reached | Confirms run length pacing |
| End state | IPO / Unicorn / Sustainable / Acquisition / Loss |
| First feature completion quarter | Early gratification check |
| First revenue quarter | Early economy pressure check |
| Team size at Q8 / Q16 / Q24 | Hiring affordability and growth pacing |
| Cash floor (lowest point) | Bankruptcy pressure sanity |
| Event pressure feel (1-5) | Subjective pacing sanity |
| Interview affordability feel (1-5) | Early-game hiring pressure sanity |

## Expected Shape (High Level)

- **Sandbox**: easiest runway and lowest pressure; most runs should survive past Q20.
- **Normal**: meaningful pressure but recoverable; strong play should reach sustainable/IPO windows.
- **Hardcore**: mistakes punished quickly; expert play still viable with disciplined hiring.

## Suggested Tuning Order

1. `DIFFICULTY_MULTS.cash_mult`
2. `DIFFICULTY_MULTS.churn_mult`
3. `DIFFICULTY_MULTS.competitor_mult`
4. `DIFFICULTY_MULTS.fundraise_threshold_shift`
5. Interview cost/lock multipliers in `employee_list.gd`

## Validation Checklist

- No difficulty where a "harder" mode is consistently easier than an easier mode.
- No company type that is effectively unwinnable on Normal with clean play.
- No company type that reaches victory too early (< Q16) in most Normal runs.
