# Venture — Game Design Document

*Working title: "Venture" (change later — ship first, brand second)*

---

## 1. Game Vision

**One-line pitch:** "Pocket GM 3, but for tech startups — a premium mobile management sim where you build a company from garage to IPO."

**Core fantasy:** You are the CEO/founder of a tech startup. You make every strategic decision — what to build, who to hire, when to raise money, when to pivot. The game simulates realistic consequences. Some decisions pay off quarters later. Others blow up in your face immediately.

**Target platform:** iOS and Android (Godot 4.3), Steam/desktop future
**Monetization:** Free (ad-supported) or Premium $4.99 (no ads) + $2.99 DLC packs per path
**Session length:** 10–20 minutes (one "quarter" per session, natural stopping points)
**Total game length:** 20–40 quarters (5–10 years of startup life per run)

---

## 2. Core Game Loop

Each in-game **quarter** follows this cycle:

```
┌─────────────────────────────────────────────┐
│  1. INBOX — Read events, news, requests     │
│  2. PEOPLE — Hire, fire, promote, manage     │
│  3. PRODUCT — Allocate team to work items    │
│  4. MONEY — Revenue, costs, fundraise        │
│  5. STRATEGY — Marketing, partnerships, etc  │
│  6. ADVANCE — Simulate quarter, see results  │
│  7. BOARD REVIEW — Quarterly scorecard       │
└─────────────────────────────────────────────┘
```

The player can visit these screens in any order before hitting "Advance Quarter." This is the PGM3 model — do your management, then sim forward.

---

## 3. Game Systems

### 3.1 Company Setup (Game Start)

Player chooses at game start:

**Industry Path** → **Company Type** within that path.

Paths are the macro category (Software, Hardware, AI). Company Types are the specific business model within that path. Each combination creates a fundamentally different game experience with unique mechanics, employee specialties, cost structures, and win conditions.

---

#### PATH 1: SOFTWARE (Included in base game — v1.0)

The classic tech startup experience. Your product is code. Revenue comes from users paying for access to that code.

**Company Types within Software:**

**SaaS B2B Tool**
- *Fantasy:* Build the next Slack, Notion, or Datadog
- *Unique mechanic: Sales Pipeline.* Enterprise deals take 1–3 quarters to close. You need SDRs and Account Executives. Deals have stages (Lead → Demo → Trial → Negotiation → Closed). Bigger deals = more revenue but longer cycles and risk of deals falling through.
- *Key metric:* ARR (Annual Recurring Revenue), Net Revenue Retention
- *Revenue:* Subscription tiers (Free → Pro → Enterprise). Upselling existing customers is cheaper than acquiring new ones.
- *Unique tension:* Do you build the feature your biggest client demands (keeps them, but makes your product niche) or the feature that appeals to the broader market?
- *Employee needs:* Backend engineers, sales team, customer success
- *Hosting costs:* Scale with customer count, but enterprise clients demand uptime SLAs (99.9%+). Outage = churn.

**Consumer App**
- *Fantasy:* Build the next Instagram, TikTok, or Duolingo
- *Unique mechanic: Virality Engine.* Growth depends on K-factor (how many new users each existing user brings in). Features that increase sharing/invites are more valuable than features that improve the product. You're optimizing for engagement metrics (DAU/MAU ratio, session length, retention curves).
- *Key metric:* DAU, MAU, D1/D7/D30 retention, engagement
- *Revenue:* Ad revenue (CPM × impressions), premium subscriptions, or in-app purchases. Each model has different dynamics.
- *Unique tension:* Dark patterns boost engagement but hurt brand/press coverage. Do you add notifications that feel spammy but drive DAU? Do you add ads that hurt UX but fund growth?
- *Employee needs:* Mobile engineers, designers (critical), growth/marketing, data analysts
- *Hosting costs:* Scale aggressively with users. A viral moment can 10x your cloud bill overnight.

**Marketplace / Platform**
- *Fantasy:* Build the next Airbnb, Uber, or Etsy
- *Unique mechanic: Two-Sided Growth.* You need BOTH supply (sellers/providers) and demand (buyers/users). Chicken-and-egg problem — neither side joins without the other. Must decide which side to subsidize. Liquidity (match rate between supply and demand) is the key health metric.
- *Key metric:* GMV (Gross Merchandise Value), take rate, liquidity
- *Revenue:* Transaction fees (% of each sale/booking). Higher take rate = more revenue but pushes suppliers to competitors.
- *Unique tension:* A supplier is cheating the system (taking transactions off-platform to avoid fees). Crack down and lose them, or tolerate it?
- *Employee needs:* Full-stack engineers, ops/trust & safety, community managers
- *Hosting costs:* Moderate, but payment processing fees eat into margins.

