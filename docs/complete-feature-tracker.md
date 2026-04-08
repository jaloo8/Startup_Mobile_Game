# VENTURE — Complete Feature Tracker

**Purpose:** This is the single source of truth for every feature, system, and polish item mentioned across all conversations, memory files, and documentation. Written at the user's explicit request so nothing gets forgotten.

**Last updated:** April 7, 2026 (v3 — line-by-line pass of full Dev Bible + all 239 Cursor messages + Claude Code transcript)

**Legend:**
- ✅ DONE — Implemented and working
- 🔶 PARTIAL — Started but not fully complete
- ❌ NOT STARTED — Mentioned/requested but no code written yet
- 🔮 FUTURE/DLC — Explicitly deferred to post-launch or DLC

---

## 1. Core Gameplay Loop

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 1 | GameState autoload singleton | ✅ DONE | Central state management |
| 2 | Resource-based data models (Company, Employee, Product, Financials, Market, Event) | ✅ DONE | 6 model classes |
| 3 | Quarterly advance simulation (12-step engine) | ✅ DONE | `simulation_engine.gd` |
| 4 | Employee hire/fire/view/assign | ✅ DONE | Full CRUD on team |
| 5 | Work allocation (Features/Bugs/Tech Debt/Infra/R&D) | ✅ DONE | 5 categories |
| 6 | Stage-aware responsibilities (early cross-functional → growth specialization) | ✅ DONE | |
| 7 | Role-mesh bonuses (balanced lane coverage synergy) | ✅ DONE | |
| 8 | Product metrics (features, bugs, tech debt, stability, UX, churn) | ✅ DONE | |
| 9 | Basic finances (burn, revenue, cash, runway) | ✅ DONE | |
| 10 | Game over conditions (bankruptcy, dead product) | ✅ DONE | |
| 11 | Win conditions (IPO, Acquisition, Sustainable, Unicorn) | ✅ DONE | Victory screen |
| 12 | All 4 revenue models (SaaS, Consumer, Marketplace, Dev Tools) | ✅ DONE | Type-specific calc |
| 13 | Save/load with threaded auto-save | ✅ DONE | JSON serialization |
| 14 | Scene management (preload, deferred transitions) | ✅ DONE | `scene_loader.gd` |
| 15 | Quarterly narrative report (6+ bullet summary) | ✅ DONE | Revenue, cash, team, product, users, economy context |

## 1b. Company-Type Unique Mechanics (From Dev Bible Section 3.1)

Each company type was designed with a unique core mechanic. These are individually tracked here:

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 15a | SaaS unique: Sales Pipeline (SDR, AE, deal stages: Lead → Demo → Trial → Negotiation → Closed) | ❌ NOT STARTED | Dev Bible: "Enterprise deals take 1–3 quarters to close. You need SDRs and Account Executives." — dedicated sales pipeline system |
| 15b | Consumer unique: Virality Engine / K-factor | ❌ NOT STARTED | Dev Bible: "Growth depends on K-factor (how many new users each existing user brings in). Features that increase sharing/invites are more valuable." |
| 15c | Consumer tension: Dark patterns vs. brand | ❌ NOT STARTED | Dev Bible: "Dark patterns boost engagement but hurt brand/press coverage. Do you add notifications that feel spammy but drive DAU?" |
| 15d | Marketplace unique: Two-Sided Growth / chicken-and-egg | ❌ NOT STARTED | Dev Bible: "You need BOTH supply and demand. Must decide which side to subsidize. Liquidity is the key health metric." |
| 15e | Marketplace tension: Supplier taking transactions off-platform | ❌ NOT STARTED | Dev Bible: "A supplier is cheating the system. Crack down and lose them, or tolerate it?" |
| 15f | Dev Tools unique: Developer Ecosystem / DX / docs quality | ❌ NOT STARTED | Dev Bible: "Growth comes from documentation quality, developer experience (DX), and community/open-source strategy." |
| 15g | Dev Tools tension: Open source vs. proprietary | ❌ NOT STARTED | Dev Bible: "Open source your core to drive adoption (but competitors can fork it) or keep it proprietary?" |

## 2. Company Setup & Configuration

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 16 | 4 company types (SaaS, Consumer, Marketplace, Dev Tools) | ✅ DONE | Unique growth curves, features, events |
| 17 | Company type illustrations (dark navy flat style) | ✅ DONE | 4 images |
| 18 | Consumer App marked "★ Recommended for new players" | ✅ DONE | |
| 19 | Plain-English difficulty descriptions | ✅ DONE | Live-updating |
| 20 | 3 difficulty modes (Sandbox/Normal/Hardcore) | ✅ DONE | Tunable via `DIFFICULTY_MULTS` |
| 21 | 6 preset starting scenarios (Garage → Scale Chief) | ✅ DONE | Different cash/team entry points |
| 22 | JSON-driven niche selection per company type | ✅ DONE | `niches.json` with growth/churn/revenue modifiers |
| 23 | Niche-aware event/headline weighting | ✅ DONE | |
| 24 | Niche-biased competitor seeding | ✅ DONE | |
| 25 | Bespoke niche event packs (niche-specific unique events) | 🔶 PARTIAL | Framework done, unique per-niche events still pending |
| 26 | 4 founder archetypes (Engineer/Finance/Recruiter/Hustler) | ✅ DONE | Stats affect gameplay |
| 27 | Custom founder (distribute point pool) | ✅ DONE | 20 points across 4 stats |
| 28 | God Mode founder (unlockable after first win) | ✅ DONE | All stats maxed |
| 29 | CEO stat growth through choices | ✅ DONE | Finance option nudges finance skill up, etc. |

