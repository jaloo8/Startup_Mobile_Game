# Venture — Cursor Art Generation Prompt Guide

**Date:** April 13, 2026 (updated)
**Purpose:** Copy-paste ready prompts for Cursor to generate every visual asset the game needs. Each prompt is self-contained with exact specs.

**How the code works:** All images load from `assets/illustrations/` via a `_load_tex(filename)` helper. If the file exists, it's displayed. If not, the code falls back to a colored rectangle. This means **generating a PNG with the right filename is all you need** — the code picks it up automatically for existing image slots.

**Color palette (include in every prompt):**
- Dark navy: `#0F172A`, `#1E293B`
- Blue accent: `#2563EB`, `#3B82F6`, `#60A5FA`
- White text: `#F8FAFC`
- Gold: `#F59E0B`
- Green: `#22C55E`
- Red: `#EF4444`
- Muted gray: `#94A3B8`

---

## HOW THE PRODUCT MOCKUP WORKS (Read This First)

The game has an interactive phone mockup built in code (`src/ui/product/product_visual.gd`). It renders a fake phone with a status bar, notch, and home indicator. Inside the phone, a company-specific UI is built from helper functions:

- `_img_card(filename, height)` — Loads a PNG as a card. Falls back to a colored rectangle.
- `_img_bubble(filename, size)` — Loads a PNG as a circle. Falls back to a colored pill.
- `_img_icon(filename, size, corner)` — Loads a PNG as a small icon. Falls back to a colored pill.
- `_card(color, height)` — Always a colored rectangle (no image slot yet).
- `_pill(color)` — Always a colored shape (no image slot yet).

**The Consumer type already loads 13 images from `assets/illustrations/`.** The other 3 types (SaaS, Marketplace, Dev Tools) are 100% procedural — no images yet. That's our biggest visual upgrade opportunity.

**All images go in:** `assets/illustrations/` (the code reads from this folder)

---

## SECTION 1: CONSUMER APP COMPONENT IMAGES

These already have working code slots. Just generate better versions.

### Existing Slots (upgrade quality)

These files already exist and are already loaded by the code. Generate better versions to replace them.

#### Prompt 1 — Consumer Brand Badge
**File:** `assets/illustrations/consumer_brand_badge.png`
**Used at:** Line 905 — `_img_icon("consumer_brand_badge.png", 22, 9)`
**Display size:** 22×22, rounded corners (9px radius)
```
Create a tiny app icon/badge (64x64 pixels, scale down to 22x22 in-game) for a fictional consumer social app.

- A simple, recognizable logo mark — could be an abstract shape, letter, or symbol
- Bold colors that pop on a dark background: use bright blue (#3B82F6) or gradient blue-to-purple
- Rounded square shape (the code clips it with rounded corners)
- Should read clearly at 22x22 pixels — keep it VERY simple (1-2 shapes max)
- Dark background (#0F172A) or transparent
- Think: Instagram's gradient camera icon or Twitter's bird — simple, bold, iconic
- This is for a FICTIONAL app, not a real brand
- Style: flat/material design icon, clean edges
```

#### Prompt 2 — Consumer Profile Avatar
**File:** `assets/illustrations/consumer_profile_avatar.png`
**Used at:** Line 931 — `_img_bubble("consumer_profile_avatar.png", 22)`
**Display size:** 22×22, circular clip
```
Create a small circular profile avatar (64x64 pixels, displayed at 22x22) for a consumer app mockup.

- A generic, friendly user avatar — silhouette or simple face
- Works as a tiny circle in a dark-themed app header bar
- Warm skin tone with a subtle smile or neutral expression
- Simple pixel art or flat illustration style
- Should read as "user profile photo" even at 22x22 pixels
- Background: a solid color (blue #3B82F6 or warm neutral) — the code clips this into a circle
- NOT a real person — generic/illustrated
```