**Dev Tools / Infrastructure**
- *Fantasy:* Build the next Stripe, Vercel, or GitHub
- *Unique mechanic: Developer Ecosystem.* Your users are developers. Growth comes from documentation quality, developer experience (DX), and community/open-source strategy. API stability is critical — breaking changes cause mass churn.
- *Key metric:* API calls, developer accounts, SDK installs
- *Revenue:* Usage-based pricing (pay per API call, compute, storage). Very predictable once established. Enterprise tier with SLAs.
- *Unique tension:* Open source your core to drive adoption (but competitors can fork it) or keep it proprietary (slower adoption but defensible)?
- *Employee needs:* Senior backend engineers (must be elite), DevRel, technical writers
- *Hosting costs:* Very high — you ARE the infrastructure. Reliability is existential.

---

#### PATH 2: AI / ML (DLC Pack #1 — "The Intelligence Age" — $2.99)

The AI gold rush. Compute is your biggest cost. The talent war is brutal. The hype cycle is your best friend and worst enemy.

**Shared AI Path Mechanics (apply to all types below):**
- *GPU/Compute Budget:* A dedicated resource you must manage. Training runs cost thousands to millions. You choose between cloud GPU rental (flexible but expensive per-hour) vs. buying your own cluster (huge upfront, cheaper long-term, risk of obsolescence).
- *Model Quality Score (1–100):* Your AI's capability. Improves through training runs, better data, and research breakthroughs. Directly affects product quality and competitiveness.
- *Data Moat:* Proprietary data you've collected. More data = better models = better product = more users = more data. The flywheel.
- *Hype Cycle Events:* Market sentiment toward AI swings between euphoria and "AI winter." During hype: easy fundraising, high valuations, talent available. During winter: funding dries up, customers skeptical, layoffs industry-wide.
- *Talent War:* AI/ML engineers cost 2–3x normal engineers. They get poached constantly. Retention is a core challenge.
- *Regulatory Risk:* New AI regulations can mandate compliance requirements that cost quarters of engineering time.

**Company Types within AI:**

**AI SaaS / API Product**
- *Fantasy:* Build the next OpenAI API, Anthropic, or Hugging Face
- *Unique mechanic: Inference Economics.* Every API call costs you compute. You must price above your per-call cost, but competitors are racing to zero. Margin compression is constant. Model efficiency improvements (quantization, distillation) directly improve margins.
- *Revenue:* Usage-based API pricing (tokens, calls, compute-seconds)
- *Unique tension:* A bigger company releases a free model that's 80% as good as yours. Do you differentiate on quality, pivot to enterprise, or slash prices?

**AI-Powered Application**
- *Fantasy:* Build the next Jasper, Midjourney, or Cursor
- *Unique mechanic: Build vs. Buy Models.* Do you train your own model (expensive, slow, proprietary) or build on top of someone else's API (fast, cheap, but you're dependent on their pricing and availability)? The "wrapper" vs. "foundational" strategic decision.
- *Revenue:* Subscription (freemium → pro tiers)
- *Unique tension:* The model provider you depend on just raised API prices 3x. Your margins are gone. Scramble to switch providers, build your own model, or raise prices and lose users?

**AI Research Lab**
- *Fantasy:* Build the next DeepMind or Anthropic
- *Unique mechanic: Research Breakthroughs.* Allocate researchers to long-term projects with uncertain payoff. Research has a probability of breakthrough each quarter based on team quality, compute budget, and accumulated progress. Breakthroughs unlock new capabilities that can be commercialized or published for reputation.
- *Revenue:* Enterprise licensing, government contracts, eventual product commercialization. Very back-loaded — you burn cash for years before revenue.
- *Unique tension:* Publish your research (builds reputation, attracts talent, but competitors benefit) or keep it proprietary (short-term advantage, but talent leaves for more open labs)?

---

#### PATH 3: HARDWARE (DLC Pack #2 — "Silicon Dreams" — $2.99)

Entirely different economics. Physical atoms, not bits. Manufacturing is the game. Margins are tight. Timelines are long. One bad chip tape-out can bankrupt you.

