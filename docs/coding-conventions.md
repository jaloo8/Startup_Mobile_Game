# Venture — Coding Conventions & Patterns

A quick reference for anyone working on the codebase. Follow these conventions to keep the game stable, readable, and easy to extend.

Last updated: March 2026

---

## Architecture Overview

### Singletons (Autoloads)

| Autoload | File | Role |
|----------|------|------|
| `GameState` | `src/autoload/game_state.gd` | All run state (company, employees, product, financials, market, history). Central save/load hub. |
| `SceneLoader` | `src/autoload/scene_loader.gd` | Scene transitions with preloaded cache and deferred calls. |
| `Glossary` | `src/autoload/glossary.gd` | Term-definition popups triggered from UI labels. |
| `Analytics` | `src/autoload/analytics.gd` | GameAnalytics wrapper + settings I/O. |
| `AdManager` | `src/autoload/ad_manager.gd` | Ads, IAP, paywall gating. Guarded by `MONETIZATION_TEMP_DISABLED`. |
| `TutorialManager` | `src/autoload/tutorial_manager.gd` | First-run guided overlay with skip/replay support. |
| `UITouchHelper` | `src/autoload/ui_touch_helper_bridge.gd` | Runtime bridge that delegates to `src/ui/ui_touch_helper.gd`. |
| `WorldEventEngine` | `src/autoload/world_event_engine_bridge.gd` | Runtime bridge that delegates to `src/engine/world_event_engine.gd`. |

**Why bridges?** Godot's class-name metadata cache can go stale in the editor. Autoload bridges use `preload()` to guarantee resolution without relying on cached class names.

### Data Model

All game data lives in Resource-based classes under `src/models/`:

- `CompanyData` — company type, cash, office, hosting, founder stats
- `EmployeeData` — skills, morale, personality, assignment
- `ProductData` — features, tech debt, users, churn, scores
- `FinancialsData` — revenue, burn rate, funding history
- `MarketData` — competitors, economy state
- `EventData` — event definitions (loaded from JSON)

### Content (JSON)

All game content lives in `src/data/*.json`. This lets us expand events, features, competitors, headlines, and niches without touching GDScript. Every JSON file has a validator in `tools/backend_smoke.py`.

### Engine Layer

Core simulation logic lives in `src/engine/`. These are stateless functions that read from and write to `GameState`:

- `simulation_engine.gd` — the 12-step quarterly loop
- `event_engine.gd` — event eligibility, selection, and resolution
- `revenue_engine.gd` — per-type revenue calculation
- `competitor_ai.gd` — AI competitor behavior each quarter
- `fundraising_engine.gd` — VC offers and dilution
- `world_event_engine.gd` — multi-quarter macro cycles

---

## Coding Rules

### 1. Scene Navigation

Always use `SceneLoader.goto_scene()` for screen transitions. Never call `get_tree().change_scene_to_file()` directly — it bypasses the preload cache, cleanup hooks, and transition animations.

```gdscript
# Good
SceneLoader.goto_scene("res://src/ui/dashboard/quarter_dashboard.tscn")

# Bad — bypasses SceneLoader entirely
get_tree().change_scene_to_file("res://src/ui/dashboard/quarter_dashboard.tscn")
```

### 2. Constants Over Magic Numbers

Define gameplay constants at the top of the relevant class. Reference them everywhere instead of hardcoding.

```gdscript
# In game_state.gd
const GAME_VERSION := "0.1.0"

# In product_data.gd
const REVENUE_MULT_MIN := 0.1
const REVENUE_MULT_MAX := 5.0
```

When clamping values, derive bounds from the data (e.g., `CompanyData.OFFICE_CAPACITY.size() - 1`) rather than hardcoded integers that drift when content changes.

### 3. Null Guards for GameState Properties

Any code that runs during scene init or event callbacks should guard against uninitialized state, especially `GameState.company` and `GameState.product`. These are null between a save deletion and the next `new_game()` call.

```gdscript
if GameState.company == null or GameState.product == null:
    return
```

### 4. Event Cooldowns and New Game Hygiene

