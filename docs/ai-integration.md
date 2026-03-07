# Venture — AI Integration Spec

> Game mechanics are **always deterministic**. AI is used **only for narrative text**.
> This separation is non-negotiable.

---

## Overview

Venture is 100% offline-first. All simulation, balance, and scoring run locally
with zero AI dependency. AI enhances the narrative layer only — event descriptions,
employee bios, news headlines, and quarterly reports.

| Mode | Runtime AI? | Internet? | Extra Download? | Quality |
|------|-------------|-----------|-----------------|---------|
| Classic | No | No | No | Hand-crafted templates |
| Dynamic | On-device LLM | No (after download) | ~700MB model | AI-personalized |
| Online | Cloud API | Yes | No | Highest quality |

**The game must be fully playable and fun in Classic Mode with zero AI.**

---

## Three-Tier Content System

### Tier 1: Classic Mode (v1.0 — ships first)

Pre-written templates with variable substitution. 100% offline. Zero latency.
All content baked into JSON data files at build time.

### Tier 2: Dynamic Mode (v1.2+)

On-device small LLM (Llama 3.2 1B, ~700MB one-time download).
100% offline after download. Enhances narrative text only.

### Tier 3: Online Mode (v1.3+)

Cloud API (Claude Haiku / GPT-4o-mini) for highest quality generation.
Requires internet. Costs ~$0.01 per game session. Optional toggle.

---

## Classic Mode — Template Variable System

Templates use `{variable_name}` syntax. The TemplateEngine resolves variables
from the current GameState before displaying text.

### Available Template Variables

```
{company_name}        — Player's company name
{company_type}        — "SaaS B2B", "Consumer App", etc.
{employee_name}       — Relevant employee's name
{employee_role}       — "Senior Backend Engineer", etc.
{employee_salary}     — Formatted salary string
{competitor_name}     — AI competitor company name
{cash}                — Current cash formatted (e.g., "$1.2M")
{burn_rate}           — Quarterly burn formatted
{runway}              — Quarters of runway remaining
{user_count}          — Current user count formatted
{quarter}             — Current quarter number
{year}                — Current in-game year
{revenue}             — Current quarterly revenue formatted
{employee_count}      — Total employee count
{tech_debt}           — Tech debt score (0-100)
{salary_increase}     — Percentage for salary-related events
{current_salary}      — Dollar amount for salary-related events
```

### Event JSON Schema (Enhanced)

```json
{
  "id": "string — unique identifier",
  "title": "string — short display title",
  "category": "people | product | money | market | legal",
  "stage": "early | growth | late | any",
  "company_types": ["saas", "consumer", "marketplace", "devtools"],
  "trigger_conditions": {
    "employee_count": 3,
    "min_quarter": 1,
    "min_cash": 0,
    "has_raised_funding": false
  },
  "weight": 1.0,
  "one_time": false,
  "cooldown_quarters": 0,
  "description_template": "string — default template with {variables}",
  "variations": [
    "alternate phrasing 1 with {variables}",
    "alternate phrasing 2 with {variables}"
  ],
  "variables_required": ["employee_name", "competitor_name"],
  "choices": [
    {
      "label": "string — button text",
      "effects": {
        "cash": 0,
        "morale_all": 0,
        "tech_debt": 0,
        "bugs": 0,
        "reputation": 0,
        "users": 0,
        "stress_all": 0,
        "remove_employee": false,
        "employee_salary_multiplier": 1.0,
        "equity_dilution": 0.0
      },
      "outcome_template": "string — what happens after choosing",
      "outcome_variations": [
        "alternate outcome 1",
        "alternate outcome 2"
      ]
    }
  ]
}
```

### Employee Bio Schema

```json
{
  "id": "string",
  "bio_template": "1-2 sentences with optional {name} variable",
  "personality": "ambitious | chill | perfectionist | chaotic | mentor | introvert",
  "seniority_range": ["junior", "mid", "senior"],
  "specialty_range": ["backend", "frontend", "mobile", "design"]
}
```

### News Headline Schema

```json
{
  "id": "string",
  "headline_template": "One line, TechCrunch style, with optional {variables}",
  "category": "funding | launch | scandal | regulation | market | layoffs | ipo | acquisition",
  "involves_player": false,
  "stage": "early | growth | late | any"
}
```

### Content Quantity Targets (v1.0)

| Content Type | Minimum | Notes |
|---|---|---|
| Events | 50 unique, 3-5 variations each | Mix across all categories and stages |
| Employee bios | 200 templates | Mix of personalities and backgrounds |
| News headlines | 150 templates | ~30% involve player, ~70% industry |
| VC dialogue | 30 variations | Pitch meetings and term sheet offers |
| Quarterly reports | 20 narrative templates | Summarize quarter outcomes |
| Game over postmortems | 10 templates | Tailored to loss condition type |
| Competitor descriptions | 50 templates | Names, products, strategies |