**Shared Hardware Path Mechanics (apply to all types below):**
- *R&D Cycles:* Hardware products take 4–8 quarters from design to market (vs. 1–2 for software). You're making bets years in advance on what the market will want.
- *Fabrication/Manufacturing:* You choose between fabless (outsource manufacturing — lower risk, lower margin) or building your own production (massive capex, higher margin, years to set up). Fabless companies depend on foundry relationships.
- *Bill of Materials (BOM):* Physical cost per unit. Unlike software (near-zero marginal cost), every unit you sell has a real cost. BOM optimization is a constant pressure.
- *Supply Chain:* Component shortages, shipping delays, tariffs, and supplier relationships are active management challenges. A single-source component going unavailable can halt production.
- *Inventory Management:* Build too many units = dead stock eating cash. Build too few = missed sales and angry customers. Demand forecasting is a skill.
- *Certification & Compliance:* FCC, CE, UL certifications take time and money. Skipping them limits your markets. Failing certification wastes the investment.
- *Defect Rate:* Manufacturing quality. Higher defect rate = returns, warranty costs, brand damage. Quality control costs money but saves money long-term.

**Company Types within Hardware:**

**Consumer Electronics / IoT Device**
- *Fantasy:* Build the next Sonos, Ring doorbell, or Remarkable tablet
- *Unique mechanic: Product Generations.* You design and release discrete product versions (Gen 1, Gen 2, etc.). Each generation is a major bet — 6+ quarters of development, then a launch event where reviews and sales determine success. Between generations, you release firmware updates (software-like) to sustain engagement.
- *Revenue:* Hardware sales (one-time) + optional subscription service. Hardware margins are 30–50% at best.
- *Unique tension:* Gen 1 sold well but has a hardware flaw. Do you do a costly recall (brand trust) or push a firmware workaround (cheaper but users notice)?

**Chip Design (Fabless Semiconductor)**
- *Fantasy:* Build the next Nvidia, Qualcomm, or Cerebras
- *Unique mechanic: Tape-Out Gamble.* Designing a chip costs millions and takes years. The "tape-out" (sending design to fabrication) is a point of no return — you can't patch silicon. If the design has a critical bug, you've wasted millions and 18+ months. Pre-tape-out verification is critical but never catches everything.
- *Additional mechanic: Process Node Selection.* Smaller process = better performance but exponentially more expensive and longer foundry queue times. Do you target bleeding-edge 3nm (expensive, delays, but fastest chip) or mature 7nm (cheaper, faster to market, but less competitive)?
- *Revenue:* Chip sales to OEMs, licensing IP blocks, or selling compute (if you build your own data center hardware).
- *Unique tension:* Your foundry partner (e.g., TSMC) has limited capacity. A bigger company just booked 80% of next year's allocation. Do you pay a premium for guaranteed slots, switch to a less advanced foundry, or delay your product?
- *Employee needs:* RTL designers, verification engineers, physical design engineers, firmware engineers. Extremely specialized and expensive.
- *Starting capital required:* Much higher ($2M+ minimum). This path starts with the "Corporate spinoff" or "VC-backed" scenario only.

**Robotics / Deep Tech**
- *Fantasy:* Build the next Boston Dynamics, Anduril, or Figure AI
- *Unique mechanic: Prototype Iterations.* Physical prototypes are expensive and slow. Each iteration costs real money and takes 1–2 quarters. You must decide how many prototype cycles to do before committing to production. More iterations = better product, less cash.
- *Additional mechanic: Demo Events.* Robotics companies live and die by demos. A successful public demo can trigger fundraising, press coverage, and government contracts. A failed demo (robot falls over on stage) is devastating. You invest in demo preparation vs. actual product development.
- *Revenue:* Government/defense contracts, enterprise sales, licensing. Very long sales cycles (6–12 months).
- *Unique tension:* A defense contractor wants to fund your development but requires exclusive rights. Take the guaranteed money but lose commercial market? Or stay independent and hope commercial revenue materializes?

---

#### PATH 4: GAMING (DLC Pack #3 — "Press Start" — $2.99)

Project-based creative bets. Every game is a roll of the dice. You're managing creative vision, technical execution, and market timing simultaneously.