## 3. Employee System

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 30 | Employee generation with randomized stats | ✅ DONE | |
| 31 | Hiring pipeline (post job → candidates → interview → offer) | ✅ DONE | $5K job posting cost |
| 32 | Employee sorting/filtering (name, skill, morale, salary, assignment) | ✅ DONE | |
| 33 | Salary negotiation (−15% button, reject risk) | ✅ DONE | Culture-fit dependent |
| 34 | Specialty match system (0.9×–1.4× productivity multipliers) | ✅ DONE | "⚡ Great fit / ✓ Good fit" badges |
| 35 | Deep interview system (interviewer tier selection) | ✅ DONE | Founder/VP/Director/Manager/Engineer tiers |
| 36 | Interview skill affects stat reveal accuracy | ✅ DONE | Error margins based on interviewer quality |
| 37 | Interviewer lock (time/resource cost, opportunity cost) | ✅ DONE | |
| 38 | Culture fit detection (requires strong people-skill interviewer) | ✅ DONE | Shows as `???` otherwise |
| 39 | Interview feedback flavor text with confidence level | ✅ DONE | |
| 40 | Employee hire badge (pop-in "Welcome to the Team" modal) | ✅ DONE | Spring scale-in animation |
| 41 | Employee bios | ✅ DONE | 72 bio strings across 6 personality types in `bios.json` |
| 42 | Employee detail view with history + trajectory chart | ✅ DONE | Dedicated profile screen |
| 43 | Employee aging & retirement | ✅ DONE | Probabilistic curve (60-80 range) |
| 44 | Employee personalities (6 traits) | 🔶 PARTIAL | Steady/Ambitious/Perfectionist/Team Player/Mentor/Adaptable implemented; deeper personality-authored event branches still pending |
| 45 | Team composition collaboration/morale effects | ✅ DONE | |
| 46 | 8 Pixar-style employee avatars | ✅ DONE | Deterministic hash assignment |
| 47 | Employee bios target 200 (currently 160) | 🔶 PARTIAL | 72 in `bios.json`, need more |
| 48 | Expand bios to 200+ total | ❌ NOT STARTED | Content target |
| 49 | Executive poaching from competitors | ❌ NOT STARTED | Browse competitor orgs, guaranteed quality hire, lawsuit risk |
| 50 | Acqui-hire / Big company poaching you | ❌ NOT STARTED | Goople/Mapple/Amacon parody offers |
| 50a | Employee onboarding period (reduced output after hire) | ❌ NOT STARTED | Dev Bible 3.2: "Onboarding takes 1–2 weeks (reduced output initially)" — new hires don't produce at full capacity immediately |
| 50b | Employee promotion system (Junior → Mid → Senior → Lead → Principal) | ❌ NOT STARTED | Dev Bible 3.2: Seniority levels exist as attributes, but no in-game promotion mechanic where employees advance through tiers over time based on performance/tenure |
| 50c | Employee Speed attribute (1–100) separate from Skill | ❌ NOT STARTED | Dev Bible 3.2: "Speed (1–100) — How fast they produce output" — currently Skill is the main stat; Speed as a distinct attribute affecting output rate not implemented |
| 50d | Employee Growth Potential attribute (Low/Med/High) | ❌ NOT STARTED | Dev Bible 3.2: "Growth potential (Low/Med/High) — How much Skill can increase over time" — cheap juniors with High growth potential vs. expensive seniors with Low growth = a key hiring decision |
| 50e | 9 employee specialties (Frontend, Backend, Mobile, Design, Data/ML, DevOps, Sales, Marketing, Operations) | 🔶 PARTIAL | Dev Bible 3.2 lists 9 distinct specialties; current implementation has fewer. Sales, Marketing, Operations as distinct specialties not fully implemented |
| 50f | Feature assignment slots visual (clearer worker-to-feature UX) | ❌ NOT STARTED | Cursor S2: User said "For assigning workers, maybe have slots so it is clearer; more workers = faster completion" — visual slots showing who's working on what |

## 4. Product System

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 51 | Company-type-specific feature trees (10 features per type) | ✅ DONE | Prerequisites, costs, gameplay effects |
| 52 | Feature build speed tuned (1–4 quarters with small team) | ✅ DONE | 3× increase |
| 53 | Feature ETA display | ✅ DONE | Estimated quarters, engineer count, specialty summary |
| 54 | Feature shipped celebration (color-coded banner) | ✅ DONE | Quality-tinted |
| 55 | Feature-ship confetti burst | ✅ DONE | GPUParticles2D, quality-tinted colors |
| 56 | Milestone roadmap on Product screen | ✅ DONE | User count, features-shipped, revenue targets |
| 57 | Idle-game progression curve (exponential feature cost scaling) | ✅ DONE | 0.7× early → 4× late |
| 58 | Feature synergies system | ✅ DONE | `feature_synergies.json` |
| 58x | R&D unlocks new feature categories (not just stat boost) | ❌ NOT STARTED | Dev Bible 3.3: "R&D — Research new technologies (unlocks future feature categories)" — R&D allocation should progressively unlock new features to build, not just be a passive stat |
| 58y | Individual feature quality scores (1–100 per shipped feature) | 🔶 PARTIAL | Dev Bible 3.3: "Features (list of completed features, each with quality score 1–100)" — features have build quality but per-feature quality score as a persistent tracked metric not fully visible to player |

## 5. Interactive Phone Mockup (Product Visual)

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 59 | Phone device frame (bezel, status bar, notch, home indicator) | ✅ DONE | Procedural in `product_visual.gd` |
| 60 | Data-driven product visual (UI evolves as features ship) | ✅ DONE | 4 company-type layouts |
| 61 | Consumer streaming app mockup | ✅ DONE | Feed, recommendations, stories |
| 62 | Ken Burns slow zoom on revealed thumbnails | ✅ DONE | 1.0→1.06, 13s loop |
| 63 | Skeleton shimmer on in-progress features | ✅ DONE | White strip sweep loop |
| 64 | Phase-offset scale pulses on story bubbles | ✅ DONE | 1.0→1.10, 2.6s cycle |
| 65 | Consumer streaming art pack (12 images) | ✅ DONE | Brand badge, avatars, thumbnails, stories |
| 66 | SaaS product mockup | ✅ DONE | Unique layout |
| 67 | Marketplace product mockup | ✅ DONE | Unique layout |
| 68 | Dev Tools product mockup | ✅ DONE | Unique layout |
| 69 | "Product Demo" tap mechanic (tap features → gain rep) | ✅ DONE | Bounce + tooltip + rep bonus |
| 70 | Demo tap haptic feedback + screen flash | ✅ DONE | |
| 71 | Floating "+N Rep" spring animation on demo tap | ✅ DONE | Scale 0.5→1.0, drift up, fade |
| 72 | Prototype concept switcher (JSON-driven) | ✅ DONE | `product_preview_prototypes.json` |
| 73 | Concept-specific art variants per prototype | 🔶 PARTIAL | Framework done, unique visuals per concept pending |
| 74 | Per-concept layout overrides | ❌ NOT STARTED | Different visual arrangements per concept |

