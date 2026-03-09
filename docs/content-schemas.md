# Venture — Content Schemas & Generation Guide

> Reference doc for all narrative content data formats and how to batch-generate
> them during development. See `docs/ai-integration.md` for the full AI spec.

---

## Event Schema (Enhanced)

Events live in `src/data/events.json`. Each event supports template variables
and multiple text variations for replay variety.

```json
{
  "id": "unique_snake_case_id",
  "title": "Short Title (2-4 words)",
  "category": "people | product | money | market | culture | legal",
  "stage": "early | growth | late | any",
  "company_types": ["saas", "consumer", "marketplace", "devtools"],
  "trigger_conditions": {
    "employee_count": 3,
    "quarter": 2,
    "users": 1000,
    "cash": 50000,
    "has_raised_funding": false
  },
  "weight": 1.0,
  "one_time": false,
  "cooldown_quarters": 4,
  "description_template": "Default text with {variables}.",
  "variations": [
    "Alternate phrasing 1 with {variables}.",
    "Alternate phrasing 2 with {variables}.",
    "Alternate phrasing 3 with {variables}."
  ],
  "choices": [
    {
      "label": "Button text (short)",
      "effects": {
        "cash": -5000,
        "morale_all": -5,
        "tech_debt": -10,
        "bugs": 3,
        "reputation": 10,
        "users": 2000,
        "stress_all": 10,
        "remove_employee": false,
        "employee_salary_multiplier": 1.2,
        "equity_dilution": 0.5,
        "salary_increase_pct": 30,
        "fundraising_opportunity": true,
        "lose_best_engineer": false,
        "equity_grant_pct": 0.5,
        "game_win": "acquisition"
      },
      "outcome_template": "What happens after choosing, with {variables}.",
      "outcome_variations": [
        "Alternate outcome 1 with {variables}.",
        "Alternate outcome 2 with {variables}."
      ]
    }
  ]
}
```

**Template variables:** `{company_name}`, `{employee_name}`, `{employee_role}`,
`{competitor_name}`, `{cash}`, `{burn_rate}`, `{runway}`, `{user_count}`,
`{quarter}`, `{year}`, `{revenue}`, `{employee_count}`, `{tech_debt}`,
`{salary_increase}`, `{current_salary}`

---

## Employee Bio Schema

Bios will live in `src/data/employee_bios.json`. Used by HiringEngine to give
generated candidates personality and backstory.

```json
[
  {
    "id": "bio_bootcamp_001",
    "bio_template": "{name} graduated from a coding bootcamp 6 months ago. Writes clean code, asks good questions, and brings donuts to standup.",
    "personality": "ambitious",
    "seniority_range": ["junior"],
    "specialty_range": ["frontend", "backend", "mobile"]
  },
  {
    "id": "bio_exfaang_001",
    "bio_template": "{name} spent 4 years at Google before burning out on bureaucracy. Wants to work on something that matters — their words, not yours.",
    "personality": "perfectionist",
    "seniority_range": ["senior", "lead"],
    "specialty_range": ["backend", "devops", "data"]
  }
]
```

**Personality types:** `ambitious`, `chill`, `perfectionist`, `chaotic`, `mentor`, `introvert`

**Target: 200+ bios** across this mix:
- ~40 fresh grads / bootcamp grads
- ~40 ex-FAANG engineers
- ~40 career changers (teacher→dev, musician→designer, etc.)
- ~40 international talent
- ~40 unique characters (genius dropout, overqualified vet, etc.)

### Batch Generation Prompt

```
Generate 50 employee bio templates for a tech startup sim game.
1-2 sentences each. Use {name} as a placeholder for the actual name.

Mix of backgrounds:
- 10 fresh grads / bootcamp grads
- 10 ex-FAANG engineers
- 10 career changers (teacher → dev, musician → designer, etc.)
- 10 international talent
- 10 unique/memorable characters

Output as JSON: [{"id": "...", "bio_template": "...", "personality": "...",
"seniority_range": [...], "specialty_range": [...]}]
```

---

## News Headline Schema

Headlines will live in `src/data/news_headlines.json`. Displayed in a news
ticker each quarter to create atmosphere and context.

```json
[
  {
    "id": "headline_funding_001",
    "headline_template": "{competitor_name} raises $50M Series B to challenge {company_name} in enterprise market",
    "category": "funding",
    "involves_player": true,
    "stage": "growth"
  },
  {
    "id": "headline_layoffs_001",
    "headline_template": "Major tech layoffs continue: 10,000 jobs cut across the sector this quarter",
    "category": "layoffs",
    "involves_player": false,
    "stage": "any"
  }
]
```

**Categories:** `funding`, `launch`, `scandal`, `regulation`, `market`, `layoffs`, `ipo`, `acquisition`

**Target: 150+ headlines** — ~30% reference player/competitor, ~70% general industry

### Batch Generation Prompt