#### Prompt 3 — Consumer Feed Thumbnails (3 images)
**Files:** `assets/illustrations/consumer_thumb_1.png`, `consumer_thumb_2.png`, `consumer_thumb_3.png`
**Used at:** Line 1014-1015 — `_img_card(img_file, 52, 4)`
**Display size:** ~80×52 each (expand to fill width, 52px tall, 4px corner radius)
```
Create 3 social media feed thumbnail images for a consumer app mockup. Each is 160x104 pixels (displayed at ~80x52 in-game).

These represent content posts in a social feed — like Instagram explore thumbnails or TikTok feed cards.

Thumbnail 1: A colorful food/lifestyle photo — bright colors, warm tones (oranges, reds)
Thumbnail 2: A landscape/travel scene — blues, greens, natural tones
Thumbnail 3: An urban/city scene — neon lights, night vibes, purples and blues

All three should:
- Be photographic in style (not pixel art) but can be slightly stylized/illustrated
- Look like real social media content thumbnails
- Be visually distinct from each other (different color palettes)
- Have enough detail to look interesting at 80x52 pixels
- NOT contain real people's faces — use scenery, objects, or abstract compositions
- Dark-themed edges to blend with the navy app background
```

#### Prompt 4 — Consumer Story Bubbles (4 images)
**Files:** `assets/illustrations/consumer_story_1.png`, `consumer_story_2.png`, `consumer_story_3.png`, `consumer_story_4.png`
**Used at:** Line 1005-1006 — `_img_bubble(img_file, 20)`
**Display size:** 20×20 each, circular clip
```
Create 4 small circular story bubble avatars for a consumer app mockup. Each is 64x64 pixels (displayed at 20x20 circles).

These represent different users' story bubbles (like Instagram stories). Each should be visually distinct.

Bubble 1: A warm-toned avatar with reddish/orange background — friendly, energetic
Bubble 2: A cool-toned avatar with blue/teal background — calm, creative
Bubble 3: A purple/pink avatar — playful, trendy
Bubble 4: A green/earth-toned avatar — natural, outdoorsy

All should:
- Be simple enough to read at 20x20 pixels
- Be distinct from each other in color and feel
- Work as tiny circles — the code clips them with full rounded corners
- Be illustrated/stylized — NOT real photos
- Can be abstract patterns, simple face illustrations, or color-blocked designs
```

#### Prompt 5 — Consumer Recommendation Cards (3 images)
**Files:** `assets/illustrations/consumer_rec_1.png`, `consumer_rec_2.png`, `consumer_rec_3.png`
**Used at:** Line 978-979 — `_img_card(img_file, 38, 4)`
**Display size:** ~70×38 each (expand to fill, 38px tall, 4px corners)
```
Create 3 recommendation card thumbnail images for a "For You" section in a consumer app. Each is 140x76 pixels (displayed at ~70x38 in-game).

These represent personalized content recommendations — like Spotify's "Made for You" or YouTube's "Recommended."

Card 1: A creative/artistic composition — paint splashes, abstract art vibe, warm colors
Card 2: A tech/gadget themed image — devices, screens, cool blue tones
Card 3: A nature/wellness themed image — plants, soft greens, calming

All should:
- Look like curated content cards with visual interest
- Be distinct in color palette
- Read well at 70x38 — bold shapes, not fine detail
- Dark edges to blend with navy background
- NOT contain real brand logos or real people's faces
```

---

## SECTION 2: SAAS DASHBOARD — NEW COMPONENT IMAGES

The SaaS mockup is currently 100% procedural (colored rectangles). These images require small code changes to wire up — I'll handle the code, you generate the images.

**Save all to:** `assets/illustrations/`

#### Prompt 6 — SaaS Analytics Chart
**File:** `assets/illustrations/saas_chart.png`
**Target:** Replace the procedural bar chart at line 1139-1147 with an `_img_card("saas_chart.png", 60)`
**Display size:** ~260×60 (full width card, 60px tall)
```
Create a dark-themed analytics chart image (520x120 pixels, displayed at ~260x60) for a B2B SaaS dashboard mockup.

Show a simple line chart displaying "Revenue Trend" or "Monthly Growth":
- Dark background (#111827)
- A smooth upward-trending blue line (#3B82F6) with subtle gradient fill below it
- 6-8 data points along the line
- Faint horizontal grid lines in dark gray (#1F2937)
- Small axis labels at bottom: "Jan Feb Mar Apr May Jun Jul" in muted gray (#64748B)
- Optional: a subtle green arrow "↑ 23%" in the top-right corner
- Clean, professional, Datadog/Grafana dark-mode aesthetic
- Rounded corners (the code clips with 4px radius)
- This should look like a real SaaS analytics chart, not pixel art
```