---

## Dynamic Mode — On-Device LLM (v1.2+)

### Model Specification

**Primary:** Llama 3.2 1B Instruct (Q4_K_M quantization via llama.cpp)
- GGUF format, ~700 MB, ~1.2 GB RAM
- ~25-30 tok/s on iPhone 14+ / modern Android
- Stored in `user://models/`

**Fallback (low-end devices):** SmolLM2 360M (Q8)
- ~400 MB, ~600 MB RAM, ~40+ tok/s

### Integration Architecture

```
Godot GDScript
    │
    ├── LLMManager.gd (autoload singleton)
    │   ├── load_model(path) → bool
    │   ├── generate(prompt, max_tokens) → String
    │   ├── is_loaded() → bool
    │   └── unload_model()
    │
    ▼
LLMBridge (GDExtension — C++)
    │   Wraps llama.cpp. Runs inference on background thread.
    │   Emits signal on completion.
    │
    ▼
llama.cpp (statically linked)
    │
    ▼
GGUF model file (on disk)
```

### Generation Rules

1. **Max tokens:** 120 for events, 60 for bios, 40 for headlines
2. **Temperature:** 0.7
3. **Timeout:** 5 seconds — fall back to Classic Mode if exceeded
4. **Validation:** 20-500 chars, no code blocks, no markdown headers, no "I'm an AI"
5. **Threading:** Always background thread, never block UI
6. **Caching:** Cache last 20 generated texts per session
7. **Battery:** Show warning in settings

### Fallback Logic

Dynamic Mode **always** falls back to Classic Mode templates if generation
fails, times out, or returns invalid text. The player never sees an error.

### Model Download Flow

Model is NOT bundled with the app. When player enables Dynamic Mode:
1. Confirmation dialog (explains ~700MB download, offline after)
2. Background download with progress bar in Settings
3. Download complete → model verified → Dynamic Mode active
4. If download fails → graceful error, stays in Classic Mode

---

## Online Mode — Cloud API (v1.3+)

### Proxy Architecture

**NEVER ship API keys in the app.** All calls go through a proxy:

```
Godot App → HTTPS → Proxy Server → Anthropic/OpenAI API
                        │
                        ├── Holds API keys
                        ├── Rate limits per device (10 req/min)
                        ├── Caches common generations (LRU, 1hr TTL)
                        ├── Logs usage for cost monitoring
                        └── Kill switch if costs spike
```

**Proxy:** Cloudflare Worker or Vercel Edge Function (free tier, ~50 lines)

**Model:** Claude Haiku — ~$0.001/generation, ~$0.10-0.20/playthrough

---

## What AI Does vs. Doesn't Do

### AI GENERATES (narrative only):
- Event descriptions and dialogue
- Employee bios and personality flavor
- News ticker headlines
- Quarterly report narrative summaries
- VC pitch meeting dialogue
- Competitor descriptions
- Board meeting commentary
- Game over postmortem narrative

### AI NEVER GENERATES (always deterministic):
- Stat changes (cash, morale, skill, users, etc.)
- Event trigger conditions or choice effects
- Revenue / cost calculations
- Win / loss conditions
- Game balance values
- Difficulty modifiers
- Competitor AI behavior
- Anything the player relies on for strategic decisions

---

## Real-World Scenario Packs

Pre-built starting scenarios (JSON config files, not AI-generated):

**Included in base game:**
- "Modern Day" — Current market conditions
- "Bootstrapper's Dream" — No VC available, revenue-funded only

**Free post-launch content drops:**
- "Dot-Com Boom" — Start in 1998. Money everywhere. Then it isn't.
- "The Social Era" — Start in 2010. Mobile exploding.
- "The AI Gold Rush" — Start in 2023. Every VC wants AI.
- "Pandemic Pivot" — March 2020. World locks down.
- "Crypto Winter" — Went all-in on Web3. Market crashed.
- "The TikTok Effect" — Viral moment. 500K users overnight.

These are just JSON config files (starting cash, market conditions, era events).
Zero new code. Great for ongoing engagement.

---

## Build Order

| Phase | What | When |
|-------|------|------|
| Development | Use Claude/GPT to batch-generate content library | During Phases 1-4 |
| v1.0 Ship | Classic Mode only. All content pre-baked in JSON. Zero runtime AI. | Week 13 |
| v1.2 | Dynamic Mode. llama.cpp GDExtension. Model download. Fallback system. | Week 20 |
| v1.3 | Online Mode. Proxy server. Cloud API integration. | Week 28+ |

---

*AI paints the picture; the engine runs the simulation.*
