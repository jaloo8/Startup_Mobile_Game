# Venture — Visual Asset Brief (v1)

**Date:** April 13, 2026
**Purpose:** Specific art assets needed, their dimensions, where they go in the game, and what they should look like. Designed to be handed to Cursor or an artist for generation.
**Art Style:** "Cozy Bloomberg terminal" — dark UI, pixel art characters, clean modern illustrations. Think professional but playful.

---

## How the Product Visual System Works (Context for Artists)

The game has an interactive phone mockup that shows the player's product evolving as they build features. It's rendered inside a fake phone frame (bezel, notch, status bar, home indicator). Currently, the mockup is built programmatically — colored rectangles, labels, and small thumbnail PNGs. The system uses a `_gate(feature_id, node)` function that hides UI elements until the player ships that feature, then reveals them with animations.

There are 4 company types, each with 10 features that progressively unlock. The phone mockup evolves from nearly empty ("Ship features to bring your app to life!") to a fully populated app/dashboard/marketplace/console.

---

## CATEGORY 1: Product Mockup Evolution Images (THE BIG OPPORTUNITY)

This is the user's key insight and the game's most unique visual hook. Instead of programmatic colored rectangles, replace key mockup elements with actual illustrated screenshots showing the product at different stages of completeness.

### How It Works Technically

The current `ProductVisual` already loads images from `assets/illustrations/` using helper functions like `_img_card()`, `_img_bubble()`, and `_img_icon()`. New images slot directly into the existing gating system — each is tied to a `feature_id` and hidden until shipped.

### Consumer App Mockup (10 feature stages)

The consumer app looks like a social/content app (think Instagram meets TikTok). The phone shows a feed-based UI that fills in as features ship.

| Feature ID | Asset Name | Dimensions | What It Shows | Current State |
|-----------|------------|------------|---------------|---------------|
| (base) | `consumer_app_empty.png` | 280×480 | Bare-bones app shell: white/dark screen, single nav bar, "Welcome" text, empty feed area. Feels like a v0.1 prototype. | Programmatic (placeholder text) |
| `profile_pages` | `consumer_profile_card.png` | 60×60 | Small avatar circle with name below — appears in header bar | EXISTS: `consumer_profile_avatar.png` |
| `push_notifications` | `consumer_notif_bell.png` | 24×24 | Bell icon with red dot badge | Programmatic (emoji 🔔) |
| `social_feed` | `consumer_feed_stage1.png` | 260×200 | App now has a feed: 3 content cards stacked vertically with thumbnails, usernames, timestamps. Looks like a real social app. | PARTIAL: 3 thumb PNGs exist (`consumer_thumb_1-3.png`), but they're small placeholders |
| `stories` | `consumer_stories_row.png` | 260×40 | Row of 4-5 circular story bubbles with gradient rings, like Instagram stories | PARTIAL: 4 story PNGs exist (`consumer_story_1-4.png`) |
| `dark_mode` | `consumer_dark_overlay.png` | 280×480 | Semi-transparent dark tint layer | Programmatic (ColorRect) — fine as-is |
| `sharing` | `consumer_share_icon.png` | 24×24 | Share/export arrow icon | Programmatic (text "↗") |
| `offline_mode` | `consumer_offline_icon.png` | 24×24 | Download/cloud icon | Programmatic (text "↓") |
| `recommendations` | `consumer_recs_row.png` | 260×80 | "For You" section: 3 recommendation cards with images and short titles. Feels like a discovery page. | PARTIAL: 3 rec PNGs exist (`consumer_rec_1-3.png`) |
| `iap` | `consumer_premium_banner.png` | 260×40 | Gold/premium banner: "★ PREMIUM — Unlock exclusive content" | Programmatic (gold pill with text) |
| `live_chat` | `consumer_chat_fab.png` | 48×48 | Floating action button — blue circle with chat bubble icon | Programmatic (blue pill with text) |

**Key consumer full-stage composites (THE REAL WINS):**

These are the "wow" images — full-screen mockups showing the app at each evolution stage. They replace the individual elements when the player has reached that stage.