## 5b. Gameplay Mechanics (From Dev Bible, Playtester Feedback & Conversations)

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 58a | Build multiple features simultaneously | ✅ DONE | User: "can't I work on multiple things at once if I wanted to?" — team allocation allows parallel work |
| 58b | All team roles feel impactful (not just Features) | ✅ DONE | User: "adding people to different responsibilities feels a little useless... R&D, tech debt, etc feel useless" — role-mesh system now gives all lanes real impact |
| 58c | Gradually introduce event popups later in game | ✅ DONE | User: "gradually have some popups more later in the game?" — valuation-based event pacing limits early events |
| 58d | Game-over angel investor rescue option | 🔶 PARTIAL | User: "after clicking on game over, you should have an option for an angel investor" — "An Angel Appears" event exists at Q3+, but no game-over rescue mechanic |
| 58e | Employee contractor / intern / part-time types | ❌ NOT STARTED | User: "hiring full-time/contractor, etc" — mentioned as future scope in early game economy revamp |
| 58f | Designers with clear roles (visual vs. UX) | 🔶 PARTIAL | User: "If they are a designer, what kind? Does it make the product look better or is more friendly?" — specialties exist but designer sub-roles not split |
| 58g | Office upgrade path clarity | 🔶 PARTIAL | User: "office full? How do we upgrade?" — office tiers exist but upgrade UX could be clearer |
| 58h | Lite/casual mode for non-tech players | ❌ NOT STARTED | User: "also maybe having a lite option for non tech people who just like idle games" — simplified gameplay mode |
| 58i | Shipping decisions: MVP vs. Polished vs. Ship with Known Bugs | ❌ NOT STARTED | Dev Bible: Player chooses product quality before releasing a feature — MVP (fast, lower quality), Polished (slower, higher), or Ship with Bugs (risky). Affects reviews, users, reputation |
| 58j | Crunch / overtime button (employee-level) | ❌ NOT STARTED | Dev Bible: "Burnout/stress mechanic with crunch button tradeoff" — toggle that boosts short-term output but damages morale and risks employee burnout |
| 58k | Partnerships / BD deals system | ❌ NOT STARTED | Dev Bible core loop: "5. STRATEGY — Marketing, partnerships, etc." Marketing spend is done, but partnership deals (co-marketing, API integrations, revenue shares) are not implemented |
| 58l | Board Review quarterly scorecard | 🔶 PARTIAL | Dev Bible core loop: "7. BOARD REVIEW — Quarterly scorecard." Board patience metric exists, quarterly report exists, but a dedicated investor-facing scorecard screen with target tracking is not implemented |
| 58m | First-run guided objectives / early achievements | 🔶 PARTIAL | Playtester: "easily obtainable objectives for a first time run through" — tutorial overlay exists, but specific early-game milestone objectives (e.g. "Hire your first employee", "Ship your first feature") as guided achievements not tracked |
| 58n | Sandbox mode clearer in-game explanation | 🔶 PARTIAL | Playtester: "Unsure what sandbox mode is" — difficulty descriptions exist but sandbox could use a more prominent "this is the learning mode" callout |
| 58o | User segments (early adopters, mainstream, enterprise) with different needs | ❌ NOT STARTED | Dev Bible 3.5: "Different segments (early adopters, mainstream, enterprise) have different needs" — user base should have segmented cohorts that respond differently to features, pricing, and marketing |
| 58p | Competitive moat mechanic (defensibility builds over time) | ❌ NOT STARTED | Dev Bible 3.5: "Competitive moat builds over time through features, brand, and network effects" — accumulated defensibility metric that protects against competitor pressure |
| 58q | Gameplay length pacing (game completes too quickly) | 🔶 PARTIAL | Cursor S2: User completed game in ~4 in-game years and said it's too short. "needs to be longer" — profitable/success conditions may trigger too early, especially in later scenarios. Balance pass needed. |
| 58r | Real-life current/past events as content (stock crashes, wars, pandemics for humor/relatability) | 🔶 PARTIAL | Cursor S2: User said "stock crashes, wars, etc. as event content; makes it feel funnier, relatable" — world events system exists with recession/tariffs but more real-world-inspired drama wanted |
| 58s | Replayability / "keep people coming back" systems | 🔶 PARTIAL | Cursor S2: User asked "how to keep people coming back; game is not as endless as Candy Crush." Achievements + seeds partially address this; daily objectives / weekly challenges discussed but deferred to low-priority backlog |

## 6. Finance & Fundraising

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 75 | Fundraising (VC meetings, term sheets, dilution, board seats) | ✅ DONE | Named VC firms with preferences |
| 76 | Quarter-over-quarter delta labels (Cash, Revenue, Burn) | ✅ DONE | Green/red +/- display |
| 77 | Finance decision guidance ("Next best move" NL text) | ✅ DONE | |
| 78 | Driver-level drill-down summary (quarter cash movement) | ✅ DONE | Revenue + cost bucket breakdown |
| 79 | Valuation-based event pacing | ✅ DONE | Max events scale with company size |
| 80 | Early game economy revamp | ✅ DONE | Garage $60K, organic growth 20/Q, revenue rates buffed |
| 81 | Marketing spend → user growth pathway | ✅ DONE | `MARKETING_USER_MULT` wired |
| 82 | "An Angel Appears" tutorial event for unfunded companies | ✅ DONE | Q3+ trigger, $50K + 5 rep |
| 83 | Founder burnout system (energy 0-100, game over at zero) | ✅ DONE | Dashboard display |
| 84 | Board takeover (patience tracked for funded companies) | ✅ DONE | Finance screen display |
| 84a | CAC / LTV / Gross Margin as explicitly displayed finance metrics | ❌ NOT STARTED | Dev Bible 3.4: "Key financial metrics displayed: Monthly Burn Rate, Runway, MRR/ARR, CAC (Customer Acquisition Cost), LTV (Lifetime Value per customer), Gross Margin" — burn/runway/MRR displayed, but CAC, LTV, and Gross Margin not yet shown |
| 84b | Named fundraising rounds (Pre-seed → Seed → Series A → Series B → Growth) | 🔶 PARTIAL | Dev Bible 3.4: Each round has "different dynamics." Current system has fundraising stages but named progression (Pre-seed through Growth) with distinct mechanics per round not fully differentiated |
| 84c | Tools & software licenses as visible cost category | ❌ NOT STARTED | Dev Bible 3.4 lists "Tools & software licenses" as a cost category alongside salaries, cloud, office, marketing, legal — not currently broken out in the finance display |
| 84d | Legal/accounting costs scaling with company size and fundraising | ❌ NOT STARTED | Dev Bible 3.4: "Legal/accounting (increases with company size and fundraising)" — costs should visibly grow as you raise rounds and scale headcount |

## 7. Events & World Events

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 85 | Event system (JSON-driven, template variables, variations) | ✅ DONE | |
| 86 | 50+ events across 5 categories | ✅ DONE | People, product, money, market, culture |
| 87 | Event resolution UI (modal, choices, effects, outcome text) | ✅ DONE | |
| 88 | World event engine (multi-quarter macro cycles) | ✅ DONE | `WorldEventEngine` |
| 89 | 26 world events total | ✅ DONE | Tariff shock, privacy regulation, recession, etc. |
| 90 | Economy state transitions (Bull/Neutral/Bear) | ✅ DONE | Affects growth, churn, fundraising |
| 91 | Recession/instability duration caps | ✅ DONE | 6→4Q max recession, 5→4Q instability |
| 92 | News headline ticker (67+ templates) | ✅ DONE | Context-filtered per quarter |
| 93 | `requires_world_event` filter on headlines | ✅ DONE | 6 headlines tagged |
| 93a | Stock price/market information in news ticker (like CNBC/ABC) | ❌ NOT STARTED | User: "rotating through a few headlines in addition to maybe stock information like on ABC/CNBC/etc." — stock ticker alongside headlines |
| 93b | News piece reader reactions/comments boosting reputation | ❌ NOT STARTED | User: "maybe a few replies and it can help with reputation for you and the business" — social media-style comment reactions on press coverage |
| 94 | Event balance rebalance (12 events where one choice dominated) | ✅ DONE | |
| 95 | 3 press/media events (feature profile, hit piece, acquisition rumor) | ✅ DONE | In `events.json` |
| 96 | Dedicated press outlet personas (TekCrunch, Bloomburg, The Informant) | 🔶 PARTIAL | Events exist, full outlet system pending |
| 97 | Investigative-piece mechanic | ❌ NOT STARTED | |
| 98 | Reader-reaction headline variants | ❌ NOT STARTED | |
| 99 | Expand headlines to 150+ total | ❌ NOT STARTED | Content target from roadmap |
| 100 | Expand events to 50+ (target from Classic Mode) | ✅ DONE | Already at 50+ |
| 100a | Event description variations (3–5 alternate phrasings per event) | ❌ NOT STARTED | Dev Bible 8: "50+ unique events with 3-5 description variations each" — each event should have multiple written variations so the same event reads differently on repeat playthroughs. Currently events have one description each. |