```
Generate 100 tech industry news headlines for a startup sim game.
One line each. TechCrunch/Verge style.

Categories (roughly equal distribution):
- Funding rounds, Product launches, Layoffs/shutdowns
- Regulatory news, Market shifts, Acquisitions
- Scandals/controversies, IPOs

~30 should reference {player_company} or {competitor_name}.
~70 should be general industry news.

Output as JSON: [{"id": "...", "headline_template": "...",
"category": "...", "involves_player": bool, "stage": "any|early|growth|late"}]
```

---

## VC Dialogue Schema

VC dialogue will live in `src/data/vc_dialogue.json`. Used during fundraising
meetings and term sheet presentations.

```json
[
  {
    "id": "vc_pitch_001",
    "type": "pitch_response",
    "template": "Interesting. Your ARR growth is impressive, but I'm concerned about churn. What's your plan to get retention above 90%?",
    "stage": "early",
    "sentiment": "cautious"
  },
  {
    "id": "vc_offer_001",
    "type": "term_sheet",
    "template": "We'd like to lead your Series A. $5M at a $20M pre-money valuation. We'll want a board seat.",
    "stage": "growth",
    "sentiment": "positive"
  }
]
```

**Target: 30+ variations** across pitch meetings, term sheets, rejections, and celebrations.

---

## Quarterly Report Narrative Schema

Templates in `src/data/quarterly_reports.json` for the end-of-quarter summary.

```json
[
  {
    "id": "report_growth_001",
    "type": "growth",
    "template": "Strong quarter for {company_name}. User growth hit {user_count}, up from last quarter. Revenue is trending in the right direction at {revenue}. The team of {employee_count} is finding their rhythm.",
    "conditions": { "users_grew": true, "revenue_grew": true }
  },
  {
    "id": "report_crisis_001",
    "type": "crisis",
    "template": "Rough quarter. Cash is at {cash} with {runway} of runway. The team is feeling the pressure — morale is fragile. Something needs to change.",
    "conditions": { "runway_low": true }
  }
]
```

**Target: 20+ templates** covering growth, crisis, plateau, breakthrough, and milestone quarters.

---

## Game Over Postmortem Schema

Templates in `src/data/postmortems.json` for the game-over summary screen.

```json
[
  {
    "id": "postmortem_bankrupt_001",
    "loss_type": "bankruptcy",
    "template": "{company_name} ran out of money in Year {year}, Quarter {quarter}. At its peak, the company had {peak_users} users and {peak_employees} employees. In the end, {final_cash} wasn't enough to keep the lights on.",
    "tone": "reflective"
  },
  {
    "id": "postmortem_burnout_001",
    "loss_type": "founder_burnout",
    "template": "After {total_quarters} quarters of non-stop building, you couldn't do it anymore. {company_name} had {user_count} users and was {profitability_status}. But the cost was too high.",
    "tone": "bittersweet"
  }
]
```

**Target: 10+ templates** — at least 2 per loss condition type (bankruptcy, dead product, founder burnout, board takeover).

---

## Competitor Description Schema

Templates in `src/data/competitors.json` for AI competitor companies.

```json
[
  {
    "id": "comp_vc_darling",
    "name_template": "{random_prefix}ly",
    "product_template": "A slick {company_type} tool that's getting buzz on Product Hunt",
    "strategy": "growth_at_all_costs",
    "aggression": 0.8,
    "starting_users": 500,
    "starting_cash": 2000000
  }
]
```

**Target: 50+ competitor templates** with varied strategies and aggression levels.

---

## Scenario Pack Schema

Scenario packs are JSON config files in `src/data/scenarios/`. Zero new code needed.

```json
{
  "id": "dotcom_boom",
  "name": "Dot-Com Boom",
  "description": "Start in 1998. Money is everywhere. Then it isn't.",
  "starting_year": 1998,
  "starting_cash_multiplier": 1.5,
  "economy_state": "bull",
  "economy_shift_quarter": 12,
  "economy_shift_to": "recession",
  "fundraising_difficulty_multiplier": 0.5,
  "competitor_count": 6,
  "unique_events": ["dotcom_crash", "irrational_exuberance", "pets_dot_com"],
  "flavor_text": "Everyone's getting funded. Every idea seems brilliant. What could go wrong?"
}
```

**Included in base game:** "Modern Day", "Bootstrapper's Dream"

**Free post-launch drops:** "Dot-Com Boom", "The Social Era", "The AI Gold Rush",
"Pandemic Pivot", "Crypto Winter", "The TikTok Effect"

---

## Content Generation Workflow

1. **Write 5-10 examples by hand** — Establish tone and quality bar
2. **Use Claude/GPT to batch-generate** — Paste examples + schema + prompts from this doc
3. **Hand-edit every generated piece** — Fix tone, ensure tradeoffs are genuinely hard, remove obvious right answers
4. **Playtest** — Does it feel fresh across 3+ runs? Cut events that feel stale.
5. **Iterate** — Add events that fill narrative gaps you notice during playtesting

---

*All content is pre-baked into JSON files at build time. Zero runtime AI needed for v1.0.*
