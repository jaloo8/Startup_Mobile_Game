# Venture — Tier 1 Launch Punch List

**Generated:** April 13, 2026
**Target:** Mid-May 2026 launch
**Purpose:** Every item that must be done before a real person plays this on a phone.

---

## Codebase Audit Results (April 13, 2026)

All 7 checks passed or have known-acceptable status:

| Check | Status | Detail |
|-------|--------|--------|
| Bare print() statements | PASS | All logging uses push_warning()/push_error() |
| Scene transitions | PASS | All route through SceneLoader.goto_scene() |
| Hardcoded desktop paths | PASS | All paths use res:// or user:// |
| App icon | PASS | assets/app_icon.png exists, referenced in project.godot |
| Analytics keys | PASS | Loaded from user://settings.json, not hardcoded |
| Mobile settings | PASS | Portrait locked, 720x1280, touch helper wired |
| Export presets | MISSING | No export_presets.cfg — must create in Godot Editor |

---

## Punch List

### PHASE 1: Enrollment (Owner: Jason — Week of April 13)

These are gates. Nothing else matters until they're done.

| # | Task | Cost | Time | Notes |
|---|------|------|------|-------|
| 1.1 | Enroll in Apple Developer Program | $99/yr | 24-48hrs approval | https://developer.apple.com/programs/enroll/ — Use Water Hazard Studios entity. Need D-U-N-S number if enrolling as org (takes 5+ business days). Individual enrollment is faster. |
| 1.2 | Enroll in Google Play Console | $25 one-time | Instant-24hrs | https://play.google.com/console/signup — Personal or organization account. |
| 1.3 | Install Xcode (latest) on Mac | Free | 10GB+ download | Required for iOS export. Must accept Xcode license: `sudo xcodebuild -license accept` |
| 1.4 | Install Android Studio + SDK | Free | 5GB+ download | Required for Android export. Need SDK, NDK, and build tools. |

### PHASE 2: First Device Build (Owner: Both — Target: April 20)

The single most important milestone. Get the game running on your iPhone 14.

| # | Task | Owner | Notes |
|---|------|-------|-------|
| 2.1 | Download Godot 4.6 export templates (iOS + Android) | Jason | Editor → Manage Export Templates → Download. Must match exact Godot version. |
| 2.2 | Create iOS export preset in Godot Editor | Jason | Project → Export → Add iOS. Set bundle ID: `com.waterhazardstudios.venture`. Team ID from Apple Developer portal. |
| 2.3 | Create Android export preset in Godot Editor | Jason | Project → Export → Add Android. Generate debug keystore. Set package name: `com.waterhazardstudios.venture`. |
| 2.4 | Create iOS provisioning profile | Jason | Apple Developer portal → Certificates, IDs & Profiles. Create App ID + Development provisioning profile for your iPhone 14. |
| 2.5 | Build and run on iPhone 14 | Jason | Export from Godot → Open .xcodeproj in Xcode → Build to device. First build will surface any issues. |
| 2.6 | Build and run on Galaxy S20 Ultra | Jason | Export APK from Godot → adb install or direct transfer. |
| 2.7 | Build and run on iPad Pro 11" | Jason | Same provisioning profile should work. Check layout scaling on larger screen. |
| 2.8 | Document any device-specific issues found | Both | Create issues list. This WILL surface problems — that's the point. |

### PHASE 3: Pre-Release Code Changes (Owner: Claude — Target: April 27)

These are code changes I can make once you confirm the game runs on device.