**Shared Gaming Path Mechanics:**
- *Project-Based Revenue:* Unlike SaaS (recurring), games are hits-driven. Launch spike → long tail → DLC bumps. One hit funds three misses.
- *Creative Direction:* Games have a Genre, Art Style, and Theme. Matching these to market trends and your team's strengths determines review scores and sales.
- *Review Scores:* Simulated reviews (press + user) based on quality, genre fit, originality, and polish. Scores directly impact sales. A 90+ metacritic equivalent = massive organic sales. Below 60 = flop.
- *Platform Choice:* PC, Console, Mobile, or Multi-platform. Each has different dev costs, audience sizes, revenue shares (Steam 30%, mobile 30%, console licensing fees), and development complexity.
- *Wishlists / Hype:* Pre-launch marketing builds wishlists. Higher wishlist count = bigger launch spike. But overhyping a mediocre game leads to backlash.
- *Crunch Culture:* Pushing for a launch deadline? Crunch boosts short-term output but destroys morale and causes talent to leave post-launch. Industry-realistic.

**Company Types within Gaming:**

**Indie Studio**
- *Fantasy:* Build the next Supergiant, Team Cherry, or LocalThunk
- *Unique mechanic: Creative Bets.* Small team, limited budget, must pick the RIGHT game to make. Genre selection matters enormously. A brilliant game in a dead genre still flops. A decent game riding a trend wave can succeed.
- *Revenue:* Game sales (premium), small DLC packs
- *Unique tension:* Your passion project is a niche genre. Your data says a trending genre would sell 5x more. Follow your heart or follow the market? (This is literally the central tension of indie dev.)

**AA / Mid-Size Studio**
- *Fantasy:* Build the next Larian, FromSoftware, or Firaxis
- *Unique mechanic: Multi-Project Management.* Run 2–3 projects simultaneously with shared staff. Allocate your best people to the project with highest potential, but neglecting other projects means delays and quality drops. Managing multiple timelines and team morale across projects is the challenge.
- *Revenue:* Game sales + DLC + potential live service
- *Unique tension:* Your flagship game needs 2 more quarters of polish, but your publisher is pressuring you to ship for the holiday window. Ship early (buggy launch, patch later) or delay (miss the window, publisher angry)?

**Live Service / F2P**
- *Fantasy:* Build the next Fortnite, Genshin Impact, or Path of Exile
- *Unique mechanic: Seasons and Content Pipeline.* After launch, the game is never "done." You must release seasonal content on a regular cadence to retain players. Miss a season = player drop-off. Content pipeline management (planning 3 seasons ahead while executing the current one) is the core skill.
- *Additional mechanic: Monetization Ethics Spectrum.* A slider from "cosmetics only" to "pay-to-win." More aggressive monetization = more revenue but worse reviews, press backlash, and potential regulation. Community sentiment is a live metric.
- *Revenue:* In-app purchases, battle passes, cosmetic sales. Potentially massive but requires sustained investment.
- *Unique tension:* Players are outraged about a monetization change. Revert it (lose revenue, gain goodwill) or hold firm (keep revenue, community fractures)?

---

#### PATH 5: OS & PLATFORM (DLC Pack #4 — "The Platform Play" — $2.99)

The most ambitious path. You're not building a product — you're building the foundation other people build on. Winner-take-all dynamics. Enormous investment before any return.

**Shared Platform Mechanics:**
- *Developer Ecosystem:* Your platform's value comes from third-party developers building on it. You must attract developers through great documentation, tools, SDKs, and revenue sharing. A platform with no apps/developers is worthless.
- *Compatibility:* Must support existing standards and apps or offer a compelling reason to switch. Breaking compatibility = instant developer abandonment.
- *Network Effects:* More users → more developers → more apps → more users. The flywheel is everything. But it takes years to spin up.
- *Platform Governance:* You control the rules. Fees, content policies, API access. Every decision affects developer trust and user experience.

**Company Types within Platform:**

**Mobile/Desktop OS**
- *Fantasy:* Build a challenger to Android/iOS, or a niche OS (like System76/Pop!_OS)
- *Unique mechanic: App Ecosystem Health.* Track number of apps, quality of top apps, developer satisfaction. You can fund key apps directly to bootstrap the ecosystem.
- *Revenue:* Hardware bundling, app store fees, enterprise licensing
- *Unique tension:* A major app developer threatens to pull their app unless you reduce your app store fee from 30% to 15%. Lose the app (lose users) or lose the margin?
- *Note: This is HARD MODE. Realistic OS development requires enormous teams and capital. Starting scenario should reflect this (corporate spinoff or megafund raise).*