#### Prompt 7 — SaaS Integration Icons Row
**File:** `assets/illustrations/saas_integrations.png`
**Target:** Replace colored pills at line 1155-1159 with an `_img_card("saas_integrations.png", 24)`
**Display size:** ~260×24 (full width, 24px tall)
```
Create a row of integration app icons (520x48 pixels, displayed at ~260x24) for a SaaS dashboard.

Show 4 small app icons in a horizontal row with equal spacing:
- Icon 1: A purple chat bubble (represents a messaging tool like Slack)
- Icon 2: A blue board/kanban icon (represents a project tool like Jira)
- Icon 3: A dark circle with code brackets <> (represents a code tool like GitHub)
- Icon 4: A green circle with a checkmark (represents an automation tool)
- Each icon is about 20x20 pixels with small green "connected" dot in corner
- Dark background (#111827) or transparent
- Flat/material design style icons — NOT real brand logos
- Small "Connected" text in green (#22C55E) below the row (optional, only if readable)
```

#### Prompt 8 — SaaS Audit Log Panel
**File:** `assets/illustrations/saas_audit_log.png`
**Target:** Replace text labels at line 1172-1178 with an `_img_card("saas_audit_log.png", 48)`
**Display size:** ~260×48 (full width, 48px tall)
```
Create a dark-themed audit log panel image (520x96 pixels, displayed at ~260x48) for a SaaS dashboard.

Show 3 log entries in a monospace-style list:
- "09:41:22  user.login      admin@acme.co    ✓" in green-tinted text
- "09:38:15  billing.update  finance@acme.co  ✓" in blue-tinted text
- "09:35:01  report.export   ceo@acme.co      ✓" in white text
- Dark background (#0F172A)
- Subtle horizontal divider lines between entries (#1F2937)
- Monospace font feel (even if illustrated)
- Should feel like a real audit trail / system log
- NOT pixel art — clean, professional, enterprise aesthetic
```

---

## SECTION 3: MARKETPLACE — NEW COMPONENT IMAGES

The Marketplace mockup has product cards as colored rectangles. Replace with actual product images.

**Save all to:** `assets/illustrations/`

#### Prompt 9 — Marketplace Product Cards (3 images)
**Files:** `assets/illustrations/marketplace_product_1.png`, `marketplace_product_2.png`, `marketplace_product_3.png`
**Target:** Replace `_card(color, 46)` calls at line 1261 with `_img_card()` calls
**Display size:** ~75×46 each (expand to fill column, 46px tall)
```
Create 3 product listing thumbnail images for a marketplace/e-commerce app. Each is 150x92 pixels (displayed at ~75x46).

These represent products for sale on a marketplace platform (think Etsy or Amazon).

Product 1: A handmade ceramic mug — warm brown/cream tones, artisanal feel
Product 2: A minimalist desk lamp — cool blue/silver tones, modern design
Product 3: A canvas tote bag — earth green tones, eco/natural feel

All should:
- Look like real product photography on a simple background
- Be slightly stylized (illustrated realism, not photographic)
- Have warm, inviting colors that pop on a dark (#0F172A) background
- Be distinct and recognizable at 75x46 pixels
- NOT contain real brand names or logos
- Subtle shadow/depth to feel like product cards on an e-commerce site
```

#### Prompt 10 — Marketplace Delivery Tracking Bar
**File:** `assets/illustrations/marketplace_tracking.png`
**Target:** Replace text labels at line 1273-1278 with an `_img_card("marketplace_tracking.png", 36)`
**Display size:** ~260×36 (full width, 36px tall)
```
Create a delivery tracking progress bar image (520x72 pixels, displayed at ~260x36) for a marketplace app.

Show a horizontal progress bar with 4 steps:
- "Packed" (completed, green checkmark ✓)
- "Shipped" (completed, green checkmark ✓)
- "In Transit" (active, pulsing blue dot)
- "Delivered" (pending, gray dot)
- Connected by a line: green for completed sections, gray for pending
- Step labels below each dot in small text
- Dark background (#0F172A)
- Green (#22C55E) for completed, blue (#2563EB) for active, gray (#475569) for pending
- Clean, modern, like a real shipping tracker
```

---