Static data (like `EventEngine._cooldowns`) persists across scene reloads because the engine scripts stay loaded. Always clear caches in `GameState.new_game()`:

```gdscript
EventEngine.reset_cooldowns()
```

If you add any new static/module-level caches to engine scripts, add a matching reset call in `new_game()`.

### 5. Shared Logic — No Duplication

If the same calculation is used in multiple places (e.g., `responsibility_stage`), define it once as a `static func` on the engine class that owns it, and call it from everywhere else.

```gdscript
# In simulation_engine.gd
static func responsibility_stage(state) -> String:
    var count := state.employees.size()
    if count <= 6: return "early"
    if count <= 20: return "growth"
    return "scale"

# In other files
var stage := SimulationEngine.responsibility_stage(GameState)
```

### 6. Feature Effects and Pending Bonuses

Feature effects like `reputation_bonus` should not apply inline during `apply_feature_effects()` because they depend on `GameState` and would create tight coupling. Instead, accumulate into a pending variable and drain at the call site.

```gdscript
# In product_data.gd
var _pending_reputation_bonus: int = 0

func drain_pending_reputation_bonus() -> int:
    var bonus := _pending_reputation_bonus
    _pending_reputation_bonus = 0
    return bonus
```

### 7. Clamping and Bounds

Always clamp gameplay values to sane ranges in `clamp_all()` methods and during deserialization (`_clamp_deserialized_values()`). This prevents unbounded growth from stacking effects or save file tampering.

Key ranges to enforce:
- `revenue_mult` → `[0.1, 5.0]`
- `office_level` → `[0, OFFICE_CAPACITY.size() - 1]`
- `competitor users` → growth cap per quarter (currently `10_000_000`)
- `morale`, `skill`, `stress` → `[0, 100]`

### 8. Save/Load Safety

- Writes go through a temp file + atomic rename + checksum wrapper.
- Always write `.bak` before overwriting the primary save.
- On load, verify checksum first; if corrupt, fall back to `.bak`.
- History and event log are compacted (windowed) during serialization to keep payload size bounded.
- Deep-copy all data before async writes to avoid mutation during serialization.

### 9. UI Layout Conventions

- Use `ScrollContainer` → `MarginContainer` → `VBoxContainer` for any screen with variable-length content.
- Top-level scene root is a `Control` or `PanelContainer` anchored full-rect.
- Touch targets: minimum 44px height, 48px preferred. Use `UITouchHelper.harden_tree()` to enforce.
- Never hardcode pixel positions — use anchors, size flags (`SIZE_EXPAND_FILL`), and containers.
- Keep the `PrivacyPanel` / overlay nodes as siblings of the scroll, not children.

### 10. User-Facing Text

- No internal file paths, code syntax, or model names in player-visible text.
- Use plain English for labels and hints ("next quarter" not "simulation", "above 97%" not ">=97%").
- Glossary terms should use `short` for inline display and `tip` for the popup.
- Version strings should reference `GameState.GAME_VERSION` everywhere — never hardcode.
- Comments referencing AI tools or internal tooling should not appear in shipped code.

### 11. Event & Headline Data Quality

- Every event choice that promises a reward in its label/outcome text must have a matching effect key (e.g., mentions "grant money" → needs `"cash": X`).
- Event categories must use the canonical set: `people`, `product`, `money`, `market`, `culture`. Not aliases like "finance".
- Headlines with dollar amounts must include the number (no templates like `"hit  billion"`).
- Every niche ID in `niches.json` should have at least one competitor tagged with it in `competitors.json`.
- Glossary keys must be unique case-insensitively (no `"mrr"` and `"MRR"` as separate entries).

### 12. Comment Style

- Write comments that explain *why*, not *what*.
- Avoid narration comments (`# increment the counter`, `# return the value`).
- Use `## Section header` for class-level documentation blocks.
- Mark animation/visual placeholders with `# VISUAL_HOOK:` so art passes can find them easily.

---

## Validation & Testing

### Backend Smoke Test

Run after every meaningful change:

```bash
python3 tools/backend_smoke.py
```

