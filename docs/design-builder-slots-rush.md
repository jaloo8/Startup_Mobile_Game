# Venture — Builder Slots + Rush Mechanic Design

**Date:** April 13, 2026
**Status:** Design spec — not yet implemented
**Scope:** Combines "builder slot" constraints with "rush job" monetization. Fits into existing quarterly simulation without replacing it.

---

## The Core Idea

**The Constraint:** Your team can only work on a limited number of things at once (builder slots). This forces the player to prioritize — "do I build Social Feed or Push Notifications first?"

**The Release Valve:** Any feature currently being built can be rushed to completion. Watch a rewarded ad OR spend VC Chips to skip build time. Early features are cheap/fast; late features are expensive/slow — escalating pressure to spend.

**The Guarantee:** Every feature is completable without paying. Spending just accelerates. This keeps the "not a cash grab" promise.

---

## How Builder Slots Work

### Slot Capacity

Builder slots represent how many features your team can work on simultaneously. Right now, the game only supports 1 feature at a time (`target_feature_id` is a single string on `ProductData`). This mechanic formalizes that and makes it upgradeable.

| Slot Count | How to Unlock | Narrative Framing |
|-----------|---------------|-------------------|
| 1 slot | Default (start of game) | "Your tiny team can only focus on one thing at a time." |
| 2 slots | Hire 5+ engineers OR spend 8 VC Chips | "Your team is big enough to split into two workstreams." |
| 3 slots | Hire 12+ engineers OR spend 15 VC Chips | "You've got squads now. Three projects can run in parallel." |
| 4 slots (max) | Hire 20+ engineers OR spend 25 VC Chips | "Full engineering org. Four concurrent build lanes." |

**Key design decision:** Slots unlock via team size (free path) OR VC Chips (pay path). The VC Chip unlock is permanent for the run — once bought, you keep it even if you lose employees. This means whales get it early, free players get it when their team naturally grows.

**Engineers for slot purposes:** Count employees assigned to "Features" work lane only. Not bug fixers, not R&D, not tech debt.

### UI Changes Needed

The Product Overview screen currently shows 1 feature being built. With slots:

- Show a "Build Queue" section with N slots (1-4)
- Each slot shows: feature name, progress bar, ETA in quarters, "Rush" button
- Empty slots show available features to assign
- If all slots are full, available features are grayed out with "All build slots in use"

---

## How Build Durations Work

### Current System

Right now, feature progress advances each quarter based on:

```
progress += (team_contribution * dev_speed_multiplier) / (FEATURE_COST * feature_cost_multiplier)
```

Where `feature_cost_multiplier()` escalates: 0.7x → 0.85x → 1.0x → 1.26^(n-3) for features 4+.

A feature ships when `feature_progress >= 1.0`.

### Proposed System: Explicit Quarter Durations

Instead of abstract progress-to-1.0, convert to explicit quarter durations that the player can see. This makes the escalation tangible and the rush cost obvious.

| Feature # | Cost Multiplier | Base Quarters to Build | With Full Team Bonus |
|-----------|----------------|----------------------|---------------------|
| 1st | 0.7x | **1 quarter** | 1 quarter |
| 2nd | 0.85x | **1 quarter** | 1 quarter |
| 3rd | 1.0x | **1 quarter** | 1 quarter |
| 4th | 1.26x | **2 quarters** | 1 quarter |
| 5th | 1.59x | **2 quarters** | 1-2 quarters |
| 6th | 2.00x | **2 quarters** | 2 quarters |
| 7th | 2.52x | **3 quarters** | 2 quarters |
| 8th | 3.18x | **3 quarters** | 2-3 quarters |
| 9th | 4.00x | **4 quarters** | 3 quarters |
| 10th | 5.04x | **4 quarters** | 3 quarters |

**"Full Team Bonus"** = having 3+ engineers assigned to the feature lane. Reduces build time by ~25-33%. This creates a natural incentive to hire more people.

**The Clash of Clans parallel:** Feature 1 is like your first building (instant). Feature 10 is like a max-level Town Hall upgrade (takes 4 quarters = a full in-game year). The escalation curve is the same shape.

### Feature Upgrade Tiers (Scaling for Traffic)

This is your "upgrade the building" idea. After shipping a feature, you can upgrade it to handle more traffic / provide better quality. Each upgrade tier takes longer.

| Upgrade Tier | Effect | Additional Quarters | VC Chip Rush Cost |
|-------------|--------|-------------------|-------------------|
| Base (shipped) | Standard effects | 0 (already built) | — |
| Tier 2: "Scaled" | +50% of base effects | 2 quarters | 8 chips |
| Tier 3: "Optimized" | +100% of base effects + new bonus | 3 quarters | 12 chips |
| Tier 4: "Enterprise-Grade" | +150% of base effects + unique perk | 5 quarters | 20 chips |