**Developer Platform / Cloud**
- *Fantasy:* Build the next AWS, Vercel, or Shopify
- *Unique mechanic: Platform Reliability.* Uptime is existential. A major outage doesn't just hurt you — it hurts every business built on you. Invest heavily in infrastructure resilience or risk catastrophic cascading failures.
- *Revenue:* Usage-based compute/storage fees, platform subscriptions
- *Unique tension:* A customer is using your platform to host content that violates your TOS but represents 5% of your revenue. Enforce policy or look the other way?

---

### Path Selection Architecture

The system is designed modularly so paths share the core engine but plug in unique mechanics:

```
CORE ENGINE (all paths share this):
├── Employee management (hire/fire/morale/skills)
├── Cash management (burn rate, runway, fundraising)
├── Quarterly turn structure
├── Event system
├── Competitor AI
└── Win/loss conditions

PATH-SPECIFIC MODULES (plugged in based on selection):
├── Revenue model (subscription vs. sales vs. usage vs. transaction)
├── Product system (features vs. hardware generations vs. game projects)
├── Unique resources (GPU compute, BOM costs, fab capacity, etc.)
├── Specialized employee types (chip designers, ML researchers, etc.)
├── Path-specific events (50+ per path)
└── Path-specific win conditions and milestones
```

This means the core game ships with the Software path fully fleshed out (4 company types), and each DLC adds a new path with its own mechanics, events, and company types.

---

**Difficulty:**
- **Sandbox** — Generous starting capital, forgiving market
- **Normal** — Realistic startup economics
- **Hardcore** — Tight runway, aggressive competitors, realistic failure rates

**Starting scenario:**
- Garage bootstrapper ($20K savings) — Software path only
- Accelerator graduate ($125K seed, mentor network, 3-month runway)
- Corporate spinoff ($500K, existing tech, but bureaucratic baggage)
- VC-backed from day one ($2M seed, board seat, growth expectations) — Required for Hardware path

---

### 3.2 People System

This is the heart of the game. Startups are people.

**Employee attributes:**
- **Skill** (1–100) — How good they are at their job
- **Speed** (1–100) — How fast they produce output
- **Growth potential** (Low/Med/High) — How much Skill can increase over time
- **Salary demand** ($) — What they cost per quarter
- **Morale** (1–100) — Affected by overwork, culture, compensation, events
- **Culture fit** (1–100) — How well they mesh with team. Low fit = morale drain on everyone
- **Specialty** (enum) — Frontend, Backend, Mobile, Design, Data/ML, DevOps, Sales, Marketing, Operations. *Specialty now drives a real productivity multiplier (0.9×–1.4×) based on assignment and company type — see `EmployeeData.specialty_mult()`.*
- **Seniority** (Junior/Mid/Senior/Lead/Principal) — Affects output, salary, and mentorship

**Specialty match multipliers (Features assignment):**

| Company type | Best fit (1.35×) | Good fit (1.2×) | Neutral (1.0×) |
|---|---|---|---|
| SaaS B2B | Backend | Frontend, Design | others |
| Consumer App | Mobile | Design (1.25×), Frontend | others (0.9×) |
| Marketplace | Backend (1.3×) | Frontend, Mobile (1.15×) | others |
| Dev Tools | Backend (1.4×) | DevOps (1.25×), Data/ML | others |

Non-Feature assignments: DevOps → Infra (1.4×), Backend → Bugs/Tech Debt (1.3×), Data/ML+Design → R&D (1.3×).

Fit badges ("⚡ Great fit", "✓ Good fit") appear on both candidate cards and team cards so the player always knows who is punching above their stats.

**Hiring flow:**
1. Post a job listing ($5K fee)
2. Receive 3 candidates with partially revealed stats; specialty-fit badge shown immediately
3. Interview to reveal full stats (Skill, Speed, Morale, Growth)
4. Optionally **negotiate salary (−15%)** — one chance; low-culture-fit candidates may walk
5. Hire → **Employee ID badge** pops in (spring animation): avatar, name, title, Skill/Morale/Speed, employee number, hire date — a moment of gratification before the assignment prompt
6. Assignment prompt appears immediately so new hires don't sit idle

**Employee avatars:**
8 Pixar-inspired 3D cartoon portraits, each a distinct character (varied ethnicity, age, style). Selected deterministically from the employee's name hash so the same name always maps to the same face. Displayed on candidate cards, team rows, and the hire badge.

