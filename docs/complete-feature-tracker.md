# VENTURE — Complete Feature Tracker

**Purpose:** This is the single source of truth for every feature, system, and polish item mentioned across all conversations, memory files, and documentation. Written at the user's explicit request so nothing gets forgotten.

**Last updated:** April 7, 2026

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
| 94 | Event balance rebalance (12 events where one choice dominated) | ✅ DONE | |
| 95 | 3 press/media events (feature profile, hit piece, acquisition rumor) | ✅ DONE | In `events.json` |
| 96 | Dedicated press outlet personas (TekCrunch, Bloomburg, The Informant) | 🔶 PARTIAL | Events exist, full outlet system pending |
| 97 | Investigative-piece mechanic | ❌ NOT STARTED | |
| 98 | Reader-reaction headline variants | ❌ NOT STARTED | |
| 99 | Expand headlines to 150+ total | ❌ NOT STARTED | Content target from roadmap |
| 100 | Expand events to 50+ (target from Classic Mode) | ✅ DONE | Already at 50+ |

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
| 174 | Custom sprite art commission/generation | ❌ NOT STARTED | Match Pixar-inspired avatar style |
| 175 | AnimationPlayer multi-step office sequences | ❌ NOT STARTED | Employees react to events, celebrate, droop |
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

## 26. Content Packs (Special)

| # | Feature | Status | Notes |
|---|---------|--------|-------|
| 249 | Silicon Valley (show) character pack | ❌ NOT STARTED | Erlich, Gilfoyle, Dinesh, Jared, Gavin, Monica, Big Head parodies |
| 250 | Scenario packs ("Dot-Com Boom", "AI Gold Rush", "Pandemic Pivot") | ❌ NOT STARTED | JSON configs |

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

## Summary Counts

| Status | Count |
|--------|-------|
| ✅ DONE | ~198 |
| 🔶 PARTIAL | ~14 |
| ❌ NOT STARTED (v1.0 scope) | ~45 |
| 🔮 FUTURE/DLC | ~16 |
| **Total tracked** | **~280** |

### Critical Path to Launch (must-do items):
1. ❌ Apple Developer + Google Play enrollment (user)
2. ❌ Export templates + first device build (user)
3. ❌ QA Section 23 mobile testing (user + dev)
4. ❌ `MONETIZATION_TEMP_DISABLED = false` + IAP wiring
5. ❌ Store listing assets (screenshots, description)
6. ❌ TestFlight / Play Store internal beta
7. ❌ Public launch

### Nice-to-have before launch:
- 🔶 More bios (72 → 200)
- 🔶 More headlines (67 → 150)
- ❌ Typography/theme pass
- ❌ Postmortem screen
- 🔶 Manual balance empirical pass

### Can wait until post-launch:
- All DLC content (v1.2–v1.6)
- Stock market endgame
- Corporate Ventures
- Dynamic org structures
- Custom sprite art
- AI narrative modes
- Silicon Valley character pack