## 8. Competitors & Market

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 101 | Competitor AI (grow users, improve products, raise funding) | ✅ DONE | |
| 102 | 86 competitor entries | ✅ DONE | In `competitors.json` |
| 103 | Market leaderboard (tappable competitor rows with detail popup) | ✅ DONE | |
| 104 | Pop-culture parody reference pack | ✅ DONE | Events, headlines, competitors |
| 105 | Reference tone & safety guardrails doc | ✅ DONE | `docs/reference-tone-guardrails.md` |
| 106 | Expand competitor roster with more parodies | ❌ NOT STARTED | Multiple product lines, unique behaviors |
| 107 | Competitor product depth (multiple products per competitor) | ❌ NOT STARTED | |
| 108 | Community mod packs / "real names" JSON | ❌ NOT STARTED | Import flow for user-created packs |
| 108a | Redo competitor products to match player company types better | 🔶 PARTIAL | User: "we also need to redo company products so we have competitors that match up with ours better" — niche-biased seeding done, but product-level matching pending |
| 108b | Competitor acquisitions, pivots, IPOs as market events | ❌ NOT STARTED | User: "flesh out each with multiple product lines, unique behaviors, and market moves" |
| 108c | S&P 500 scale competitor count (aspirational) | ❌ NOT STARTED | User: "should we maybe have enough competitors to make it feel like an accomplishment? ...we'd maybe need like the S&P500?" — currently 86, aspirational target is hundreds |
| 108d | In-game version control references use gitlab not github | ❌ NOT STARTED | User: "Instead of, in game, mentioning the use of github, maybe can you use an actual enterprise version control like gitlab? Maybe you use like gitlab.&lt;company_Name&gt;.com" |

## 9. Hosting & Infrastructure

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 109 | Hosting economics (demand/capacity lanes: web/cache/data) | ✅ DONE | |
| 110 | Plan-based costs (Managed Cloud/Hybrid/In-house) | ✅ DONE | |
| 111 | Overage costs and reliability incidents | ✅ DONE | |
| 112 | Player-facing capacity actions (lane upgrades + optimization) | ✅ DONE | Logistics screen |
| 113 | Workload-aware pressure profiling (AI/ML, streaming, marketplace, API) | ✅ DONE | |

## 10. VC Chips System

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 114 | VC Chips currency system | ✅ DONE | |
| 115 | "Skip Event" spend (4 chips) | ✅ DONE | Event popup button |
| 116 | "Reveal Extra Candidate" spend (3 chips) | ✅ DONE | Hiring screen button |
| 117 | "Boost +10%" product spend (5 chips) | ✅ DONE | Product screen button |
| 118 | "2× Passive Income" spend (6 chips) | ✅ DONE | Dashboard button |
| 119 | `chip_spend` synthesized SFX | ✅ DONE | |
| 120 | Tutorial chip step (step 5) | ✅ DONE | |
| 121 | Glossary "VC Chips" entry | ✅ DONE | |

## 11. Achievements & Scoring

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 122 | Achievement system (40 achievements) | ✅ DONE | `achievements.json`, `AchievementManager` autoload |
| 123 | Achievement ceremony (toast + SFX + haptic + confetti) | ✅ DONE | |
| 124 | Achievement browser screen | ✅ DONE | |
| 125 | Cross-run tracking | ✅ DONE | Persistent unlocks |
| 126 | VC Chips rewards for achievements | ✅ DONE | |
| 127 | Founder Score (6-axis: finances, growth, product, team, speed, reputation) | ✅ DONE | `ScoringEngine`, letter grades S/A/B/C/D/F |
| 128 | Postmortem screen (timeline of key decisions, shareable) | ❌ NOT STARTED | |
| 129 | Seed system (share seeds for specific market conditions) | ❌ NOT STARTED | |

## 12. Tutorial System

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 130 | TutorialManager autoload (5-step overlay) | ✅ DONE | Step persistence, auto-advance |
| 131 | Skip tutorial option | ✅ DONE | |
| 132 | Replay tutorial from Settings | ✅ DONE | |
| 133 | Tutorial chip step | ✅ DONE | Step 5 explaining VC Chips |

## 13. Game Juice & Polish

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 134 | Toast notification system (ToastManager autoload) | ✅ DONE | |
| 135 | 22 synthesized sound effects | ✅ DONE | hire, fire, feature_ship, button_tap, event_popup, retire, achievement, game_over, victory, fundraise, toast, quarter_whoosh, quarter_ding, chip_spend, + more |
| 136 | Button press feedback (squash/stretch animation) | ✅ DONE | Every button |
| 137 | Haptic vibration (light/medium/heavy) | ✅ DONE | Wired into taps, quarter advance, fundraise, feature ship, achievements |
| 138 | Screen shake (trauma-based) | ✅ DONE | Big cash changes, fundraise, feature ship |
| 139 | Floating number pop-ups ("+$50K", "+1.2K users") | ✅ DONE | Drift up and fade |
| 140 | Enhanced offline income summary (staggered reveal) | ✅ DONE | |
| 141 | Quarter advance transition animation + SFX | ✅ DONE | Full-screen label + sweep + eased fade |
| 142 | Turn-change clarity polish (momentum strip, event guidance, hints) | ✅ DONE | |
| 143 | Safe entrance animations (stagger_list, pop_in, fade_in on children) | ✅ DONE | Replaced broken fade_in(self) on 8 screens |
| 144 | Main menu entrance animation (deferred frame, fade_in buttons) | ✅ DONE | Fixed VBoxContainer position-fighting |
| 145 | SceneLoader transition safety timeout | ✅ DONE | Prevents permanent navigation lock |
| 145a | Creative/clever loading screen | ❌ NOT STARTED | User: "maybe if we need to load the game in any way, we do it in a clever/smart/creative way" — startup tips, fun facts, or mini-animations during any loading moments |
| 145b | Quarter advance income/loss summary shown prominently | 🔶 PARTIAL | Playtester: "When advancing quarter, saying how much money we made or lost would be good" — quarterly report exists, deltas on dashboard exist, but an inline advance-quarter money summary may not be prominent enough |

## 14. Charts & Data Visualization

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 146 | TrendChart (4-series named API with colored legend) | ✅ DONE | Endpoint markers, normalized overlay |
| 147 | Finance charts (Cash, Revenue, Burn, Users, Valuation, Team, Morale) | ✅ DONE | |
| 148 | Employee trajectory chart (skill/morale/stress over quarters) | ✅ DONE | In employee detail view |
| 149 | Deeper drill-down analytics | 🔶 PARTIAL | Basic charts done, deeper per-metric drilldown pending |