**Example for "Social Feed" (consumer):**

| Tier | Effect | What Changes Visually |
|------|--------|--------------------|
| Base | +8% DAU, +15 user growth | Feed shows 3 cards |
| Scaled | +12% DAU, +22 user growth | Feed shows 6 cards, "Trending" section |
| Optimized | +16% DAU, +30 user growth, +3 reputation | Feed has algorithm, infinite scroll |
| Enterprise-Grade | +20% DAU, +40 user growth, +5 reputation, -1% churn | Feed has stories integration, creator tools |

This is where the evolving product mockup visuals really shine — each upgrade tier changes what the phone shows.

---

## Rush Mechanics

### Rush via VC Chips

| What You're Rushing | Cost | Effect |
|--------------------|------|--------|
| Skip 1 quarter of build time | 5 chips | Advances feature progress by 1 quarter's worth |
| Instant complete (any feature) | 10-25 chips (scales with remaining time) | Feature ships immediately |
| Instant complete (upgrade tier) | 8-20 chips (scales with tier) | Upgrade completes immediately |

**Scaling formula for instant complete:**
```
rush_cost = 5 + (remaining_quarters * 5)
```
So a feature with 1 quarter left costs 10 chips. A feature with 4 quarters left costs 25 chips.

### Rush via Rewarded Ads (Stacking Tiers — Diminishing Returns)

Instead of one big skip, ads provide stacking small bonuses. Each ad helps a little, never feels mandatory, and diminishing returns prevent it from feeling predatory.

| Ad # (per feature per day) | Build Time Reduction | Cumulative Reduction | Feel |
|---------------------------|---------------------|---------------------|------|
| 1st ad | -25% of remaining time | 25% faster | "That helped!" |
| 2nd ad | -15% of remaining time | ~36% faster total | "A bit more, nice" |
| 3rd ad | -10% of remaining time | ~42% faster total | "Diminishing, but still worth it" |
| No more ads available | — | Max ~42% faster | Natural cap for the day |

**Example:** Feature has 3 quarters remaining.
- After 1st ad: 3 × 0.75 = 2.25 quarters remaining
- After 2nd ad: 2.25 × 0.85 = 1.91 quarters remaining
- After 3rd ad: 1.91 × 0.90 = 1.72 quarters remaining
- Net: saved ~1.3 quarters (from 3 → 1.72). Meaningful but not a full skip.

**Key design decisions:**
- 3 ads max per feature per real-world day (resets at midnight local time)
- Each ad reduces REMAINING time, not total time — so watching earlier is more valuable
- Players still also earn +5 VC Chips per ad (existing mechanic stacks with this)
- The player always has a choice: watch ads for speed, spend chips for bigger skips, or just wait

**Why this feels good instead of predatory:**
- No single ad is game-changing — it's always "a little help"
- Diminishing returns mean you never feel forced to watch all 3
- The VC Chips earned from watching also fund other game actions (hiring candidates, event rerolls)
- Watching ads to help your startup grow feels thematically appropriate — "watching a pitch video" or "sitting through a sponsor message"

### Rewarded Ad Theming (Player-Facing)

Don't call them "ads." Frame them as startup activities:

| Ad Slot | Player-Facing Label | Tooltip |
|---------|-------------------|---------|
| 1st ad | "Watch a Pitch" | "Sit through a pitch to energize your team" |
| 2nd ad | "Attend a Meetup" | "Network at a local tech meetup for a productivity boost" |
| 3rd ad | "Sponsor Coffee" | "Buy the team coffee (sponsored) for a small push" |

This makes the ads feel like part of the game world, not a monetization interruption.

### Rush via "Crunch Mode" (Team Event)

Not a purchase — a gameplay decision with consequences.

| Action | Effect | Cost |
|--------|--------|------|
| Declare "Crunch Mode" on a feature | Build time -1 quarter | All assigned engineers: +15 stress, -10 morale |
| Declare crunch on upgrade tier | Upgrade time -1 quarter | Same stress/morale hit + 10% chance of burnout event |

This is the free path that creates tension. You CAN rush for free, but your team suffers. It's a real startup decision — "do we crunch to hit the deadline?"

---

## VC Chip Economy (Updated)

### Current Earn Rates (unchanged)
- Quarter with positive cash: +1 chip
- Feature shipped: +1-2 chips (quality-scaled)
- Milestone: +2-5 chips
- Offline return: +1-4 chips
- Rewarded ad: +5 chips (3/day max)