**Key decisions:**
- Hire the expensive senior who ships immediately, or the cheap junior with high growth potential?
- Someone's morale is tanking — give them a raise, reduce their workload, or let them go?
- Your lead engineer got a FAANG offer. Counter-offer at 40% raise, or let them walk?
- Two employees have a conflict. Side with one, mediate, or ignore?
- You need to lay off 2 people to extend runway. Who goes?

**Burnout mechanic:**
- Employees assigned to >100% workload accumulate Stress
- Stress reduces Morale over time
- Low Morale reduces output quality and increases quit probability
- "Crunch" button: temporarily boost output by 50% but Stress skyrockets. Realistic tradeoff.

---

### 3.3 Product System

**Product has these attributes:**
- **Features** (list of completed features, each with quality score 1–100)
- **Tech Debt** (0–100) — Accumulates when you ship fast. Slows all future development. Must allocate team to reduce it.
- **Bugs** (count) — Found by users or QA. Affect user satisfaction.
- **Stability** (1–100) — Server reliability. Low = outages = user churn.
- **UX Score** (1–100) — Affected by design quality. Higher = better conversion/retention.

**Each quarter, you allocate your engineering team across:**
- **New Features** — Build new capabilities (the exciting stuff)
- **Bug Fixes** — Reduce bug count (unsexy but necessary)
- **Tech Debt** — Refactor and clean up (investment in future speed)
- **Infrastructure** — Improve stability and scale (needed before growth spikes)
- **R&D** — Research new technologies (unlocks future feature categories)

This allocation is THE core tension. You always want to build features, but neglecting the others will kill you. Ship too fast → tech debt piles up → development slows to a crawl → competitors catch up. Sound familiar?

**Feature development:**
- Pick from available features (depends on product type and R&D unlocks)
- Assign team members — their Skill, Speed, Morale, and Specialty match all determine quality and speed
- Progress scales with team size: 2 engineers complete a feature roughly 2× faster than 1
- Features have an ETA shown live on the Product screen, including a specialty-fit breakdown
- Quality depends on: developer skill, designer skill, time allocated, tech debt level, specialty match
- A celebration banner appears when a feature ships (colour-coded by quality)

**Shipping decisions:**
- Ship MVP (lower quality, faster to market, more bugs)
- Ship polished (higher quality, slower, fewer bugs, but competitors may beat you)
- Ship with known bugs (save time, risk user backlash)

---

### 3.4 Money System

**Revenue sources (vary by company type):**
- Subscriptions (SaaS/Consumer) — MRR based on user count × conversion rate × price
- Transaction fees (Marketplace) — GMV × take rate
- Ad revenue (Consumer) — DAU × engagement × CPM
- Enterprise contracts (SaaS) — Large lumpy deals, long sales cycles
- Game sales (Game Studio) — Launch spike then long tail

**Cost categories:**
- Salaries (biggest cost — usually 70–80% of burn)
- Cloud/infrastructure (scales with users — can spike unexpectedly)
- Office rent (upgrades unlock capacity for more employees)
- Marketing spend (optional but affects growth)
- Legal/accounting (increases with company size and fundraising)
- Tools & software licenses

**Key financial metrics displayed:**
- Monthly Burn Rate
- Runway (months of cash remaining) — THE most important number
- MRR / ARR (for subscription businesses)
- CAC (Customer Acquisition Cost)
- LTV (Lifetime Value per customer)
- Gross Margin

**Fundraising system:**
- Available after hitting certain milestones (users, revenue, or product progress)
- VC meetings: pitch your metrics, they make offers
- Offers vary: amount, valuation (dilution), board seats, strings attached
- Taking VC money: more runway but pressure to grow fast, board may override decisions
- Bootstrapping: full control but slower, every dollar matters
- Rounds: Pre-seed → Seed → Series A → Series B → Growth (each with different dynamics)

---

### 3.5 Market & Competition System

**Users/Customers:**
- Grow based on: product quality, marketing spend, word-of-mouth, market timing
- Churn based on: bugs, missing features, competitor launches, price
- Different segments (early adopters, mainstream, enterprise) have different needs

**Competitors:**
- 3–5 AI competitors that also develop products, raise money, hire people
- They can launch features before you, poach your employees, undercut your pricing
- You can see their public metrics (users, funding rounds) but not internals
- Competitive moat builds over time through features, brand, and network effects