## 15. Visual Assets & Art

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 150 | 4 company type illustrations | ✅ DONE | Dark navy flat style |
| 151 | 4 office tier banners (Garage → Co-working → Small Office → HQ) | ✅ DONE | |
| 152 | 8 employee avatars (Pixar-inspired, diverse) | ✅ DONE | Deterministic hash assignment |
| 153 | 5 assignment category icons | ✅ DONE | Features/Bugs/Tech Debt/Infra/R&D |
| 154 | App icon | ✅ DONE | |
| 155 | 12 consumer streaming art images | ✅ DONE | Brand badge, profiles, thumbnails, stories |
| 156 | Water Hazard Studios SVG logo | ✅ DONE | Pixel-art golf flag, water waves |
| 157 | Art asset brief for image generation | ✅ DONE | `docs/art-asset-brief.md` with 8 prompts |
| 158 | App Store icon (1024×1024) | ❌ NOT STARTED | Prompt ready in art brief |
| 159 | Studio logo full (2048×512 horizontal) | ❌ NOT STARTED | Prompt ready in art brief |
| 160 | Studio logo square (512×512 avatar) | ❌ NOT STARTED | Prompt ready in art brief |
| 161 | Game splash screen (1440×2560) | ❌ NOT STARTED | Prompt ready in art brief |
| 162 | Google Play feature graphic (1024×500) | ❌ NOT STARTED | Prompt ready in art brief |
| 163 | 6 App Store screenshots (1290×2796 each) | ❌ NOT STARTED | Prompt ready in art brief |
| 164 | Social media banner (1500×500) | ❌ NOT STARTED | Prompt ready in art brief |
| 165 | Promotional key art (1920×1080) | ❌ NOT STARTED | Prompt ready in art brief |

## 16. Office Scene & Character Animation

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 166 | Procedural pixel characters with 4-frame animation | ✅ DONE | Office worker visuals |
| 167 | Morale expressions on characters | ✅ DONE | |
| 168 | Office furniture (desks, chairs, monitors, plants, whiteboards, etc.) | ✅ DONE | |
| 169 | Monitor glow pulses | ✅ DONE | |
| 170 | Disney-style positional bob | ✅ DONE | |
| 171 | Kenney/custom sprite art replacement | 🔶 PARTIAL | Procedural sprites working, Kenney/custom art swap pending |
| 172 | AnimatedSprite2D idle/walk/sit cycles | ❌ NOT STARTED | Requires custom sprites |
| 173 | Assignment-specific animations (typing for Features, worried for Bugs, etc.) | ❌ NOT STARTED | Requires custom sprites |
| 173a | Employees typing animation tied to feature progress | ❌ NOT STARTED | User: "maybe if we have them type they keep progressing the features?" — visual link between office workers typing and feature build progress bar |
| 174 | Custom sprite art commission/generation | ❌ NOT STARTED | Match Pixar-inspired avatar style |
| 174a | Sprites should be Disney/Pixar-inspired with more detail | 🔶 PARTIAL | User: "A little more like simpler disney inspired ones" and "sprites are on the right path! But can you add in a little more details? They are just a bit too generic" — procedural sprites exist, need more personality |
| 175 | AnimationPlayer multi-step office sequences | ❌ NOT STARTED | Employees react to events, celebrate, droop |
| 175a | Office scene should look "good and cute looking" | 🔶 PARTIAL | User: "really want the scene of furniture, people, office, etc to look good and cute looking" — procedural furniture/characters in place, visual polish pending |
| 176 | Animated product mockup for trailer (pre-rendered video) | 🔮 FUTURE | "Showcase mode" for App Store |

## 17. UI & Theme

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 177 | Color-coded progress bars (green/gold/red) | ✅ DONE | `_tint_bar()` |
| 178 | Morale-colored 3px left borders on employee cards | ✅ DONE | |
| 179 | Stress warning badges (⚠ High stress / ⚠ Burnout risk) | ✅ DONE | |
| 180 | Color-coded bugs/users/churn labels | ✅ DONE | |
| 181 | Nav tabs at top of Dashboard | ✅ DONE | People/Product/Finances/Market |
| 182 | Godot Theme resource (unified typography pass) | 🔶 PARTIAL | ThemeManager constants used, but full Godot Theme resource not created |
| 183 | Full typography pass across all screens | ❌ NOT STARTED | |
| 183a | More color in UI (beyond dark navy + white) | 🔶 PARTIAL | Playtester said "will there be any other colors aside from just black and white?" — accent colors exist but could be richer |
| 183b | Info icons / tooltips on ALL game metrics | ❌ NOT STARTED | User: "unsure what runway is, maybe have more information icons to help people who aren't tech savvy?" and "what is DAU/MAU? Can you add in an info button?" — applies to runway, burn rate, MRR, ARR, CAC, LTV, DAU/MAU, etc. |
| 183c | Simple view vs. detailed view toggle | ❌ NOT STARTED | User: "maybe we have like an indepth look at everything, and like simple view like in pocket GM?" — layman-friendly mode for casual players |
| 183d | Finance metrics written layman-friendly | 🔶 PARTIAL | User: "keeping a lot of the finance metrics in between laymens simple terms and CFO level" — driver drill-down done, but many raw metrics still jargon-heavy |
| 183e | Scrolling / overflow UX audit | 🔶 PARTIAL | User reported: "Many times I see bugs with the menu as I try to view the top and bottom" and "product page and when features are opened sometimes I cant see the top of the screen" — some fixes done, full audit still pending |

## 18. Save System & Data Safety

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 184 | Atomic writes (.tmp → rename) | ✅ DONE | |
| 185 | Checksum validation on load | ✅ DONE | |
| 186 | .bak backup recovery | ✅ DONE | |
| 187 | Schema version enforcement | ✅ DONE | |
| 188 | Storage safety limits (size caps, clamp/sanitize on deserialize) | ✅ DONE | |
| 189 | Analytics settings crash-safe with backup | ✅ DONE | |

## 19. Settings & Privacy

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 190 | Analytics toggle (consent-gated) | ✅ DONE | |
| 191 | Age gate panel (COPPA compliance) | ✅ DONE | |
| 192 | Privacy policy viewer | ✅ DONE | |
| 193 | Terms of Service viewer | ✅ DONE | |
| 194 | SFX toggle | ✅ DONE | |
| 195 | Haptic/vibration toggle | ✅ DONE | |
| 196 | Premium status display | ✅ DONE | |
| 197 | Restore purchases button | ✅ DONE | |
| 198 | Replay tutorial button | ✅ DONE | |
| 199 | Version label with build mode | ✅ DONE | |