| # | Task | File(s) | Notes |
|---|------|---------|-------|
| 3.1 | Bump GAME_VERSION to "1.0.0" | src/autoload/game_state.gd line 4 | Currently "0.1.0". Should be "1.0.0" for launch. |
| 3.2 | Flip MONETIZATION_TEMP_DISABLED to false | src/autoload/ad_manager.gd line 32 | Only after IAP plugin is wired and tested. |
| 3.3 | Wire IAP plugin (iOS StoreKit) | src/autoload/ad_manager.gd | _setup_iap_provider() already scaffolded for InAppStore singleton. Need to install Godot iOS IAP plugin and test purchase flow. |
| 3.4 | Wire IAP plugin (Android Google Play Billing) | src/autoload/ad_manager.gd | Already scaffolded for GodotGooglePlayBilling singleton. Need to install plugin and configure. |
| 3.5 | Set up GameAnalytics keys | user://settings.json | Analytics already consent-gated. Need GA game key + secret key for iOS and Android. Optional for launch but recommended. |
| 3.6 | Verify app icon meets platform specs | assets/app_icon.png | iOS needs 1024x1024 no-alpha PNG. Android needs 512x512. Check current dimensions. |
| 3.7 | Run full smoke test + balance sim | tools/ | Final validation before submission. |

### PHASE 4: Store Listings (Owner: Claude drafts, Jason approves — Target: May 1)

| # | Task | Platform | Notes |
|---|------|----------|-------|
| 4.1 | App Store description (short + long) | iOS | See drafts below |
| 4.2 | App Store keywords (100 char limit) | iOS | See drafts below |
| 4.3 | App Store category + age rating | iOS | Games → Simulation, 4+ |
| 4.4 | Google Play description (short + long) | Android | See drafts below |
| 4.5 | Google Play tags + category | Android | Games → Simulation |
| 4.6 | Content rating questionnaire | Both | IARC — answer honestly (simulated violence: none, IAP: yes) |
| 4.7 | Privacy policy URL | Both | Host PRIVACY_POLICY.txt at a public URL (GitHub Pages works) |
| 4.8 | Screenshots (5-8 per platform) | Both | iPhone 14 + iPad. Capture key screens: dashboard, people, product mockup, fundraising, event popup, market leaderboard. |
| 4.9 | App preview video (optional) | iOS | 15-30 sec gameplay capture. Nice-to-have, not blocking. |

### PHASE 5: Beta Testing (Owner: Both — Target: May 5-12)

| # | Task | Platform | Notes |
|---|------|----------|-------|
| 5.1 | Upload build to TestFlight | iOS | Via Xcode or Transporter app. Apple reviews TestFlight builds (24-48hrs). |
| 5.2 | Upload build to Play Store internal track | Android | Instant availability for internal testers. |
| 5.3 | Recruit 5-10 beta testers | Both | Friends, family, startup/gaming people. Need at least a few non-tech testers. |
| 5.4 | Run QA smoke checklist on device | Both | docs/qa-smoke-checklist.md — starred items minimum. |
| 5.5 | Test IAP purchase flow (sandbox) | Both | TestFlight uses sandbox StoreKit. Play Store has test purchase mode. |
| 5.6 | Test free-to-premium upgrade path | Both | Play 8 quarters → hit paywall → purchase → verify unlock. |
| 5.7 | Collect and triage beta feedback | Both | Focus on crashes, save corruption, layout issues. Not feature requests. |

### PHASE 6: Submission (Owner: Jason — Target: May 12)

| # | Task | Platform | Notes |
|---|------|----------|-------|
| 6.1 | Submit to App Store Review | iOS | Allow 24-72hrs for review. First submissions sometimes take longer. |
| 6.2 | Submit to Google Play Review | Android | Usually 1-3 days. Can be faster. |
| 6.3 | Respond to any review rejections | Both | Common rejections: missing privacy policy link, IAP issues, metadata problems. |
| 6.4 | Set release date and publish | Both | Can stage for manual release after approval. |

---

## Store Listing Drafts

### App Store (iOS)

**App Name:** Venture: Startup Simulator
**Subtitle (30 char):** Build Your Tech Empire
**Category:** Games → Simulation
**Age Rating:** 4+ (no objectionable content)
**Price:** Free (with $2.99 IAP unlock)

**Promotional Text (170 char — can update without new build):**
Run your own tech startup. Hire engineers, ship products, raise funding, and outmaneuver competitors. Every quarter is a new crisis. Can you make it to IPO?