## SECTION 4: DEV TOOLS — NEW COMPONENT IMAGES

The Dev Tools mockup is terminal/IDE themed. Currently all procedural.

**Save all to:** `assets/illustrations/`

#### Prompt 11 — Dev Tools CLI Snippet
**File:** `assets/illustrations/devtools_cli.png`
**Target:** New `_img_card("devtools_cli.png", 40)` in the dev tools builder
**Display size:** ~260×40 (full width, 40px tall)
```
Create a terminal/CLI code snippet image (520x80 pixels, displayed at ~260x40) for a developer tools mockup.

Show a mini terminal window with 2 lines of code:
$ npm install @venture/sdk
✓ Successfully installed v2.1.0

- Very dark background (#0A0E1A) — darker than the rest of the app
- Dollar sign prompt ($) in gray (#64748B)
- Command text in white (#F8FAFC)
- Success checkmark and message in green (#22C55E)
- Monospace font style
- Subtle terminal window chrome at top (optional): three dots (red/yellow/green) or just a thin border
- Should feel like a real terminal — NOT pixel art
- Rounded corners (code clips with 4px radius)
```

#### Prompt 12 — Dev Tools API Docs Panel
**File:** `assets/illustrations/devtools_docs.png`
**Target:** New `_img_card("devtools_docs.png", 70)` in the dev tools builder
**Display size:** ~260×70 (full width, 70px tall)
```
Create an API documentation panel image (520x140 pixels, displayed at ~260x70) for a developer tools product.

Show a mini API docs page with a code example:
- Header: "GET /api/v1/users" in bold white text with a green "200" badge
- Code block showing a JSON response:
  {
    "data": [
      { "id": 1, "name": "Jane" }
    ]
  }
- Syntax highlighting: strings in green (#22C55E), keys in blue (#60A5FA), numbers in gold (#F59E0B), brackets in white
- Very dark background (#0A0E1A)
- Subtle border or panel outline (#1F2937)
- Monospace font feel throughout
- Should look like real API documentation (Stripe's style)
```

#### Prompt 13 — Dev Tools Usage Chart
**File:** `assets/illustrations/devtools_usage.png`
**Target:** New `_img_card("devtools_usage.png", 55)` in the dev tools builder
**Display size:** ~260×55 (full width, 55px tall)
```
Create an API usage chart image (520x110 pixels, displayed at ~260x55) for a developer tools dashboard.

Show a small area chart of "API Requests / Hour" over 24 hours:
- A blue (#3B82F6) filled area chart trending upward with slight variance (not smooth — real traffic patterns)
- X-axis: time labels "12am  6am  12pm  6pm  Now" in muted gray
- A dashed horizontal line at ~70% height labeled "Rate Limit" in amber (#F59E0B)
- Top-right corner: "4,521 req/hr" in white, "p99: 42ms" in green (#22C55E) below it
- Very dark background (#0A0E1A)
- Subtle grid lines
- Professional monitoring dashboard style (like Datadog or Grafana)
```

---

## SECTION 5: FOUNDER ARCHETYPE PORTRAITS (6 images)

Shown on the new game setup screen. These should be **pixel art** — matching the game's character style.

**Save to:** `assets/illustrations/founders/`
**Dimensions:** 160×160 pixels each, transparent background
**Style:** Pixel art bust portraits (head + shoulders), chunky visible pixels

#### Prompt 14 — Engineer Founder
**File:** `founder_engineer.png`
```
Create a pixel art character portrait (160x160, transparent background) of a tech startup founder — the "Engineer" archetype.

- Head and shoulders bust, facing slightly left
- Dark blue or charcoal hoodie, maybe a laptop sticker visible
- Glasses optional (~50% chance)
- Slightly messy hair — late-night coder energy
- Subtle glow from a monitor behind them (green #22C55E code on dark screen)
- Confident but focused expression
- Medium skin tone (keep inclusive/generic)
- Chunky pixel art style — visible individual pixels, NOT smooth/anti-aliased
- Color palette: navy (#1E293B), blue (#2563EB), white (#F8FAFC), green (#22C55E)
- Transparent background
```