| Stage | Asset Name | Dimensions | What It Shows |
|-------|------------|------------|---------------|
| Stage 0 (empty) | `consumer_stage_0.png` | 280×480 | Bare prototype: nav bar, empty screen, "Welcome to [App Name]" centered text, gray placeholder boxes |
| Stage 1 (3 features) | `consumer_stage_1.png` | 280×480 | Profile + Feed + Notifications visible. Feels like a real app now — content cards populated, avatar in header, bell icon |
| Stage 2 (6 features) | `consumer_stage_2.png` | 280×480 | Stories row, recommendations section, share buttons. The app feels alive — content everywhere, social features working |
| Stage 3 (all 10) | `consumer_stage_3.png` | 280×480 | Fully built: dark mode option, premium tier banner, live chat FAB, offline indicator. Looks like a polished, shipped consumer app |

### SaaS Dashboard Mockup (10 feature stages)

The SaaS product looks like a B2B dashboard (think Datadog or Notion admin panel). Dark theme, data-dense.

| Feature ID | Asset Name | Dimensions | What It Shows |
|-----------|------------|------------|---------------|
| (base) | `saas_app_empty.png` | 280×480 | Empty dashboard shell: sidebar with company logo, "Dashboard" header, empty content area |
| `user_dashboard` | `saas_metrics_cards.png` | 260×60 | Row of 3 metric cards: Users (blue), Revenue (green), Churn (red) — with fake numbers |
| `billing` | `saas_billing_tab.png` | 50×24 | "Billing" tab in top nav row |
| `analytics` | `saas_chart.png` | 260×100 | Line chart showing growth trend — clean, minimal, dark-themed |
| `api_v2` | `saas_api_tab.png` | 50×24 | "API v2" tab in nav row |
| `sso_login` | `saas_sso_badge.png` | 40×20 | Green "SSO" badge in header |
| `admin_panel` | `saas_admin_tab.png` | 50×24 | "Admin" tab in nav row |
| `multi_tenancy` | `saas_tenant_selector.png` | 260×30 | Organization/tenant dropdown at top of page |
| `audit_log` | `saas_audit_panel.png` | 260×80 | Log entries panel: timestamps, actions, user emails — looks like a real audit trail |
| `integrations` | `saas_integrations_grid.png` | 260×80 | Grid of integration icons (Slack, Jira, GitHub-parodies) with "Connected" badges |
| `custom_reports` | `saas_reports_tab.png` | 50×24 | "Reports" tab in nav row |

**SaaS full-stage composites:**

| Stage | Asset Name | Dimensions | What It Shows |
|-------|------------|------------|---------------|
| Stage 0 | `saas_stage_0.png` | 280×480 | Empty dashboard: header, sidebar icons, "No data yet" in content area |
| Stage 1 | `saas_stage_1.png` | 280×480 | Metrics visible, billing tab, basic dashboard populated with charts |
| Stage 2 | `saas_stage_2.png` | 280×480 | SSO badge, admin panel, analytics charts, API docs link. Looks enterprise-ready |
| Stage 3 | `saas_stage_3.png` | 280×480 | Full enterprise SaaS: multi-tenancy dropdown, audit log, integrations grid, custom reports. Looks like Datadog |

### Marketplace Mockup (10 feature stages)

The marketplace looks like an e-commerce platform (think Etsy or Airbnb). Grid-based product listings.