### Current Spend Actions
| Action | Cost | Status |
|--------|------|--------|
| Extra hiring candidate | 3 chips | Exists |
| Reroll event choices | 4 chips | Exists |
| Feature progress +10% | 5 chips | Exists → **REPLACE with new rush** |
| Double idle income 1hr | 6 chips | Exists |
| Office theme unlock | 10 chips | Exists |

### New Spend Actions
| Action | Cost | Notes |
|--------|------|-------|
| Rush: skip 1 build quarter | 5 chips | Replaces old +10% boost |
| Rush: instant complete | 10-25 chips | Scales with remaining time |
| Rush: instant upgrade | 8-20 chips | Scales with tier |
| Unlock build slot (permanent) | 8/15/25 chips | One-time per slot |

### Economy Balance Check

**Average chips earned per quarter:** ~2-4 (profitable quarter + occasional feature ship + milestone)
**Average chips from ads per day:** ~5 (if player watches 1 ad)

A player earning ~3 chips/quarter can rush 1 feature build every 2 quarters — feels fair. They can afford a slot unlock every 3-5 quarters if they save. A player watching ads daily can rush more aggressively.

**Free player path:** Never stuck. Features just take longer. A complete 10-feature run takes ~22 quarters (vs ~10 quarters if rushing everything). That's 5.5 in-game years — well within the 5-10 year target game length.

**Paying player path:** VC Chips are earned, not purchased with real money (currently). If you add a "buy chips" IAP in the future, pricing would be:
- 25 chips for $0.99
- 60 chips for $1.99
- 150 chips for $4.99

But this is v2 territory. For v1, chips are earned only.

---

## What Changes in Code

### ProductData Changes
```
# Add to product_data.gd:
var build_slots: int = 1                          # current slot count
var build_queue: Array[Dictionary] = []            # [{feature_id, progress, quarters_remaining}]
var feature_upgrades: Dictionary = {}              # {feature_id: tier_level}
const MAX_BUILD_SLOTS := 4

# Change: target_feature_id → build_queue[0].feature_id (primary slot)
# Change: feature_progress → build_queue[N].progress (per-slot)
```

### SimulationEngine Changes
- Quarter advance now iterates over `build_queue` instead of single feature
- Each slot advances independently based on assigned engineer count
- Feature ships when its slot progress hits 1.0

### CurrencyManager Changes
- Replace `COST_FEATURE_BOOST` with `COST_RUSH_QUARTER := 5`
- Add `COST_RUSH_INSTANT_BASE := 10`
- Add `COST_SLOT_UNLOCK: Array = [8, 15, 25]`
- Add `spend_rush_quarter()`, `spend_rush_instant()`, `spend_slot_unlock()`

### UI Changes
- Product Overview: build queue display (N slots with progress bars)
- Each slot: feature name, ETA, "Rush" button (shows chip cost or ad option)
- "Crunch Mode" toggle per slot (with warning about morale cost)
- Slot unlock button (shows chip cost or "Hire N engineers" requirement)

### Estimated Implementation Effort
| Component | Lines of Code | Complexity |
|-----------|--------------|------------|
| ProductData build queue | ~80 | Low (data model extension) |
| SimulationEngine multi-slot | ~60 | Medium (loop refactor) |
| CurrencyManager rush actions | ~40 | Low (new spend functions) |
| Product Overview UI | ~200 | Medium (new UI section) |
| Feature upgrade system | ~120 | Medium (new mechanic) |
| Crunch Mode event | ~50 | Low (stress/morale effects) |
| **Total** | **~550 lines** | **~3-4 sessions of work** |

---

## Open Questions (Need Your Input)

1. **Should premium ($2.99) players get a permanent extra slot?** e.g., premium = start with 2 slots instead of 1. Makes the purchase feel more tangible.

2. **Should feature upgrades be visible in the phone mockup?** This is where the "website evolving" visual really pays off — upgrade tiers change the mockup. But it means more art assets (4 tiers × 10 features × 4 types = 160 variations, which is too many). Likely do 4 tiers × 4 composites per type = 64 images total.

3. **Crunch Mode as a free rush alternative — too punishing or not enough?** +15 stress / -10 morale is significant but recoverable. Should there be a risk of someone quitting?

4. **Should the 10th feature be gated behind upgrade tiers?** i.e., you can't build feature 10 until you've upgraded at least 3 features to Tier 2. Creates a natural progression gate.

---

*This is a design doc, not a commitment. Review before implementing.*