#### Prompt 15 — Finance Founder
**File:** `founder_finance.png`
```
Create a pixel art character portrait (160x160, transparent background) of a startup founder — the "Finance" archetype.

- Head and shoulders bust
- Button-down shirt or vest — professional but not stuffy
- Clean, well-groomed appearance
- Subtle chart/spreadsheet glow behind them (green and red numbers)
- Analytical, sharp expression — sees the numbers
- Medium-dark skin tone (keep inclusive/generic)
- Chunky pixel art style, visible pixels
- Color palette: navy, green (#22C55E), gold (#F59E0B), white
- Transparent background
```

#### Prompt 16 — Recruiter Founder
**File:** `founder_recruiter.png`
```
Create a pixel art character portrait (160x160, transparent background) of a startup founder — the "Recruiter" archetype.

- Head and shoulders bust
- Smart casual — blazer over t-shirt or nice sweater
- Warm, open, approachable expression
- Subtle org chart or people icons in background
- Light-medium skin tone (keep inclusive/generic)
- Chunky pixel art style, visible pixels
- Color palette: navy, purple (#7C3AED), blue (#2563EB), white
- Transparent background
```

#### Prompt 17 — Hustler Founder
**File:** `founder_hustler.png`
```
Create a pixel art character portrait (160x160, transparent background) of a startup founder — the "Hustler" archetype.

- Head and shoulders bust, confident lean forward
- Modern casual — leather jacket or trendy shirt
- Phone visible in hand or nearby
- Social media or pitch deck elements in background
- Bold, charismatic expression
- Medium skin tone (keep inclusive/generic)
- Chunky pixel art style, visible pixels
- Color palette: navy, gold (#F59E0B), blue (#3B82F6), red (#EF4444)
- Transparent background
```

#### Prompt 18 — Custom Founder
**File:** `founder_custom.png`
```
Create a pixel art character portrait (160x160, transparent background) of a startup founder — the "Custom" archetype (player assigns their own stats).

- Head and shoulders bust, gender-neutral
- Plain well-fitting t-shirt or crew neck — versatile, not strongly typed
- Subtle floating stat icons or question marks in background
- Curious, open expression — could become anything
- Medium skin tone (keep inclusive/generic)
- Chunky pixel art style, visible pixels
- Color palette: navy, muted blue (#64748B), white, subtle multicolor accents
- Transparent background
```

#### Prompt 19 — God Mode Founder
**File:** `founder_godmode.png`
```
Create a pixel art character portrait (160x160, transparent background) of a startup founder — the "God Mode" archetype (unlocked after first win, all stats maxed).

- Head and shoulders bust
- Same general style as other founders but with PREMIUM FLAIR
- Golden pixel crown or halo above head
- Golden/glowing aura outline
- Sharp outfit — dark suit or premium hoodie with gold accents
- Confident, knowing smile — they've done this before
- Upward arrows or "MAX" indicator in gold behind them
- Medium skin tone (keep inclusive/generic)
- Chunky pixel art style, visible pixels
- Color palette: navy, GOLD (#F59E0B) dominant, white, blue
- Transparent background
```

---

## SECTION 6: UI ICONS (16 icons)

Replace emoji and text characters with proper pixel art icons.

**Save to:** `assets/icons/`
**Dimensions:** 24×24 pixels each (16×16 for star only), transparent background
**Style:** Pixel art, 2-3 colors max, white primary stroke

#### Prompt 20 — Full Icon Set
```
Create a set of 16 pixel art icons for a dark-themed mobile game UI. Each icon should be a separate 24x24 pixel PNG with transparent background. Style: chunky pixel art with visible individual pixels — NOT smooth vector icons.

Primary stroke color: white (#F8FAFC). Each icon has one accent color as noted.

1. bell.png — Notification bell with small red (#EF4444) dot badge
2. share.png — Share arrow pointing up-right, blue (#3B82F6) accent
3. download.png — Download arrow into tray, green (#22C55E) accent
4. chat.png — Speech bubble with dots, blue (#2563EB) accent
5. star.png — (16x16 ONLY) Filled five-pointed star, gold (#F59E0B)
6. lock.png — Closed padlock, gold (#F59E0B) accent
7. crown.png — Simple 3-point crown, gold (#F59E0B)
8. briefcase.png — Briefcase, blue (#2563EB) accent
9. code.png — Code brackets </>, green (#22C55E) accent
10. cart.png — Shopping cart, blue (#3B82F6) accent
11. chart_up.png — Trending up arrow/line, green (#22C55E)
12. chart_down.png — Trending down arrow/line, red (#EF4444)
13. person_add.png — Person silhouette with +, green (#22C55E)
14. person_remove.png — Person silhouette with -, red (#EF4444)
15. money.png — Dollar sign in circle, green (#22C55E)
16. trophy.png — Trophy cup, gold (#F59E0B)

All icons should be clearly readable at 24x24 and match a "cozy Bloomberg terminal" game aesthetic.
```