| Feature ID | Asset Name | Dimensions | What It Shows |
|-----------|------------|------------|---------------|
| (base) | `marketplace_app_empty.png` | 280×480 | Bare marketplace shell: search bar at top, empty grid area, "List your first product" CTA |
| `seller_onboarding` | `marketplace_seller_form.png` | 260×80 | Seller onboarding flow preview: form fields, upload button |
| `search_filters` | `marketplace_search_bar.png` | 260×40 | Search bar with filter chips (Price, Category, Rating) |
| `ratings` | `marketplace_rating_stars.png` | 80×16 | Star rating display (e.g., ★★★★☆ 4.2) |
| `payment_escrow` | `marketplace_secure_badge.png` | 120×24 | "Secure Payment" badge with lock icon |
| `disputes` | `marketplace_dispute_panel.png` | 260×60 | "Resolution Center" mini-panel |
| `seller_analytics` | `marketplace_seller_dash.png` | 260×80 | Seller dashboard: sales graph, revenue number, listing count |
| `promoted_listings` | `marketplace_promoted_tag.png` | 60×18 | "Promoted" badge on a listing card |
| `categories` | `marketplace_category_chips.png` | 260×30 | Scrollable category pills: Electronics, Home, Fashion, etc. |
| `delivery_tracking` | `marketplace_tracking.png` | 260×50 | Delivery progress bar: Ordered → Shipped → Out for Delivery → Delivered |
| `referral_program` | `marketplace_referral_banner.png` | 260×40 | "Invite a friend, get $10" referral banner |

**Marketplace full-stage composites:**

| Stage | Asset Name | Dimensions | What It Shows |
|-------|------------|------------|---------------|
| Stage 0 | `marketplace_stage_0.png` | 280×480 | Empty storefront: search bar, "No listings yet" empty state |
| Stage 1 | `marketplace_stage_1.png` | 280×480 | Basic marketplace: product grid with 4-6 items, ratings, search working |
| Stage 2 | `marketplace_stage_2.png` | 280×480 | Trust layer: escrow badges, category navigation, seller profiles |
| Stage 3 | `marketplace_stage_3.png` | 280×480 | Fully built: promoted listings, delivery tracking, referral banner, dispute center. Looks like Etsy |

### Dev Tools Mockup (10 feature stages)

The dev tools product looks like an API console/developer portal (think Stripe Dashboard or Vercel). Code snippets, terminal vibes.

| Feature ID | Asset Name | Dimensions | What It Shows |
|-----------|------------|------------|---------------|
| (base) | `devtools_app_empty.png` | 280×480 | Bare API console: dark terminal aesthetic, "Get started" text, empty endpoints list |
| `cli_tool` | `devtools_cli_snippet.png` | 260×50 | Terminal window: `$ venture-cli init` with green output text |
| `sdk` | `devtools_sdk_cards.png` | 260×60 | Language SDK cards: Python, Node.js, Go, Ruby — with install commands |
| `api_docs` | `devtools_docs_panel.png` | 260×100 | API documentation page: endpoint list, code example, response preview |
| `sandbox` | `devtools_sandbox_badge.png` | 80×24 | "Sandbox Mode" toggle/badge (green when active) |
| `webhooks` | `devtools_webhooks_panel.png` | 260×60 | Webhook configuration: URL field, event dropdown, "Send Test" button |
| `rate_limiting` | `devtools_rate_limit.png` | 260×30 | Rate limit bar: "4,521 / 10,000 requests" with usage bar |
| `auth_tokens` | `devtools_auth_panel.png` | 260×50 | API key management: masked key with copy button, "Regenerate" button |
| `usage_dashboard` | `devtools_usage_chart.png` | 260×80 | API usage chart: requests over time, response time percentiles |
| `plugin_system` | `devtools_plugins_grid.png` | 260×80 | Plugin marketplace: grid of community plugins with install counts |
| `cicd_integration` | `devtools_cicd_panel.png` | 260×50 | CI/CD config: GitHub Actions / Jenkins logos with "Connected" status |

**Dev Tools full-stage composites:**

| Stage | Asset Name | Dimensions | What It Shows |
|-------|------------|------------|---------------|
| Stage 0 | `devtools_stage_0.png` | 280×480 | Empty console: dark terminal look, blinking cursor, "No API keys yet" |
| Stage 1 | `devtools_stage_1.png` | 280×480 | Basic developer portal: docs visible, CLI install command, SDK cards |
| Stage 2 | `devtools_stage_2.png` | 280×480 | Production-ready: webhooks, auth tokens, rate limiting visible. Looks professional |
| Stage 3 | `devtools_stage_3.png` | 280×480 | Full ecosystem: plugin marketplace, CI/CD integrations, usage dashboards. Looks like Stripe |