## 20. Monetization & Premium

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 200 | Free-tier gate (locks after Quarter 8 / Year 2) | ✅ DONE | |
| 201 | Paywall UI | ✅ DONE | |
| 202 | Premium flags + save-slot entitlement gating (2 free → 5 premium) | ✅ DONE | |
| 203 | `MONETIZATION_TEMP_DISABLED` stability guard | ✅ DONE | Currently `true` |
| 204 | Set `MONETIZATION_TEMP_DISABLED = false` and test all paths | ❌ NOT STARTED | Blocked on store accounts |
| 205 | iOS IAP plugin (InAppStore) installation + wiring | ❌ NOT STARTED | Blocked on Apple Developer enrollment |
| 206 | Android IAP plugin (GodotGooglePlayBilling) installation + wiring | ❌ NOT STARTED | Blocked on Google Play enrollment |
| 207 | Create IAP product `venture.full_game_unlock` ($2.99) in both stores | ❌ NOT STARTED | Blocked on store accounts |
| 208 | Sandbox purchase flow testing on real devices | ❌ NOT STARTED | Blocked on IAP plugins + devices |
| 208a | Free-to-play version with creative ads (separate from premium) | ❌ NOT STARTED | User: "have a free to play version which has these ads like we discussed where it is creative, or a paid option with no ads" — ad-supported free tier in addition to $2.99 premium |
| 208b | VC Chips as both cosmetic AND gameplay accelerator | ✅ DONE | User: "both please" when asked about cosmetic vs. gameplay currency |
| 208c | Rewarded ads to earn VC Chips (free version) | ❌ NOT STARTED | User wants ads that aren't invasive; rewarded video for chips is natural fit |
| 208d | Release strategy: free version first or paid first? | ❌ NOT STARTED | User: "Should we actually release the free version first before the ad free version?" — decision still open |
| 208e | Bundle: "Venture: Complete Collection" — $12.99 | ❌ NOT STARTED | Dev Bible 9: "Bundle — 'Venture: Complete Collection' — $12.99 (base + all 4 DLCs, ~25% savings)" — IAP bundle product when DLCs exist |
| 208f | Base game price: $4.99 (Dev Bible) vs $2.99 (current) — price decision | ❌ NOT STARTED | Dev Bible originally specced $4.99 base game; current implementation uses $2.99. Final pricing decision needed before launch. |

## 21. Legal & Business

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 209 | Privacy Policy (GDPR Art. 13, CCPA, COPPA) | ✅ DONE | Water Hazard Studios, email contact |
| 210 | Terms of Service (16 sections) | ✅ DONE | |
| 211 | Support contact file | ✅ DONE | `SUPPORT.txt` |
| 212 | Studio name: Water Hazard Studios | ✅ DONE | |
| 213 | Studio email: Water.Hazard.Studios@gmail.com | ✅ DONE | Updated in all legal docs |
| 214 | PO Box / registered agent address | ❌ NOT STARTED | Deferred; get when forming LLC |
| 215 | Apple Developer enrollment ($99) | ❌ NOT STARTED | User action required |
| 216 | Google Play Console enrollment ($25) | ❌ NOT STARTED | User action required |

## 22. Developer Tools

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 217 | Dev panel (god mode, time skip, injection, quick save/load) | ✅ DONE | Gated behind `AdManager.is_dev_mode()` |
| 218 | Backend smoke test (`tools/backend_smoke.py`) | ✅ DONE | Offline Python validator |
| 219 | Balance simulation runner (`tools/balance_sim.py`) | ✅ DONE | 108-run automated matrix |
| 220 | Balance sim report | ✅ DONE | `docs/balance-sim-report.md` |
| 221 | QA smoke checklist | ✅ DONE | `docs/qa-smoke-checklist.md` |
| 222 | Dev edge-case test matrix | ✅ DONE | `docs/dev-edge-case-test-matrix.md` |
| 223 | Coding conventions doc | ✅ DONE | `docs/coding-conventions.md` |
| 224 | Debug prints gated behind `OS.is_debug_build()` | ✅ DONE | 13 bare prints removed |
| 224a | Dev mode multiple test save states | 🔶 PARTIAL | User: "making a developer mode for me to test out the game and making multiple save game points to test this out" — dev panel has quick save/load, but dedicated multiple test save state snapshots not implemented |
| 224b | Smoke test covers all mobile-specific concerns | 🔶 PARTIAL | User: "is the smoke check list robust enough for all coding for mobile game development?" — QA Section 23 covers mobile, but full mobile-specific validation pending device testing |
| 224c | Automated regression / bug-catching system | ❌ NOT STARTED | Cursor S2: User asked for "a way to automate catching as many bugs as possible rather than manual clicking" — automated test harness or scene walker |
| 224d | Art originality audit (no copied references) | ❌ NOT STARTED | Cursor S2: User said "review visuals to make sure they are not copying artwork of referenced games/media; everything should be as original as possible" — audit all art assets against inspiration sources |
| 224e | Royalty-free milestone visuals | ❌ NOT STARTED | Cursor S2: User said "if possible, use royalty-free visuals for milestone graphics" — ensure all milestone/achievement graphics are original or properly licensed |

## 22b. Documentation & Code Quality (User-Requested Standards)

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 216a | README kept up to date | 🔶 PARTIAL | User: "Make sure readme is up to date and whatnot" — exists but may be stale after recent changes |
| 216b | All documentation up to date | 🔶 PARTIAL | User: "Make sure documentation is also up to date as well" — some docs lag behind implementation |
| 216c | Placeholder code comments for future AI/visual work | ✅ DONE | User: "Anywhere you think would be good for visuals/animations too, in the code in general, please add in placeholders and good comments" — AI integration comments added in engine files |
| 216d | No over-engineered or AI-generated-sounding text | ✅ DONE | User: "make sure nothing sounds too AI generated or over engineered, should be natural sounding" — applies to all player-visible text |
| 216e | Code audit for streamlining and simplicity | ✅ DONE | User: "audit all our code and make sure it is streamlined, well documented, simpler is sometimes better" — dead code removal, debug print cleanup done |
| 216f | No copyright/trademark violations in code or content | ✅ DONE | User: "make sure to not use anything that can get me sued for copyright and trademarks" — parody names used throughout, `reference-tone-guardrails.md` created |
| 216g | Xcode simulator testing guide for user | ❌ NOT STARTED | User: "maybe you can help guide via xcode somehow as well? I heard you can test stuff on there as well somehow to mimic an iphone?" — step-by-step walkthrough needed |

## 23. Device Testing & Mobile Readiness

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 225 | Export templates installed | ❌ NOT STARTED | User action in Godot editor |
| 226 | iOS export preset created (Bundle ID) | ❌ NOT STARTED | User action |
| 227 | Android export preset created (package name, keystore) | ❌ NOT STARTED | User action |
| 228 | First debug build on real device | ❌ NOT STARTED | User action, highest priority |
| 229 | QA Section 23 mobile tests (portrait lock, touch targets, back button, etc.) | ❌ NOT STARTED | Blocked on device build |
| 230 | Safe area / notch testing | ❌ NOT STARTED | |
| 231 | Small screen testing (iPhone SE) | ❌ NOT STARTED | |
| 232 | Large screen testing (iPad) | ❌ NOT STARTED | |
| 233 | 60fps performance validation | ❌ NOT STARTED | |
| 234 | Touch target validation (≥44pt) | ❌ NOT STARTED | All coded at 46px |
| 235 | Android back button handling | ❌ NOT STARTED | |

## 24. Beta & Launch

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 236 | TestFlight upload (iOS) | ❌ NOT STARTED | Blocked on Apple Developer |
| 237 | Play Store internal track upload (Android) | ❌ NOT STARTED | Blocked on Google Play |
| 238 | 10-20 beta testers recruited | ❌ NOT STARTED | Mix of gamers, founders, varied devices |
| 239 | Soft launch in 1-2 markets (Canada/Australia) | ❌ NOT STARTED | |
| 240 | Store listing metadata (description, keywords, privacy URL) | ❌ NOT STARTED | |
| 241 | Public worldwide launch | ❌ NOT STARTED | Target: mid-May 2026 |