---

## SECTION 7: EMPLOYEE SPECIALTY PORTRAITS (18 images)

**Save to:** `assets/avatars/specialties/`
**Dimensions:** 120×120 pixels each, transparent background
**Style:** Pixel art bust portraits

#### Prompt 21 through 29 — Use this template for each specialty:

```
Create TWO pixel art character portraits (120x120 each, transparent background) of a [SPECIALTY] employee in a tech startup.

Generate two visually distinct variants (different hair, skin tone, accessories) that both clearly read as "[SPECIALTY]."

Both should be head + shoulders busts, chunky pixel art with visible pixels, and use the color palette: navy (#1E293B), [ACCENT_COLOR], white (#F8FAFC).
```

**Fill in per specialty:**

| Prompt # | Specialty | Accent Color | Visual Cues |
|----------|-----------|-------------|-------------|
| 21 | Frontend | Blue #3B82F6 | Bright hoodie, laptop with colorful UI / Headphones, graphic tee |
| 22 | Backend | Teal #0D9488 | Dark shirt, terminal glow / Glasses, coffee, server silhouette |
| 23 | Mobile | Purple #7C3AED | Holding phone / Earbuds in, phone on desk |
| 24 | Design | Pink #EC4899 | Colorful accessories, creative / Tablet+stylus, artistic hair |
| 25 | Data/ML | Emerald #059669 | Glasses, neural net doodle / Whiteboard with graphs |
| 26 | DevOps | Orange #F97316 | Headset, monitoring screens / Beanie, tired-alert, coffee |
| 27 | Sales | Gold #F59E0B | Button-down, polished / Blazer, name badge, phone |
| 28 | Marketing | Magenta #D946EF | Megaphone icon behind / Trendy outfit, social media icons |
| 29 | Operations | Slate #64748B | Clipboard behind, organized / Headset, process diagram |

---

## SECTION 8: STORE MARKETING ASSETS

See `docs/art-asset-brief.md` for complete prompts (8 assets). Do these LAST — after all in-game art.

---

## GENERATION ORDER

| Priority | What | Count | Why |
|----------|------|-------|-----|
| **1** | Consumer component upgrades (Prompts 1-5) | 13 images | Drop-in — zero code changes, instant upgrade |
| **2** | Founder portraits (Prompts 14-19) | 6 images | First thing players see |
| **3** | SaaS components (Prompts 6-8) | 3 images | Biggest visual gap — currently all rectangles |
| **4** | Marketplace components (Prompts 9-10) | 4 images | Product cards are the visual payoff |
| **5** | Dev Tools components (Prompts 11-13) | 3 images | Terminal aesthetic needs real code snippets |
| **6** | UI Icons (Prompt 20) | 16 icons | Quick win, replaces all emoji |
| **7** | Employee portraits (Prompts 21-29) | 18 images | Polish for detail view |
| **8** | Store assets (art-asset-brief.md) | 8+ images | Needed for submission only |

**Total: ~71 assets**

---

## CODE CHANGES NEEDED (I'll handle these — not for Cursor)

After Cursor generates the images:

**Zero code changes (drop-in):**
- All 13 Consumer images (Prompts 1-5) — slots already wired
- Founder portraits — just need `TextureRect` added to setup screen

**Small code changes (~10-20 lines each):**
- SaaS: convert 3 procedural sections to `_img_card()` calls
- Marketplace: convert product `_card()` calls to `_img_card()` calls + tracking bar
- Dev Tools: add 3 new `_img_card()` calls for CLI, docs, usage chart
- Icons: replace emoji `Label` nodes with `TextureRect` loading from `assets/icons/`

**None of these are architectural changes.** They're find-and-replace level edits within the existing system.