**Market events:**
- Tech trends (AI hype cycle, crypto winter, remote work boom)
- Economic conditions (bull market = easy fundraising, recession = budget cuts)
- Regulatory changes (privacy laws affect ad-based businesses)
- Platform shifts (new phone OS, API changes break your integrations)

---

### 3.6 Event System (The Drama Engine)

Random and semi-random events that create narrative and force decisions. This is what makes each playthrough unique. Events are weighted by company stage, product type, and previous choices.

**Example events (50+ needed for v1, expandable):**

PEOPLE EVENTS:
- "Your lead engineer got a job offer from [Competitor]. They want a 30% raise to stay."
- "Two team members are in conflict over technical direction. Morale dropping."
- "A junior developer you hired 3 quarters ago just mass-refactored the codebase over the weekend. Tech debt -15, but 3 new bugs introduced."
- "Your designer wants to go part-time to work on a side project. Accept or refuse?"
- "Glassdoor review: Former employee rates your company 2/5 stars. Hiring pipeline quality drops."

PRODUCT EVENTS:
- "Major cloud provider outage. Your app is down for 6 hours. 2% user churn."
- "A user found a security vulnerability and posted it on Twitter. Patch immediately or risk PR disaster."
- "Your biggest enterprise client wants a custom feature. It'll take a full quarter and delays your roadmap, but they represent 30% of revenue."
- "Viral TikTok mentions your product. +50K signups in 48 hours. Can your infrastructure handle it?"

MONEY EVENTS:
- "VC firm reaches out for a coffee chat. Could lead to Series A."
- "Your cloud costs doubled this quarter due to an unoptimized database query."
- "A larger company wants to acquire you for $X. Do you sell?"
- "Your payment processor flagged unusual activity. Revenue frozen for 2 weeks."
- "Economic downturn — VC funding dries up. Extend runway or cut costs?"

MARKET EVENTS:
- "Competitor just raised $50M and is offering your product for free."
- "New regulation requires data privacy compliance. Need 1 engineer for 2 quarters."
- "Tech blog writes a favorable review. +25% organic signups this quarter."
- "Platform you're built on announces they're building the same feature natively."

---

### 3.7 Win/Loss Conditions

**Win conditions (player chooses goal at start or it emerges):**
- **IPO** — Reach $100M+ ARR with profitability. The big exit.
- **Acquisition** — Accept a buyout offer. Score based on valuation.
- **Sustainable Business** — Reach profitability and maintain for 4 consecutive quarters. The indie dream.
- **Unicorn** — Reach $1B valuation (even if not profitable). The VC dream.

**Loss conditions:**
- **Bankruptcy** — Run out of money with no ability to raise or cut costs enough
- **Dead product** — Users drop to zero (or below critical mass for marketplace)
- **Founder burnout** — CEO morale hits zero (new mechanic: you have morale too)
- **Board takeover** — If you took VC money and miss targets repeatedly, board replaces you

**Game Over screen:** Shows a "startup postmortem" — timeline of key decisions, what went right, what went wrong. Shareable.

---

## 4. Technical Architecture

### 4.1 Stack

```
Engine:         Godot 4.3 (Forward Plus)
Language:       GDScript
Platforms:      iOS, Android, Steam/desktop (all from one codebase)
Architecture:   Autoload singletons + Resource-based data model
Data:           Godot Resources (serializable) + JSON for content
State:          All game state in a single GameState autoload
Save system:    Auto-save each quarter, 3 manual save slots (Resource serialization)
UI framework:   Godot Control nodes, custom theme
```

**Why Godot:**
- Cross-platform from day one (iOS, Android, Steam, web, desktop)
- GDScript is fast to iterate with, beginner-friendly
- No server costs, no backend — pure local game
- Godot's scene/node system maps well to UI-heavy management sims
- Free and open source, no revenue share or licensing fees
- Built-in export templates for mobile and desktop

### 4.2 Core Data Model

```
GameState
├── Company
│   ├── name, type, founded_date
│   ├── cash, valuation, equity_owned
│   ├── office_level, office_capacity
│   └── reputation (1-100)
├── Employees[]
│   ├── name, specialty, seniority
│   ├── skill, speed, growth_potential
│   ├── morale, stress, culture_fit
│   ├── salary, tenure
│   └── assignment (feature/bugs/debt/infra/R&D)
├── Product
│   ├── features[], tech_debt, bugs
│   ├── stability, ux_score
│   ├── users, dau, churn_rate
│   └── revenue_model_data
├── Financials
│   ├── cash, burn_rate, runway
│   ├── revenue, costs_breakdown
│   ├── funding_rounds[]
│   └── investors[]
├── Market
│   ├── competitors[]
│   ├── market_trend, economy_state
│   └── pending_events[]
├── Quarter (current)
│   ├── number, year
│   ├── pending_decisions[]
│   └── allocations
└── History
    ├── quarterly_snapshots[]
    └── event_log[]
```