## 25. Content Targets (Quantity)

| # | Content Type | Current | Target | Status |
|---|-------------|---------|--------|--------|
| 242 | Events | ~50 | 50+ | ✅ MET |
| 243 | World Events | 26 | 26+ | ✅ MET |
| 244 | Employee Bios | 72 | 200 | 🔶 36% — needs ~128 more |
| 245 | Headlines | 67+ | 150 | 🔶 ~45% — needs ~83 more |
| 246 | Competitors | 86 | 100+ | 🔶 86% — needs ~14 more |
| 247 | Achievements | 40 | 40 | ✅ MET |
| 248 | Features (per type) | 10 | 10 | ✅ MET |
| 249x | VC pitch dialogue variations | 0 | 30+ | ❌ 0% — Dev Bible 8: "30+ VC pitch dialogue variations" for fundraising meetings |
| 249y | Quarterly report narrative templates | ~1 | 20+ | ❌ ~5% — Dev Bible 8: "20+ quarterly report narrative templates" for varied quarterly summaries |
| 249z | Game over postmortem narrative templates | 0 | 10+ | ❌ 0% — Dev Bible 8: "10+ game over 'postmortem' narrative templates" tailored to loss condition type |
| 249w | Competitor description templates | ~86 | 50+ | ✅ MET — Dev Bible AI Spec lists 50+ competitor descriptions as target; currently at 86 |
| 249v | Event description variations (3-5 per event) | ~1 each | 3-5 each | ❌ ~20% — Dev Bible 8: each of 50 events should have 3-5 written variations for replayability |

## 26. Content Packs (Special)

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 249 | Silicon Valley (show) character pack | ❌ NOT STARTED | Erlich, Gilfoyle, Dinesh, Jared, Gavin, Monica, Big Head parodies with unique events/dialogue |
| 249a | Peter Gregory / Russ Hanneman parodies as angel investors | ❌ NOT STARTED | User: "a funny reference to that guy from silicon valley that funds pied piper" — specific VC/angel characters |
| 249b | Pied Piper parody as a competitor company | 🔶 PARTIAL | Pop-culture competitors exist, but specific Pied Piper parody not confirmed |
| 250 | Scenario packs ("Dot-Com Boom", "AI Gold Rush", "Pandemic Pivot") | ❌ NOT STARTED | JSON configs |
| 250a | Free update scenario packs: Dot-Com Boom (1998), Social Era (2010), AI Gold Rush (2023), Pandemic Pivot (2020), Crypto Winter, TikTok Effect | ❌ NOT STARTED | User specified these as free updates, not DLC |
| 250b | "Real names" companion JSON for modders | ❌ NOT STARTED | User: "maybe we have a .json modders can use to actually input name?" and "Maybe we release an extra json with the real names as well ;)" — separate importable file with real company/VC names |
| 250c | Base game scenario: "Modern Day" (current market conditions) | 🔶 PARTIAL | Dev Bible 8: Included in base game (not DLC). Default new game is effectively "Modern Day" but not labeled as a named scenario |
| 250d | Base game scenario: "Bootstrapper's Dream" (no VC available, pure revenue-funded) | ❌ NOT STARTED | Dev Bible 8: Included in base game. A starting scenario where fundraising is disabled — forces pure revenue growth. |

## 27. Balance & Difficulty

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 251 | `DIFFICULTY_MULTS` tuning (cash, churn, competitor, fundraise) | ✅ DONE | In `game_state.gd` |
| 252 | 12-cell playtest matrix validation | 🔶 PARTIAL | Automated sim done, manual empirical pass pending |
| 253 | No unwinnable Normal cells | 🔶 PARTIAL | Some concern about profit streak constraint |
| 254 | Sandbox consistently easiest | ✅ DONE | 0 losses in sim |
| 255 | Hardcore intentionally brutal but beatable | ✅ DONE | |

## 28. Analytics Integration

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 256 | GameAnalytics SDK pattern (Engine.has_singleton) | ✅ DONE | |
| 257 | Consent-gated tracking | ✅ DONE | |
| 258 | Screen tracking on all screens | ✅ DONE | `Analytics.track_screen()` calls |
| 259 | New game event tracking | ✅ DONE | Company type, difficulty, scenario |

---

## 29. Post-Launch / DLC (Explicitly Deferred)

These are documented and wanted but intentionally deferred until after v1.0 ships:

| # | Feature | Target | Notes |
|---|---------|--------|-------|
| 260 | Classic Mode content expansion | Post-launch | Hit all content quantity targets |
| 261 | Dynamic Mode (on-device LLM, llama.cpp GDExtension) | v1.2 | Model download flow, fallback system |
| 262 | Online Mode (Cloud API, Claude Haiku) | v1.3 | Rate limiting |
| 263 | DLC #1: The Intelligence Age (AI/ML Path) | v1.2 | GPU/compute, model quality, AI revenue, 3 AI company types, 40 events |
| 264 | DLC #2: Press Start (Gaming Path) | v1.3 | Game projects, review scores, wishlists, 3 gaming types, 40 events |
| 265 | DLC #3: Silicon Dreams (Hardware Path) | v1.4 | Manufacturing, supply chain, product generations, 3 hardware types, 40 events |
| 266 | DLC #4: The Platform Play (OS & Platform Path) | v1.5 | Dev ecosystem, governance, network effects, 2 platform types, 30 events |
| 267 | DLC #5: Autonomous Mobility (AV Path) | v1.6 | Autonomy stack, compute/edge infra, regulatory loop, 2 mobility types, 35 events |
| 268 | Stock market post-IPO endgame | Post-launch | Live stock price, buybacks, offerings, analyst ratings, earnings calls |
| 269 | Corporate Ventures program (CVC arm) | Post-launch | Invest in AI-generated mini-startups at $100M+ valuation |
| 270 | Dynamic org structures (team pods, function leads) | Post-launch | At scale thresholds |
| 271 | Time progression alternatives (real-time/monthly mode) | Post-launch | Speed controls |
| 272 | Hybrid real-time ops monetization experiment | Post-launch | Evaluate via soft-launch data |
| 273 | Custom sprite art (commission or AI-generate) | Post-launch | Replace procedural sprites |
| 274 | AnimationPlayer office sequences | Post-launch | Requires custom sprites |
| 275 | Animated product mockup for trailer | Post-launch | Pre-rendered video for store |
| 275a | Cross-path DLC synergies / conglomerate endgame | v2.0+ | Dev Bible: "If a player completes multiple paths, they can create a conglomerate that spans Hardware + Software + AI" — multi-DLC meta-game |
| 275b | PathModule modular architecture for DLC plugin system | v1.1 | Dev Bible 9: "The core SimulationEngine calls a PathModule protocol. Each path implements this protocol." — core engine refactored so DLCs plug in without changing core code. Events loaded from JSON, UI adapts per path. |
| 275c | Salary ranges by seniority tier (Dev Bible balance targets) | Post-launch | Dev Bible 7: Junior $15-22K/Q, Mid $22-35K/Q, Senior $35-55K/Q, Lead $50-75K/Q, Principal $70-100K/Q — verify current salary generation matches these bands |

