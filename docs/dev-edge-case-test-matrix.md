# Dev Edge-Case Test Matrix

Use this when you want fast, repeatable stress testing across multiple save slots.

## Build Modes

`AdManager` now exposes explicit build modes:

- `Dev` mode: premium features unlocked for local testing convenience.
- `Release` mode: monetization + lock behavior follows production rules.

Mode is shown in `Settings` as:

- `Venture vX.Y.Z · Dev Mode`
- `Venture vX.Y.Z · Release Mode`

### Local Override (optional)

In `src/autoload/ad_manager.gd`:

- `const BUILD_MODE_OVERRIDE := ""` (auto detect)
- set to `"dev"` to force dev behavior
- set to `"release"` to force release behavior

Note: `MONETIZATION_TEMP_DISABLED` is currently `true` for stability-first QA.  
If you want to test paywall/lock flow, temporarily set it to `false` in local testing.

---

## 5-Slot Edge-Case Matrix

Create one run per slot using these presets:

| Slot | Scenario | Company Type | Difficulty | Why this run exists |
|---|---|---|---|---|
| `slot_1` | `Garage` | Consumer | Sandbox | Baseline UX sanity + onboarding clarity |
| `slot_2` | `Garage` | SaaS | Hardcore | Early-economy pressure and bankruptcy edge cases |
| `slot_3` | `VC-Backed` | Marketplace | Normal | Funding/board pressure + event cadence checks |
| `slot_4` | `Growth Operator` | Dev Tools | Hardcore | Mid-game scaling, churn, hosting pressure stress |
| `slot_5` | `Scale Chief` | Consumer | Normal | Late-game throughput, reliability, and long-run save integrity |

If needed, swap company type to target a specific niche or feature tree.

---

## What to Validate Per Slot

Run at least 6-10 quarters in each slot and verify:

1. **Advance flow**: button label matches behavior, no fake advance, no double-advance.
2. **Events gate**: unresolved events block advance and unblock correctly after resolution.
3. **Save/load**: load from slot, continue, then return to menu and re-load same slot.
4. **Navigation**: switch tabs repeatedly (People/Product/Finances/Market) and return with intact state.
5. **Stability**: no visual overlap that hides core actions (especially dashboard bottom actions).
6. **End conditions**: bankruptcy/dead-product/win/game-over transitions behave correctly.

Then run:

```bash
python3 tools/backend_smoke.py
```

And use the star items in `docs/qa-smoke-checklist.md`.

---

## Save Data Locations (macOS)

Godot `user://` resolves to:

- `~/Library/Application Support/Godot/app_userdata/Venture/saves/`
- `~/Library/Application Support/Godot/app_userdata/Venture/settings.json`
- `~/Library/Application Support/Godot/app_userdata/Venture/tutorial.dat`

Slot files:

- `slot_1.json` ... `slot_5.json`
- backup files: `slot_X.json.bak`

---

## Quick Reset Workflow

When starting a fresh matrix pass:

1. Delete or overwrite old slot runs from Save Slots UI.
2. Recreate all five slot scenarios from the table above.
3. Record outcomes (quarter reached, failure/win reason, broken flows).
4. Fix highest-impact bug first, then re-run only affected slots.