### 4.3 Simulation Engine

The simulation runs when the player hits "Advance Quarter." It processes in order:

```
1. Apply employee assignments → produce work output
2. Calculate feature progress, bugs found/fixed, tech debt changes
3. Calculate user growth/churn based on product quality + marketing
4. Calculate revenue based on users + pricing model
5. Calculate costs (salaries + infra + marketing + overhead)
6. Update cash position, check runway
7. Run competitor AI (they also develop, hire, raise money)
8. Roll for random events (weighted by context)
9. Update all employee morale based on quarter outcomes
10. Check win/loss conditions
11. Generate quarterly report
```

---

## 5. Balance Guidelines

These are starting values. You WILL need to tune them through playtesting.

### Starting conditions (Normal difficulty)
- Cash: $150,000
- Employees: 1 (you, the CEO)
- Office: Garage (capacity: 4)
- Runway: ~6 months at minimum burn

### Salary ranges

| Seniority | Min/Quarter | Max/Quarter |
|-----------|------------|------------|
| Junior    | $15,000    | $22,000    |
| Mid       | $22,000    | $35,000    |
| Senior    | $35,000    | $55,000    |
| Lead      | $50,000    | $75,000    |
| Principal | $70,000    | $100,000   |

### User growth model (Consumer App example)
- Base organic growth: 2–5% per quarter
- Marketing multiplier: spend $X → Y% boost (diminishing returns)
- Product quality multiplier: UX score × feature count → word-of-mouth coefficient
- Churn: base 5% + (bugs × 0.5%) + (competitor launches × 2%)

### Tech debt accumulation
- Shipping features at <70 quality → +5 tech debt per feature
- Shipping features at <50 quality → +10 tech debt per feature
- Tech debt > 50 → all development takes 25% longer
- Tech debt > 75 → all development takes 50% longer, random "everything breaks" events

---

## 6. What Makes This Different from Startup Company

| Aspect | Startup Company (PC) | Venture (Mobile) |
|--------|---------------------|------------------|
| Focus | Website building only | 5 industry paths, 15+ company types |
| People | Generic employees | Named characters with personalities, arcs, drama |
| Events | Minimal | Rich narrative event system (50+ per path) |
| Session | Continuous sandbox | Quarterly turn structure, natural breaks |
| Depth | Wide but shallow systems | Path-specific unique mechanics (GPU budgets, tape-outs, review scores) |
| Money | Simplified | Realistic fundraising with dilution, term sheets, board dynamics |
| Emotion | Optimization puzzle | Human stories — firing a friend, choosing between people |
| Platform | PC only | Mobile-native, designed for portrait mode, touch-first |
| Expansion | Mods (community) | Official DLC paths with unique mechanics |
| Price | $14.99 PC | $4.99 base + $2.99 per DLC |

---

---

## 7. Development Mantras

1. **Playable over perfect.** A working game with placeholder UI beats a beautiful screen with no logic behind it.
2. **One system at a time.** Don't build the fundraising system until hiring works.
3. **Decisions over numbers.** If a screen shows stats but doesn't ask the player to DECIDE something, it's not gameplay.
4. **Every quarter should have tension.** If a quarter passes with nothing interesting happening, add more events.
5. **Steal from PGM3.** Its UI patterns, session structure, and "just one more season" hooks are your north star.
6. **Your life is content.** Every frustrating thing about working in tech is a potential game event.
7. **Ship in 3 months.** Scope to what one person can build in 13 weeks with AI assistance. Cut ruthlessly.

---

## Related Docs

- **[AI Integration Spec](ai-integration.md)** — Three-tier narrative system (Classic / Dynamic / Online)
- **[Content Schemas](content-schemas.md)** — JSON formats for events, bios, headlines, VC dialogue, postmortems, scenario packs; batch generation prompts
- **[Roadmap](roadmap.md)** — Phase-by-phase checklist with current progress
- **[Monetization](monetization.md)** — Pricing, DLC structure, platform fees

---

*Living document. Update as mechanics are locked and playtested.*