---

## 30. AI/Tech Integration (Research Complete)

From `docs/AI_TECH_OPPORTUNITIES.md`:

| # | Tool/Integration | Priority | Status |
|---|-----------------|----------|--------|
| 276 | PixelLab (pixel art from text) | HIGH | ❌ NOT STARTED — available today |
| 277 | Retro Diffusion (pixel-art AI models) | HIGH | ❌ NOT STARTED — available today |
| 278 | ComfyUI + Pixel-Art-XL LoRA | MEDIUM | ❌ NOT STARTED — needs 8GB+ GPU |
| 279 | Blender-to-Godot pipeline addon | LOW | ❌ NOT STARTED |
| 280 | LLM-generated narratives (Claude API) | HIGH | ❌ NOT STARTED — specced in `ai-integration.md`, for v1.2+ |

---

---

## 31. Game Inspiration References (User-Stated)

These are games the user explicitly mentioned as inspiration. Features from these should inform design decisions:

| Game | What to Take From It | User Quote |
|------|---------------------|------------|
| **Pocket GM 3 (PGM3)** | Simple vs. detailed view toggle, role impact feel, UI patterns, session structure | "simple UI similar to the game PG3", "We want all roles to feel like they move the needle... similar to PocketGM3" |
| **Startup Company (Steam)** | Hosting fees, animated employees in office, building upgrades, real-time operations feel | "how the game startup company on steam has their game play... hosting fees", "some animations of employees sitting in an office" |
| **Project Hospital (Steam)** | Gameplay feel, management depth | "I also like how Project Hospital feels as well" |
| **Tiny Tower** | Simple sprite animations, idle progression | "simple animations/sprites similar to tiny tower" |
| **Cities: Skylines** | Real-time control model (considered but kept quarterly) | "think we should transition to real time? Like city skylines?" |
| **Disney / Pixar** | Visual quality and charm target | "animations and visuals are as good as disney", "professional game developer and animator from pixar" |
| **Apple** | UX friendliness standard | "as user friendly as apple devices" |

---

## 32. User-Stated Design Principles

These are recurring quality standards and philosophies the user has expressed across all conversations:

1. **"Technical enough for engineers, accessible for non-tech people"** — The game must satisfy both audiences
2. **"Quality over quantity"** — User explicitly prioritizes polish over shipping fast
3. **"Nothing AI-generated-sounding"** — All player-visible text must read naturally
4. **"Not over-engineered"** — Code and UI should be clean and simple, not overly complex
5. **"Disney-quality visuals, Apple-level UX"** — High bar for visual polish and usability
6. **"No copyright/trademark violations"** — Use parody names, stay legally safe
7. **"Iron-clad legal documents"** — Privacy policy, ToS must be bulletproof
8. **"Addictive and fun with subtle monetization"** — Not a cash grab, but should make money
9. **"Decisions over numbers"** — Every screen should ask the player to decide something
10. **"Every quarter should have tension"** — No boring/empty turns
11. **"I don't mind pushing out our timeline"** — Quality > speed, explicitly stated
12. **"Make it feel like you're building a real product"** — The interactive phone mockup is central to the fantasy
13. **"Playable over perfect"** — Dev Bible Mantra #1: A working game with placeholder UI beats a beautiful screen with no logic
14. **"One system at a time"** — Dev Bible Mantra #2: Don't build fundraising until hiring works
15. **"Steal from PGM3"** — Dev Bible Mantra #5: Its UI patterns, session structure, and "just one more season" hooks are the north star
16. **"Your life is content"** — Dev Bible Mantra #6: Every frustrating thing about working in tech is a potential game event
17. **"Technical enough for engineers, accessible for everyone"** — Cursor S2: "depth a technical person would understand/love while also allowing non-tech people to learn and be inspired that tech is awesome"

---

## Summary Counts

| Status | Count |
|--------|-------|
| ✅ DONE | ~200 |
| 🔶 PARTIAL | ~35 |
| ❌ NOT STARTED (v1.0 scope) | ~85 |
| 🔮 FUTURE/DLC | ~20 |
| **Total tracked** | **~350** |

### Critical Path to Launch (must-do items):
1. ❌ Apple Developer + Google Play enrollment (user)
2. ❌ Export templates + first device build (user)
3. ❌ QA Section 23 mobile testing (user + dev)
4. ❌ `MONETIZATION_TEMP_DISABLED = false` + IAP wiring
5. ❌ Store listing assets (screenshots, description)
6. ❌ TestFlight / Play Store internal beta
7. ❌ Public launch

### High-priority before launch:
- ❌ Info icons/tooltips on all game metrics (accessibility)
- ❌ CAC / LTV / Gross Margin as displayed finance metrics
- 🔶 More bios (72 → 200)
- 🔶 More headlines (67 → 150)
- ❌ 30+ VC pitch dialogue variations (currently 0)
- ❌ 20+ quarterly report narrative templates (currently ~1)
- ❌ 10+ game over postmortem narrative templates (currently 0)
- 🔶 Scrolling/overflow UX audit
- ❌ Typography/theme pass
- 🔶 Manual balance empirical pass
- 🔶 Gameplay length pacing (game completes too quickly)
- ❌ Xcode simulator testing guide
- ❌ Art originality audit (no copied references)
- ❌ Event description variations (3–5 per event for replayability)

### Nice-to-have before launch:
- ❌ Simple view vs. detailed view toggle
- ❌ Postmortem screen
- 🔶 Finance metrics layman-friendly pass
- ❌ Lite/casual mode for non-tech players
- 🔶 More color variety in UI
- ❌ Feature assignment slots visual (clearer worker-to-feature UX)
- ❌ Employee onboarding period (reduced output after hire)
- ❌ R&D unlocks new feature categories
- ❌ User segments (early adopters/mainstream/enterprise)
- ❌ Competitive moat mechanic
- ❌ Base game scenario: "Bootstrapper's Dream" (no VC mode)

### Can wait until post-launch:
- All DLC content (v1.2–v1.6)
- Stock market endgame + stock ticker in news
- Corporate Ventures
- Dynamic org structures
- Custom sprite art / Kenney replacement
- AI narrative modes (Dynamic/Online)
- Silicon Valley character pack
- Real names companion JSON
- Scenario packs (Dot-Com Boom, AI Gold Rush, etc.)
- Employee contractor/intern types
- Competitor product depth + S&P 500 scale roster
- Employees typing → feature progress visual link
- Crunch/overtime button mechanic
- Partnerships / BD deals system
- Shipping quality decisions (MVP vs. Polished)
- Cross-path DLC conglomerate endgame (v2.0+)
- News piece reader reactions/comments
- Employee promotion system (Junior → Principal progression)
- Employee Speed attribute (separate from Skill)
- Employee Growth Potential attribute (Low/Med/High)
- Bundle: "Venture: Complete Collection" $12.99
- PathModule modular DLC architecture
- Named fundraising round progression (Pre-seed → Growth)
- Tools & software licenses cost category
- Legal/accounting costs scaling with size
- Salary band verification vs Dev Bible targets
- Automated regression / bug-catching system
- Royalty-free milestone visuals