This validates:
- JSON structure for all 9 data files
- Feature prerequisite integrity
- Visual preset ID coverage
- Difficulty multiplier shape (sandbox > normal > hardcore for cash, reverse for churn)
- Monetization stability gate (`MONETIZATION_TEMP_DISABLED = true`)
- Runtime bridge wiring in `project.godot`
- UI button/signal contracts (12 screens)
- Scroll container layout contracts (6 screens)
- Glossary near-duplicate detection
- Niche-competitor coverage (every niche has tagged rivals)
- Headline content quality (no broken dollar amounts)
- Version constant presence and usage
- Event cooldown reset wiring
- History snapshot completeness
- SceneLoader-only scene transitions

### QA Smoke Checklist

Full manual test: `docs/qa-smoke-checklist.md` (~30-40 min).
Quick regression pass (items marked with star): ~15 min.

### Adding New Smoke Checks

When you fix a bug or add a new contract, add a matching check to `backend_smoke.py` so the same class of bug can't recur. The pattern:

1. Write a `validate_*` function returning `List[str]` of error messages.
2. Call it in `main()`.
3. Update the PASSED banner text.

---

## Common Pitfalls

| Pitfall | What Happens | Prevention |
|---------|-------------|------------|
| Using `change_scene_to_file` | Bypasses preload cache and transition hooks | Always use `SceneLoader.goto_scene()` |
| Hardcoded office level cap | Breaks when office tiers are added | Use `CompanyData.OFFICE_CAPACITY.size() - 1` |
| Forgetting to reset static caches on new game | Old-run data leaks into fresh games | Add reset calls in `GameState.new_game()` |
| Duplicate glossary keys | JSON keeps last value silently, first definition lost | Run smoke test (near-dupe check) |
| Untagged niches | Players in that niche never see relevant competitors | Run smoke test (niche-competitor coverage) |
| Missing effect keys on event choices | Player sees reward text but nothing happens | Audit effect dict matches label/outcome text |
| Paywall fallback granting access | `on_unlock` called when `AdManager` unavailable | Fallback should call `on_cancel` |
| Unbounded multiplier stacking | `revenue_mult` or user growth grows to infinity | Clamp in `apply_feature_effects()` and `clamp_all()` |
| Feature count checked as `> 0` instead of quarter-over-quarter | Board patience never drops after first feature ships | Compare `feature_count()` to history snapshot |

---

## File Naming

- GDScript: `snake_case.gd`
- Scenes: `snake_case.tscn`
- JSON data: `snake_case.json`
- Docs: `kebab-case.md`
- Assets: `snake_case.png` / `snake_case.wav`

---

## Adding New Content

### New Event

1. Add to `src/data/events.json` with all required fields (`id`, `title`, `description`, `choices`, `category`, `weight`).
2. Ensure every choice has an `effects` dict with valid keys (see `EVENT_EFFECT_KEYS` in `backend_smoke.py`).
3. If the event is niche-specific, add `"niches": ["niche_id"]`.
4. Run `python3 tools/backend_smoke.py`.

### New Feature

1. Add to the relevant company type array in `src/data/features.json`.
2. Include `id`, `name`, `cost`, and `effects` (valid keys in `KNOWN_EFFECT_KEYS`).
3. If it has prerequisites, list them and verify they exist in the same type.
4. If it needs a visual preset, add the ID to `VISUAL_PRESET_FEATURES` in `product_overview.gd`.
5. Run `python3 tools/backend_smoke.py`.

### New Competitor

1. Add to `src/data/competitors.json` with `name`, `focus`, `size`, and `tagline`.
2. Tag relevant `niches` so niche-competitor coverage stays complete.
3. Run `python3 tools/backend_smoke.py`.

### New Niche

1. Add to the relevant company type in `src/data/niches.json` with `id`, `name`, `description`, `modifiers`.
2. Tag at least one competitor in `competitors.json` with the new niche ID.
3. Run `python3 tools/backend_smoke.py`.

### New World Event

1. Add to `src/data/world_events.json` with required fields.
2. Effects must use keys from `WORLD_EVENT_EFFECT_KEYS`.
3. Run `python3 tools/backend_smoke.py`.