**Description:**
Venture is a management sim where you run a tech startup from a garage to IPO — or into the ground.

You are the founder. Every decision is yours: what to build, who to hire, when to raise money, and when to pivot. The game simulates realistic consequences across quarters of startup life.

FOUR COMPANY TYPES
Build a SaaS tool with enterprise sales pipelines. Launch a consumer app and chase virality. Run a marketplace and solve the chicken-and-egg problem. Create developer tools where API stability is life or death.

REAL STARTUP DECISIONS
Hire fast or hire right? Take VC money or bootstrap? Fix tech debt or ship features? Every choice has trade-offs that play out over quarters.

DEEP MANAGEMENT
Manage employees with personalities, morale, and stress. Allocate your team across features, bug fixes, tech debt, and R&D. Watch your product evolve on an interactive phone mockup.

COMPETE AND SURVIVE
86 AI competitors grow alongside you. Track the market leaderboard. React to economic cycles, industry trends, and surprise events. Survive recessions, poaching wars, and server outages.

THREE DIFFICULTY MODES
Sandbox for learning. Normal for a real challenge. Hardcore for founders who enjoy pain.

PLAY FREE THROUGH YEAR 2
Try the full game for 8 quarters. One $2.99 unlock to play forever — no ads, no subscriptions, no tricks.

**Keywords (100 char):**
startup,tycoon,simulation,management,business,CEO,tech,strategy,indie,mobile game

**What's New (for v1.0):**
Launch release! Build your tech startup from garage to IPO.

---

### Google Play Store

**App Name:** Venture: Startup Simulator
**Short Description (80 char):**
Run a tech startup from garage to IPO. Hire, build, fundraise, survive.

**Full Description:**
Venture is a management sim where you run a tech startup from a garage to IPO — or into the ground.

You are the founder. Every decision is yours: what to build, who to hire, when to raise money, and when to pivot. The game simulates realistic consequences across quarters of startup life.

FOUR COMPANY TYPES
Build a SaaS tool with enterprise sales pipelines. Launch a consumer app and chase virality. Run a marketplace and solve the chicken-and-egg problem. Create developer tools where API stability is life or death.

REAL STARTUP DECISIONS
Hire fast or hire right? Take VC money or bootstrap? Fix tech debt or ship features? Every choice has trade-offs that play out over quarters.

DEEP MANAGEMENT
Manage employees with personalities, morale, and stress. Allocate your team across features, bug fixes, tech debt, and R&D. Watch your product evolve on an interactive phone mockup.

COMPETE AND SURVIVE
86 AI competitors grow alongside you. Track the market leaderboard. React to economic cycles, industry trends, and surprise events. Survive recessions, poaching wars, and server outages.

THREE DIFFICULTY MODES
Sandbox for learning. Normal for a real challenge. Hardcore for founders who enjoy pain.

PLAY FREE THROUGH YEAR 2
Try the full game for 8 quarters. One unlock to play forever — no ads, no subscriptions, no tricks.

**Category:** Games → Simulation
**Content Rating:** IARC — Everyone
**Tags:** simulation, strategy, management, tycoon, business, offline

---

## Decision Log

| Decision | Date | Rationale |
|----------|------|-----------|
| Animations frozen, not removed | April 13, 2026 | Existing AnimHelper/stagger/pop_in work correctly. Removing would risk regressions. No new animation work for v1. Polish pass deferred to v2. |
| Illustrations deferred to Cursor | April 13, 2026 | Character illustrations handled separately. Current pixel sprites sufficient for v1 launch. |

---

## What's NOT in Tier 1 (Explicitly Deferred to v2)

- Animation polish pass
- New character illustrations (Cursor handling separately)
- AdMob SDK integration (launch with IAP only, no ads — simpler and cleaner)
- Content expansion (bios, headlines, VC dialogue, report templates)
- Balance tuning beyond current state
- Steam/desktop port
- DLC development
- GameAnalytics integration (optional, can add post-launch)

---

*This document is the single source of truth for launch readiness. Update it as items are completed.*