---

## CATEGORY 2: Character Portraits

Currently using 8 avatar PNGs + procedural 14×20 pixel characters. These work but are generic.

### Employee Detail View Portraits

Shown on the employee detail screen when you tap on a person.

| Asset | Dimensions | Style | Count Needed |
|-------|------------|-------|-------------|
| `portrait_[specialty]_[variant].png` | 120×120 | Pixel art bust portrait (shoulders up). Same color palette as pixel characters. Should feel like a zoomed-in, more detailed version of the 14×20 sprites. | 18 total (9 specialties × 2 gender-neutral variants each) |

**9 Specialties:** Frontend, Backend, Mobile, Design, Data/ML, DevOps, Sales, Marketing, Operations

**Visual cues per specialty:**
- Frontend: bright hoodie, laptop sticker visible
- Backend: darker colors, server rack or terminal in background
- Mobile: holding a phone
- Design: colorful accessories, creative vibe
- Data/ML: glasses common, neural network doodle
- DevOps: headset/monitoring screens behind
- Sales: button-down shirt, more polished
- Marketing: creative casual, maybe holding a megaphone
- Operations: clipboard or spreadsheet vibe

### Founder Archetype Portraits

Shown on the new game setup screen when picking your founder type.

| Asset | Dimensions | Style | Count Needed |
|-------|------------|-------|-------------|
| `founder_engineer.png` | 160×160 | Pixel art portrait. Hoodie, laptop, code on screen behind them. | 1 |
| `founder_finance.png` | 160×160 | Pixel art. Shirt/vest, calculator or spreadsheet, money charts behind. | 1 |
| `founder_recruiter.png` | 160×160 | Pixel art. Professional but warm, people/org-chart behind them. | 1 |
| `founder_hustler.png` | 160×160 | Pixel art. Confident energy, phone in hand, social media or pitch deck behind. | 1 |
| `founder_custom.png` | 160×160 | Pixel art. Neutral/flexible look, stat sliders or question marks behind. | 1 |
| `founder_godmode.png` | 160×160 | Pixel art. Gold/premium aura, crown or halo, all stats maxed vibe. | 1 |

---

## CATEGORY 3: Office Evolution

4 office images already exist (`office_0_garage.png` through `office_3_hq.png`). These show the workspace evolving as the company grows.

**Current state:** These exist and work. Only improve if quality is below bar.

**Optional enhancement — office with employees:** If time allows, versions of each office with pixel characters working at desks. But this is v2 scope.

---

## CATEGORY 4: Item / UI Icons

Replace text-based icons with actual pixel art icons. Currently many UI elements use emoji or text characters.

| Asset | Dimensions | Where Used | Current State |
|-------|------------|-----------|---------------|
| `icon_bell.png` | 24×24 | Consumer app notification bell | Emoji 🔔 |
| `icon_share.png` | 24×24 | Consumer app share button | Text "↗" |
| `icon_download.png` | 24×24 | Consumer app offline mode | Text "↓" |
| `icon_chat.png` | 24×24 | Consumer app live chat FAB | Text "Chat" |
| `icon_star.png` | 16×16 | Marketplace ratings | Can be generated |
| `icon_lock.png` | 24×24 | Paywall lock icon | Emoji 🔒 |
| `icon_crown.png` | 24×24 | Premium/prestige indicator | Text "★" |
| `icon_briefcase.png` | 24×24 | SaaS/business contexts | None |
| `icon_code.png` | 24×24 | Dev tools contexts | None |
| `icon_cart.png` | 24×24 | Marketplace contexts | None |
| `icon_chart_up.png` | 24×24 | Revenue/growth indicators | None |
| `icon_chart_down.png` | 24×24 | Churn/loss indicators | None |
| `icon_person_add.png` | 24×24 | Hire button | None |
| `icon_person_remove.png` | 24×24 | Fire button | None |
| `icon_money.png` | 24×24 | Fundraising/finance | None |
| `icon_trophy.png` | 24×24 | Achievements | None |

**Style:** Pixel art, 24×24, transparent background, 2-3 colors max per icon. Should match the "cozy Bloomberg terminal" aesthetic.

---

## CATEGORY 5: Store / Marketing Assets

These are for App Store and Google Play listings. Not in-game.

| Asset | Dimensions | What It Shows |
|-------|------------|---------------|
| `store_screenshot_1_hero.png` | 1290×2796 (iPhone) | Hero shot: phone mockup showing dashboard, title overlay "Run Your Tech Startup" |
| `store_screenshot_2_types.png` | 1290×2796 | 4 company type cards: SaaS, Consumer, Marketplace, Dev Tools |
| `store_screenshot_3_team.png` | 1290×2796 | Employee list with pixel character avatars, hire/fire buttons |
| `store_screenshot_4_product.png` | 1290×2796 | The phone mockup at Stage 3 (the "wow" shot) |
| `store_screenshot_5_finance.png` | 1290×2796 | Finance screen: funding round, burn rate, runway |
| `store_screenshot_6_events.png` | 1290×2796 | Event popup with choices, news ticker |
| `store_feature_graphic.png` | 1024×500 (Google Play) | Progression: garage → coworking → office → HQ with company growing |
| `store_ipad_screenshot_1.png` | 2048×2732 (iPad) | Same as iPhone hero but scaled for iPad |

---

## PRIORITY ORDER (What to Generate First)

**Priority 1 — Ship blockers (do these first):**
1. Store screenshots (Category 5) — Can't submit to app stores without them
2. Google Play feature graphic — Required for Play Store listing

**Priority 2 — Biggest visual impact:**
3. Full-stage composites (the 4 stage images per company type = 16 images) — This is the unique selling point
4. Founder archetype portraits (6 images) — First thing players see in new game setup

**Priority 3 — Polish pass:**
5. UI icons (Category 4, ~16 icons) — Replace emoji/text with pixel art
6. Individual feature element images — Fill in the gaps in the mockup
7. Employee specialty portraits (18 images)

---

## TECHNICAL NOTES FOR CURSOR / ARTIST

1. **All assets go in:** `assets/illustrations/` (product mockups) or `assets/icons/` (UI icons) or `assets/avatars/` (character portraits)
2. **Format:** PNG, transparent background where appropriate, no alpha on app icon
3. **Color palette:** Match existing dark theme — navy `#0F172A`, blue `#2563EB`, green `#22C55E`, gold `#F59E0B`, red `#EF4444`, white text `#F8FAFC`
4. **Phone mockup images render at:** 280×480 pixels inside the phone frame (actual screen area after bezel/chrome)
5. **The phone frame is already built in code** — you're only making the screen content, not the phone itself
6. **Feature gating is handled in code** — each image gets shown/hidden automatically. Artist doesn't need to worry about game logic.
7. **Pixel art style for characters** — match the existing 14×20 sprite aesthetic but at higher resolution for portraits
8. **Dashboard/app mockups should look realistic** — like actual screenshots of real apps, but with fake data and parody branding. No real company logos.
9. **Keep text in images readable at mobile resolution** — minimum 8pt equivalent when rendered on a 720×1280 screen

---

## CODE CHANGES NEEDED (After Art Is Generated)

Once assets are generated, the code changes to integrate them are minimal:

1. **Product mockup composites:** Add a stage-based system to `ProductVisual` that swaps between composite images based on shipped feature count. ~50 lines of code change.
2. **Icons:** Replace emoji/text labels with `TextureRect` nodes loading from `assets/icons/`. ~20 lines per icon.
3. **Portraits:** Add `TextureRect` to employee detail view loading from `assets/avatars/`. ~30 lines.
4. **Founder portraits:** Add `TextureRect` to new game setup screen. ~20 lines.

None of these are architectural changes — they're drop-in replacements for existing programmatic placeholders.

---

*This brief is the art team's source of truth. Update it as assets are completed.*
