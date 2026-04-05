# Venture — QA Smoke Checklist

Comprehensive test checklist covering every game system, UI screen, engine, and mobile-specific concern. Every test maps to the exact source file and function so you know where to look when something breaks.

---

## How to use

1. Launch the game in the Godot editor (F5 or Play Scene).
2. Walk through each section in order — they follow normal gameplay flow.
3. Mark each item pass/fail. If something breaks, the **Source** column points to the file.
4. After fixes, re-run only the failed section.
5. Full checklist: ~30-40 minutes. Quick regression (marked with ★): ~15 minutes.

---

## 1. Main Menu & Save Slots

| # | Test | Expected | Source |
|---|------|----------|--------|
| 1.1 | App launches to main menu | Title screen with Play, Settings, Quit | `src/ui/main_menu/main_menu.tscn` → `main_menu.gd` |
| 1.2 | "Play" opens save slot screen | 5 slots shown (empty or with save summaries) | `src/ui/saves/save_slots.gd` |
| 1.3 | Empty slot → "New Game" flow | Opens new game setup | `save_slots.gd` → new game navigation |
| 1.4 | Occupied slot shows correct summary | Company name, type, cash, year, quarter, employee count | `src/autoload/game_state.gd` → `peek_save()` |
| 1.5 | Load an existing save | Dashboard loads with correct state restored | `game_state.gd` → `load_game()` |
| 1.6 | Delete a save slot | Slot becomes empty; files cleaned up | `game_state.gd` → `delete_save()` |
| 1.7 | Back button returns to main menu | Clean navigation, no orphaned nodes | `save_slots.gd`, `src/autoload/scene_loader.gd` |
| 1.8 | Settings accessible from main menu | Settings screen opens and returns cleanly | `main_menu.gd` |
| 1.9 | Continue Last Run button resumes latest save | Loads newest valid save slot directly into dashboard; falls back to save slots if unavailable | `main_menu.gd` → `_on_continue()`, `game_state.gd` → `latest_save_slot()` |
| 1.10 | Main-menu buttons respond after cold launch | Play/Settings/Quit all register taps immediately (no script parse/autoload fallout) | `project.godot` autoloads, `ui_touch_helper_bridge.gd`, `world_event_engine_bridge.gd`, `main_menu.gd` |
| 1.11 | Save slots list scroll works on small phones | Top title/back stay fixed and lower slot cards remain reachable via the slot-list scroll area | `save_slots.tscn`, `save_slots.gd`, `ui_touch_helper.gd` |

---

## 2. New Game Setup

| # | Test | Expected | Source |
|---|------|----------|--------|
| 2.1 | ★ Start new game (Consumer App, Normal) | Dashboard loads with correct defaults | `src/ui/setup/new_game.gd`, `game_state.gd` → `new_game()` |
| 2.2 | All 4 company types selectable | SaaS, Consumer, Marketplace, Dev Tools each show description and difficulty | `new_game.gd` |
| 2.3 | "Recommended" badge on Consumer App | Badge visible for new players | `new_game.gd` |
| 2.4 | All 3 difficulty modes work | Sandbox/Normal/Hardcore each set correct multipliers | `game_state.gd` → `DIFFICULTY_MULTS` |
| 2.5 | Founder background selection | All 6 archetypes (Engineer, Finance, Recruiter, Business, Custom, God Mode) set stats | `new_game.gd`, `src/models/company_data.gd` → `founder_stat()` |
| 2.6 | Custom founder: point distribution works | 20 points across 4 stats, each 1-10, no overflow | `new_game.gd` |
| 2.7 | Company name persists through game | Name shows on dashboard and save slot | `game_state.gd` → `_serialize()` |
| 2.8 | Feature catalog loads for selected type | `features.json` parsed, 10 features available per type | `src/models/product_data.gd`, `src/data/features.json` |
| 2.9 | Events catalog loads | `events.json` parsed without errors | `src/engine/event_engine.gd`, `src/data/events.json` |
| 2.10 | Competitors load for selected type | Rival companies initialized from `competitors.json` | `src/engine/competitor_ai.gd`, `src/data/competitors.json` |
| 2.11 | Mid/large scenario presets start correctly | `Growth Operator` and `Scale Chief` start with seeded teams, users, and funding context (no crashes, values within expected ranges) | `new_game.gd`, `game_state.gd` → `_apply_starting_scenario()`, `_seed_starting_company_state()` |
| 2.12 | Niche selector updates per company type | Switching type repopulates niches; recommended niche shows star; modifiers shown below | `new_game.gd` → `_populate_niche_selector()`, `_on_niche_changed()` |
| 2.13 | Selected niche persists into gameplay | Niche modifiers affect growth/churn/revenue in first quarter | `game_state.gd` → `new_game()`, `company_data.gd` → `apply_niche()` |

---

## 3. Tutorial

| # | Test | Expected | Source |
|---|------|----------|--------|
| 3.1 | ★ Tutorial overlay on first launch | 5-step card at bottom, dimmed backdrop | `src/autoload/tutorial_manager.gd` → `start_if_needed()` |
| 3.2 | Tap through all 5 steps | Each slides up, step counter updates | `tutorial_manager.gd` → `_refresh_card()` |
| 3.3 | Step 3 auto-advances when People opens | Tutorial reacts to `scene_changed` signal | `tutorial_manager.gd` → `_on_scene_changed()` |
| 3.4 | Step 4 auto-advances after first quarter advance | Reacts to `quarter_advanced` signal | `tutorial_manager.gd` → `_on_quarter_advanced()` |
| 3.5 | "Skip Tutorial" at any step | Overlay fades, step saved as 99 | `tutorial_manager.gd` → `skip()` |
| 3.6 | Tutorial does not reappear on reload | `user://tutorial.dat` persists | `tutorial_manager.gd` → `_load_step()` |
| 3.7 | Settings → "Replay Tutorial" resets | Next new game shows tutorial again | `src/ui/settings/settings_screen.gd` → `_on_replay_tutorial()` |

---

## 4. Dashboard (Main Hub)

| # | Test | Expected | Source |
|---|------|----------|--------|
| 4.1 | ★ Dashboard displays all core stats | Cash, Revenue, Burn Rate, Runway visible | `src/ui/dashboard/quarter_dashboard.gd` → `_refresh()` |
| 4.2 | Quarter deltas show green/red changes | `+$X / -$X vs last Q` next to each stat | `quarter_dashboard.gd` → `_build_delta_labels()` |
| 4.3 | Founder energy bar visible | Energy 0-100, correct color | `quarter_dashboard.gd` |
| 4.4 | Board patience indicator (if funded) | Shows patience level when VC-funded | `quarter_dashboard.gd` |
| 4.5 | Nav tabs at top: People, Product, Finances, Market | Tabs navigate to correct screens | `quarter_dashboard.gd` |
| 4.6 | Office banner matches office level | Garage/Co-working/Small Office/HQ image | `quarter_dashboard.gd` → `_refresh_office_banner()` |
| 4.7 | Headline ticker rotates | Different headline every ~4 seconds | `quarter_dashboard.gd` → `_rotate_headline()` |
| 4.8 | "Advance Quarter" button works | Triggers simulation, events fire, stats update | `quarter_dashboard.gd` → `_on_advance()` |
| 4.9 | "Last quarter" momentum strip updates | Cash/Revenue/Users/Valuation deltas and tone update after each advance | `quarter_dashboard.gd` → `_refresh_turn_summary()` |
| 4.10 | Dashboard "Next best action" hint is context-aware | Messaging changes for no hires, no feature assignment, no target feature, tight runway | `quarter_dashboard.gd` → `_refresh_next_action_hint()` |
| 4.11 | Event heading count + resolve hint stay in sync | "This Quarter · N events" and pending-event hint update as events are resolved | `quarter_dashboard.gd` → `_refresh_events_heading()`, `_on_event_resolved()` |
| 4.12 | Advance button label shows explicit next period | Button text reads `Advance to Yx Qy` and switches to resolve-state text when blocked | `quarter_dashboard.gd` → `_update_advance_button_label()` |
| 4.13 | Quarter-entry toast appears after advance | Toast shows new quarter and immediate cash/users deltas, then fades out | `quarter_dashboard.gd` → `_show_advance_toast()` |
| 4.14 | Hosting status strip updates on dashboard | Shows plan + reliability + peak load and color state updates with infra pressure | `quarter_dashboard.gd` → `_refresh_hosting_status()` |
| 4.15 | Office worker desk sprites render and animate | Desk-aware pseudo-sprite workers (head/body badges) appear on office banner with subtle motion and per-office layout changes | `quarter_dashboard.gd` → `_refresh_office_worker_ambient()` |
| 4.16 | Dashboard finance labels use hybrid CFO + plain wording | Titles read `Cash (On Hand)`, `Revenue (Qtr)`, `Burn Rate (Qtr)`, `Runway (Time Left)` and glossary opens correct definitions | `quarter_dashboard.gd` → `_apply_plain_finance_titles()` |
| 4.17 | Dashboard plain-English finance explainer updates | One-line explainer describes positive or negative cashflow based on current quarter state | `quarter_dashboard.gd` → `_refresh_finance_plain_hint()` |
| 4.18 | Dashboard hosting strip shows workload profile | Hosting status includes workload profile text and pressure warning when run becomes scale/data-center heavy | `quarter_dashboard.gd` → `_refresh_hosting_status()` |
| 4.19 | Quarter transition FX + SFX triggers on advance | Advancing quarter plays sweep/tint/period-label transition and emits start/resolve SFX (asset-based or synth fallback) without blocking simulation flow | `quarter_dashboard.gd` → `_play_quarter_transition_placeholder()`, `_play_transition_sfx()` |
| 4.20 | Key metric info icon explains DAU/MAU and peers | Key metric title shows `ⓘ`; click opens glossary and hover shows tooltip for current metric (MRR, DAU/MAU, GMV, API Calls, Valuation) | `quarter_dashboard.gd` → `_refresh_key_metric()`, `_on_key_metric_info_pressed()` |
| 4.21 | Dashboard economy strip shows active world pulse | When a world event is active, `Market:` line appends `World: <event> (NQ left)` and color tone reflects tailwind/headwind | `quarter_dashboard.gd` → `_refresh_economy()`, `game_state.gd` → `active_world_event_brief()` |

---

## 5. Quarter Advance & Simulation

| # | Test | Expected | Source |
|---|------|----------|--------|
| 5.1 | ★ Advancing a quarter updates year/quarter | Q1→Q2→Q3→Q4→next year Q1 | `game_state.gd` → `advance_quarter()` |
| 5.2 | Feature progress increases per assigned employees | More employees = faster, ETA decreases | `src/engine/simulation_engine.gd` → `_apply_work_output()` |
| 5.3 | Locked interviewers produce zero output | Busy employees skipped in work loop | `simulation_engine.gd` → interviewer check in `_apply_work_output()` |
| 5.4 | Revenue calculated correctly per type | SaaS/Consumer/Marketplace/DevTools each have unique curves | `src/engine/revenue_engine.gd` |
| 5.5 | Burn rate reflects salaries + infrastructure | All costs summed | `simulation_engine.gd` → cost calculations |
| 5.6 | User growth calculated with feature pull | Features → user acquisition | `simulation_engine.gd` → `_calculate_user_growth()` |
| 5.7 | Churn calculated with bugs/stability | High bugs = more churn | `simulation_engine.gd` → churn block |
| 5.8 | Late-game growth headwinds above 25K users | Growth rate decreases, floor at 55% | `simulation_engine.gd` → maturity block |
| 5.9 | UX < 60 at 50K+ users adds extra churn | Extra 0.3% churn | `simulation_engine.gd` → churn block |
| 5.10 | Valuation updates each quarter | Reflects financials + growth + economy | `src/engine/valuation_engine.gd` |
| 5.11 | Competitors simulate each quarter | Rival metrics change | `src/engine/competitor_ai.gd` |
| 5.12 | Employee morale/stress/turnover processed | Stressed employees may quit | `simulation_engine.gd` → morale/turnover logic |
| 5.13 | Tech debt accumulates from rushing | Affects stability and bug rate | `simulation_engine.gd` |
| 5.14 | Auto-save fires after advance | Save file updated in `user://saves/` | `game_state.gd` → `auto_save()` |
| 5.15 | Quarterly report generates 6+ bullets | Summary includes revenue/cash/team/product/users/economy/hosting (plus situational energy/board lines) | `src/engine/quarterly_report.gd` |
| 5.16 | Hosting incidents apply reliability pressure | Overload lowers reliability and can increase bugs/churn/reduce stability | `simulation_engine.gd` → `_simulate_hosting()` |
| 5.17 | Hosting event logs appear when stressed | Quarter log can show hosting incident/overage entries under load | `simulation_engine.gd` → `_calculate_costs()` |
| 5.18 | Hosting upgrades affect lane capacity and cost | Purchasing lane upgrades/optimization increases effective capacity and raises recurring hosting cost | `simulation_engine.gd` → `_simulate_hosting()`, `logistics_overview.gd` |
| 5.19 | Workload-aware hosting demand reacts to product direction | AI/streaming/marketplace/API/realtime feature mixes change lane demand multipliers and can escalate data-center pressure tier | `simulation_engine.gd` → `_hosting_workload_profile()`, `_simulate_hosting()` |
| 5.20 | Responsibility impact scales with company maturity | Early teams can still ship with shared hats, but growth/scale runs without Bugs/Debt/Infra/R&D coverage accumulate visible operational pressure (bugs, debt, stability/UX drag, churn) | `simulation_engine.gd` → `_responsibility_profile()`, `_apply_operational_pressure()` |
| 5.21 | Role-mesh bonuses reward balanced coverage | Balanced lane staffing improves delivery quality/retention/ops pressure versus same-headcount single-lane teams | `simulation_engine.gd` → `_responsibility_mesh()`, `_apply_work_output()` |
| 5.22 | World pulse modifiers affect core simulation | Active world event changes growth/churn/revenue/cost/fundraising behavior for multiple quarters, then expires cleanly | `world_event_engine.gd`, `simulation_engine.gd`, `fundraising_engine.gd`, `game_state.gd` |

---

## 6. Events System

| # | Test | Expected | Source |
|---|------|----------|--------|
| 6.1 | ★ Events fire during quarter advance | At least 1 event appears in first few quarters | `src/engine/event_engine.gd` → `select_events()` |
| 6.2 | Event popup displays with title + description | Modal overlay with choices | `src/ui/components/event_popup.tscn` → `event_popup.gd` |
| 6.3 | Choosing an option applies consequences | Cash/morale/reputation change as described | `event_popup.gd`, `game_state.gd` |
| 6.4 | One-time events don't repeat | `fired_one_time_events` prevents re-firing | `game_state.gd` → `fired_one_time_events`, `event_engine.gd` |
| 6.5 | Events respect eligibility filters | Company type, quarter, valuation gates work | `event_engine.gd` → eligibility logic |
| 6.6 | Event frequency scales with company maturity | Event count ramps from early to growth/late runs (with valuation/team signals) without overwhelming opening quarters | `event_engine.gd` |
| 6.7 | Events are logged in event_log | Event history accessible | `game_state.gd` → `append_event_log()` |
| 6.8 | Niche-aware event weighting feels relevant | Selected niche surfaces more fitting event categories over multiple runs | `event_engine.gd` → `_effective_event_weight()` |
| 6.9 | Event cadence and repeats adapt by stage + difficulty | Early + Sandbox runs feel calmer (lower cadence / longer repeats), while late + Hardcore runs feel denser (higher cadence / shorter repeats) without becoming spammy | `event_engine.gd` → `_event_count_bounds()`, `_effective_cooldown()`, `_effective_event_weight()` |
| 6.10 | Multi-event quarters avoid same-category spam | When 2-4 events fire, picks usually span categories (not repeatedly `market`/`money` in the same quarter unless pool is constrained) | `event_engine.gd` → `_within_roll_category_dampener()`, `_weighted_pick()` |
| 6.11 | Event choice effects are fully wired (no silent no-op keys) | Salary raise, equity grant, forced attrition, and fundraising-opportunity effects all apply tangible gameplay state changes | `event_popup.gd` → `_apply_effects()`, `tools/backend_smoke.py` → `EVENT_EFFECT_KEYS` |
| 6.12 | World events roll and persist across quarters | Multi-quarter macro pulses activate, modify simulation multipliers, and expire with log entries | `world_event_engine.gd` → `resolve_quarter()`, `game_state.gd` → world event state |

---

## 7. Headlines

| # | Test | Expected | Source |
|---|------|----------|--------|
| 7.1 | Headlines generate without template errors | No `{variable}` placeholders visible in rendered text | `src/engine/headline_engine.gd`, `src/engine/template_engine.gd` |
| 7.2 | Economy-appropriate headlines selected | Bull market = optimistic, Bear = pessimistic | `headline_engine.gd`, `src/data/headlines.json` |
| 7.3 | Headlines reference company context | Company name, user count, etc. substituted correctly | `template_engine.gd` |
| 7.4 | Niche-aware weighted headlines appear | Niche-tagged/keyword-relevant headlines show up more often for current niche | `headline_engine.gd` → `_template_weight()` |

---

## 8. Hiring & Deep Interviews

| # | Test | Expected | Source |
|---|------|----------|--------|
| 8.1 | ★ Post job listing ($5K deducted) | 3 candidates with avatar + specialty badge | `src/ui/people/employee_list.gd` → `_on_hire_pressed()` |
| 8.2 | Candidates have correct stat ranges for seniority | Junior = lower, Principal = higher | `src/engine/hiring_engine.gd` → `_stat_for_seniority()` |
| 8.3 | Tap "Interview Team…" on candidate | Interviewer picker: Founder + all employees | `employee_list.gd` → `_show_interviewer_picker()` |
| 8.4 | Pick Founder: cash -$1.5K, energy -4 | Interview report on card | `employee_list.gd` → `_complete_interview()` |
| 8.5 | Pick Senior employee (Manager tier) | Cash -$2K, employee shows "Interviewing (1Q left)" | `employee_list.gd`, `game_state.gd` → `lock_interviewer()` |
| 8.6 | Report shows estimated stats (with error margin) | Skill/Speed/Morale may differ from true values | `employee_list.gd` → `_fuzzy_stat()` |
| 8.7 | Culture fit "???" for low people-skill interviewer | Culture estimate -1 when people-skill < 70 | `employee_list.gd` → `CULTURE_READ_THRESHOLD` |
| 8.8 | Culture fit shown for high people-skill interviewer | Clamped fuzzy value | Same as 8.7 |
| 8.9 | Interview feedback is natural-sounding | Verdict + role bias + culture note | `employee_list.gd` → `_feedback_text()` |
| 8.10 | "Quick Peek (Ad)" gives low-confidence report | Wide error, culture always "???", "directional" note | `employee_list.gd` → `_quick_peek_report()` |
| 8.11 | Cannot interview same candidate twice | Guard: `_interview_reports.has(ckey)` | `employee_list.gd` |
| 8.12 | Busy interviewer disabled in picker | "unavailable (XQ left)", greyed out | `employee_list.gd` → `_add_interviewer_option()` |
| 8.13 | Cannot interview if cash too low | "not enough cash", greyed out | Same |
| 8.14 | Negotiate salary: one-shot, may walk | Salary -15% or candidate exits | `employee_list.gd` → `_on_negotiate_salary()` |
| 8.15 | Hire → badge → assign flow end-to-end | Badge pops in, stats shown, assignment prompt | `employee_list.gd` → `_show_hire_badge()`, `_show_assign_prompt()` |
| 8.16 | Firing clears interviewer lock | No stale `interviewer_busy_quarters` entry | `game_state.gd` → `fire_employee()` |

---

## 9. Employee Management

| # | Test | Expected | Source |
|---|------|----------|--------|
| 9.1 | ★ Employee list displays all hired employees | Name, title, assignment, specialty | `employee_list.gd` → `_refresh_list()` |
| 9.2 | Reassign employee to different task | Assignment updates, reflected next quarter | `employee_list.gd` → assignment logic |
| 9.3 | Specialty-fit badge shows on assignment | Green badge when specialty matches task | `employee_list.gd` → specialty badge |
| 9.4 | Fire an employee | Employee removed, salary stops, list updates | `employee_list.gd` → `_on_fire()`, `game_state.gd` → `fire_employee()` |
| 9.5 | Sort employees (by name, skill, etc.) | List reorders correctly | `employee_list.gd` → sort logic |
| 9.6 | Employee avatars deterministic | Same employee always gets same avatar | `employee_list.gd` → `hash()` avatar selection |
| 9.7 | "Interviewing" busy badge on locked employee | Shows quarters remaining | `employee_list.gd` → busy badge |
| 9.8 | Office capacity enforced | Cannot hire beyond office_capacity | `game_state.gd` → `hire_employee()` |
| 9.9 | Employee unique IDs (UIDs) are stable | UID persists across save/load | `src/models/employee_data.gd` → `ensure_uid()` |
| 9.10 | No duplicate UIDs in employee list | Dedup on hire and deserialize | `game_state.gd` → `_has_employee_uid()` |
| 9.11 | Employment type + personality visible | Team/candidate cards show type + trait labels | `employee_list.gd`, `employee_data.gd` |
| 9.12 | Employee detail screen opens and renders history | `Details` button opens profile with trajectory chart + history rows | `employee_list.gd` → `_on_view_details()`, `employee_detail.gd` |
| 9.13 | People screen responsibility hint adapts by stage | Early shows shared-hat guidance; growth/scale warns when specialization lanes have no owner | `employee_list.gd` → `_refresh_allocation_hint()`, `_assignment_description_for_stage()` |
| 9.14 | People list pane scroll works with candidate panel open | Header/hints stay anchored and employee rows remain reachable via the list scroll area | `employee_list.tscn`, `employee_list.gd`, `ui_touch_helper.gd` |

---

## 10. Product & Features

| # | Test | Expected | Source |
|---|------|----------|--------|
| 10.1 | ★ Product screen shows current product state | Features, tech debt, bugs, stability, UX, users | `src/ui/product/product_overview.gd` |
| 10.2 | Feature picker shows available features | Prerequisites respected, costs shown | `product_overview.gd` → feature picker |
| 10.3 | Select a feature to build | Feature enters "in progress" state | `product_overview.gd` |
| 10.4 | Progress bar updates each quarter | Reflects assigned employee output | `product_overview.gd` → progress display |
| 10.5 | Feature completes: celebration banner | Green/yellow/red based on quality | `quarter_dashboard.gd` → `_on_feature_shipped_dashboard()` |
| 10.6 | Milestone roadmap visible | Progress toward user/feature/revenue goals | `product_overview.gd` |
| 10.7 | Tech debt and bugs affect product | High debt = more bugs = more churn | `simulation_engine.gd` |
| 10.8 | Product visual updates as features ship | Consumer: feed, stories, recs reveal progressively | `src/ui/product/product_visual.gd` → `refresh()` |
| 10.9 | Shimmer on in-progress features | White strip loops across ghosted card | `product_visual.gd` → `_start_shimmer()` |
| 10.10 | Shimmer stops when feature ships | Ken Burns or reveal animation replaces shimmer | `product_visual.gd` → `_stop_shimmer()` |
| 10.11 | All 4 company types have 10 features each | `features.json` has entries per type | `src/data/features.json` |
| 10.12 | ETA text includes throughput hint | Build status displays estimated effort-per-quarter with current team assignment | `product_overview.gd` → `_refresh_build_status()`, `_build_eta_text()` |
| 10.13 | Product feature-picker and shipped-features panes scroll reliably | Opening `Choose Next Feature` keeps picker cards scrollable, and the shipped-features list remains scrollable without collapsing the rest of the layout | `product_overview.tscn`, `product_overview.gd`, `ui_touch_helper.gd` |
| 10.14 | Prototype concept switcher cycles correctly | Prototype selector dropdown updates visual preview and hint text; showcase mode auto-cycles presets | `product_overview.gd` → `_on_prototype_selected()`, `_start_showcase_mode()` |

---

## 11. Finances & Fundraising

| # | Test | Expected | Source |
|---|------|----------|--------|
| 11.1 | ★ Finance screen shows correct numbers | Cash, revenue, burn, runway, equity, valuation | `src/ui/finance/finance_overview.gd` |
| 11.2 | Runway calculates correctly | Cash / burn_rate = quarters left | `finance_overview.gd`, `game_state.gd` |
| 11.3 | Fundraising offer appears at appropriate time | VC offers based on metrics + stage | `src/engine/fundraising_engine.gd` |
| 11.4 | Accept VC offer: cash increases, equity dilutes | Equity % decreases, cash increases by round size | `fundraising_engine.gd`, `finance_overview.gd` |
| 11.5 | Decline VC offer: no changes | State unaffected | Same |
| 11.6 | Board patience tracks after funding | Displayed on finance screen | `game_state.gd` → `board_patience` |
| 11.7 | Board patience decreases on missed targets | Eventually triggers takeover | `game_state.gd` → `_check_end_conditions()` |
| 11.8 | Angel bailout available at $0 cash | One-time rescue, steep equity cost | `game_state.gd` → `angel_bailout_used` |
| 11.9 | Cost breakdown is transparent | Salaries + infra traceable | `simulation_engine.gd`, `financials_data.gd` |
| 11.10 | Finance trend chart renders and updates | Cash/Revenue/Users lines draw from history (last 12 quarters) | `src/ui/finance/finance_overview.gd` → `_refresh_trend_chart()`, `src/ui/components/trend_chart.gd` |
| 11.11 | Finance health chart renders and updates | Valuation/Team/Morale lines draw from history/live state | `finance_overview.gd` → `_refresh_health_trend_chart()`, `game_state.gd` → `_take_snapshot()` |
| 11.12 | Finance quarter-delta strip reflects latest quarter | Cash/Revenue/Users delta text updates after each advance and colors by direction | `finance_overview.gd` → `_refresh_quarter_delta_hint()` |
| 11.13 | Finance "Next best move" hint reflects runway pressure | Recommendation changes at critical/tight runway and high-burn scenarios | `finance_overview.gd` → `_refresh_next_move_hint()` |
| 11.14 | Hosting plan selector persists and affects costs | Switching Managed Cloud/Hybrid/In-house updates company plan, autosaves, and changes future hosting costs/reliability | `finance_overview.gd` → `_on_hosting_plan_selected()`, `game_state.gd` serialize/deserialize |
| 11.15 | Hosting cost line item is visible in costs grid | `Hosting` value updates each quarter from simulation outputs | `finance_overview.gd` → `_build_hosting_controls()`, `_refresh()` |
| 11.16 | Finance → Logistics navigation works | `Open Logistics` button opens logistics overview and back returns to Finances | `finance_overview.gd` → `_on_open_logistics()`, `logistics_overview.gd` |
| 11.17 | Finance labels use hybrid CFO + plain wording | `Cash (On Hand)`, `Revenue (Qtr)`, `Burn Rate (Qtr)`, `Runway (Time Left)` visible in overview grid | `finance_overview.gd` → `_apply_plain_finance_titles()` |
| 11.18 | Finance driver drill-down explains cash movement | `Driver read` line summarizes revenue/cost drivers and incidents from last quarter snapshot | `finance_overview.gd` → `_refresh_drilldown_hint()`, `game_state.gd` → `_take_snapshot()` |
| 11.19 | Finance hosting meta includes workload profile | Hosting meta text shows profile + pressure tier and updates recommendation when data-center pressure is high | `finance_overview.gd` → `_refresh_hosting_controls()`, `_refresh_next_move_hint()` |

---

## 11B. Logistics (Hosting Ops)

| # | Test | Expected | Source |
|---|------|----------|--------|
| 11B.1 | Logistics screen renders all hosting state | Reliability, lane bars, cost labels, and objectives are visible | `src/ui/logistics/logistics_overview.gd/.tscn` |
| 11B.2 | Hosting lane bars match current demand/capacity | Web/Cache/Data utilization reflects latest quarter simulation outputs | `logistics_overview.gd` → `_set_lane()`, `simulation_engine.gd` → `_simulate_hosting()` |
| 11B.3 | Plan switching from Logistics persists | Changing plan updates `company.hosting_plan` and autosaves current slot | `logistics_overview.gd` → `_on_plan_selected()`, `game_state.gd` |
| 11B.4 | Objective lines progress correctly | Reliability streak, overage threshold, and infra staffing objective update with state | `logistics_overview.gd` → `_objective_lines()` |
| 11B.5 | Capacity action buttons buy upgrades correctly | Web/Cache/Data/Optimization upgrades deduct cash, increase levels, append event log, and autosave | `logistics_overview.gd` → `_on_upgrade_pressed()`, `game_state.gd` |
| 11B.6 | Upgrade affordability + max-level gating works | Buttons disable when cash is insufficient or level cap is reached; labels show next cost/level | `logistics_overview.gd` → `_refresh_upgrade_row()` |
| 11B.7 | Logistics guidance adapts to workload pressure | Plan hint/objectives add data-lane scaling guidance when workload profile enters scale-intensive or data-center-heavy tiers | `logistics_overview.gd` → `_refresh()`, `_objective_lines()` |

---

## 12. Market & Competitors

| # | Test | Expected | Source |
|---|------|----------|--------|
| 12.1 | Market screen shows competitor leaderboard | Player rank among rivals | `src/ui/market/market_leaderboard.gd` |
| 12.2 | Competitors grow each quarter | Rival users/revenue change | `src/engine/competitor_ai.gd` |
| 12.3 | Economy state transitions | Bull → Neutral → Bear based on events | `src/models/market_data.gd`, `simulation_engine.gd` |
| 12.4 | Economy affects user growth and fundraising | Bull = easier growth, Bear = harder | `simulation_engine.gd` → economy multipliers |
| 12.5 | Economy indicator visible on dashboard | Shows current state | `quarter_dashboard.gd` |
| 12.6 | Starting competitors are niche-biased | Initial rival pool includes same-focus and niche-relevant competitors when available | `competitor_ai.gd` → `generate_starting_competitors()` |
| 12.7 | World events roll + persist as macro conditions | Multi-quarter market pulses activate with weighted filters and log start/end entries | `world_event_engine.gd`, `game_state.gd` → `event_log` |
| 12.8 | Market leaderboard list scroll works on short screens | Back/title stay anchored and lower-ranked cards remain reachable via leaderboard list scrolling | `market_leaderboard.tscn`, `market_leaderboard.gd`, `ui_touch_helper.gd` |

---

## 13. Glossary

| # | Test | Expected | Source |
|---|------|----------|--------|
| 13.1 | Info icon buttons open glossary popup | Tap ℹ next to any stat | `src/autoload/glossary.gd` → `show_term()` |
| 13.2 | Glossary popup shows correct definition | Term title + plain-English description | `src/ui/components/glossary_popup.gd`, `src/data/glossary.json` |
| 13.3 | Popup dismisses cleanly | Tap outside or close button | `glossary_popup.gd` |
| 13.4 | All stat terms have glossary entries | No missing keys when clicking any ℹ button | `glossary.json` |
| 13.5 | Info icons show hover tooltip text | Hovering metric ℹ buttons shows concise term + explanation tooltip, while click still opens popup | `quarter_dashboard.gd`, `finance_overview.gd` |

---

## 14. Win Conditions

| # | Test | Expected | Source |
|---|------|----------|--------|
| 14.1 | ★ IPO triggers at $100M ARR + 100K users | Victory screen shows "IPO" | `game_state.gd` → `_check_end_conditions()` |
| 14.2 | Unicorn triggers at $1B valuation | Victory screen shows "Unicorn" | Same |
| 14.3 | Sustainable: 6Q profit + Q20 + scale checks | 12K users, 8 features, $250K/Q revenue | `game_state.gd` → `_meets_sustainable_victory()` |
| 14.4 | Sustainable does NOT trigger before Q20 | Even with 6+ profit streak | `game_state.gd` → `SUSTAINABLE_MIN_QUARTERS` |
| 14.5 | Acquisition (accept buyout event) | Victory screen | `event_engine.gd` + `game_state.gd` |
| 14.6 | Same win type cannot trigger twice | `_achieved_wins` prevents duplicates | `game_state.gd` → `_emit_victory()` |
| 14.7 | Victory screen displays correct stats | Revenue, users, team size, company summary | `src/ui/victory/victory_screen.gd` |
| 14.8 | "Keep Building" continues the game | Returns to dashboard, `is_game_active = true` | `victory_screen.gd` → `_on_continue()`, `game_state.gd` → `continue_after_victory()` |
| 14.9 | Post-victory: can achieve different win types | e.g., sustainable → continue → IPO | `game_state.gd` → `has_achieved_win()` |
| 14.10 | "New Game" from victory works | Clean new game setup | `victory_screen.gd` → `_on_new_game()` |
| 14.11 | "Menu" from victory works | Returns to main menu | `victory_screen.gd` → `_on_menu()` |

---

## 15. Loss Conditions & Game Over

| # | Test | Expected | Source |
|---|------|----------|--------|
| 15.1 | ★ Bankruptcy: cash ≤ 0 and revenue < burn | Game over screen, "Bankruptcy" reason | `game_state.gd` → `_check_end_conditions()` |
| 15.2 | Founder burnout: energy reaches 0 | Game over, "Burnout" reason | Same |
| 15.3 | Dead product: 0 users after Q12 | Game over, "Dead Product" reason | Same |
| 15.4 | Board takeover: patience reaches 0 | Game over, "Board Takeover" reason | Same |
| 15.5 | Game over screen displays correctly | Reason, stats summary, options | `src/ui/game_over/game_over_screen.gd` |
| 15.6 | Angel bailout option (first time only) | Cash injection at steep equity cost | `game_over_screen.gd`, `game_state.gd` → `angel_bailout_used` |
| 15.7 | "Menu" and "New Game" buttons work | Navigate correctly | `game_over_screen.gd` |
| 15.8 | Game over layout remains stable on small phones | Reason/stats/angel offer/actions render in expected order with no top-left collapse or overlapping controls | `game_over_screen.tscn`, `game_over_screen.gd` |

---

## 16. Free Tier & Paywall

| # | Test | Expected | Source |
|---|------|----------|--------|
| 16.1 | Free tier: play 8 quarters normally | No paywall during Years 1-2 | `src/autoload/ad_manager.gd` → `FREE_QUARTER_LIMIT`, `is_game_locked()` |
| 16.2 | Free tier: blocked after Q8 on mobile | Paywall overlay appears | `src/ui/dashboard/quarter_dashboard.gd` → `_on_advance()` |
| 16.3 | Desktop/dev: paywall never triggers | `is_game_locked()` returns false on PC/Mac | `ad_manager.gd` → `is_game_locked()` |
| 16.4 | Paywall "Unlock" on desktop: instant unlock | Premium set, paywall dismissed | `ad_manager.gd` → `_do_purchase()` |
| 16.5 | Settings: "Unlock Full Game" button (free) | Blue CTA below version label | `src/ui/settings/settings_screen.gd` → `_build_premium_section()` |
| 16.6 | After unlock: "✓ Full Game — Unlocked" | Green checkmark replaces button | `settings_screen.gd` → `_refresh_premium_row()` |
| 16.7 | Ad interstitial cooldown respected | Minimum 3 quarters between interstitials | `ad_manager.gd` → `INTERSTITIAL_COOLDOWN_QUARTERS` |
| 16.8 | Rewarded ad for stat reveal works | Triggers quick-peek interview report | `ad_manager.gd`, `employee_list.gd` → `_on_ad_reveal()` |
| 16.9 | Restore purchases path works | Restore button attempts recovery and unlocks if entitlement exists | `ad_manager.gd` → `restore_purchases()`, `settings_screen.gd` |
| 16.10 | Free save-slot gating enforced on mobile | Slots above free limit show locked premium cards | `save_slots.gd` → `_is_slot_unlocked()`, `ad_manager.gd` → `max_save_slots()` |
| 16.11 | Stability-first monetization gate stays active on gameplay branch | `MONETIZATION_TEMP_DISABLED` remains true; gameplay flow does not block on paywall during stabilization | `ad_manager.gd`, `tools/backend_smoke.py` → `validate_monetization_gate()` |

---

## 17. Save / Load Integrity

| # | Test | Expected | Source |
|---|------|----------|--------|
| 17.1 | ★ Auto-save fires after every quarter | Save file updated in `user://saves/` | `game_state.gd` → `auto_save()` |
| 17.2 | Save file has checksum wrapper | JSON: `_schema`, `_saved_at_unix`, `_checksum`, `data` keys | `game_state.gd` → `_atomic_write()` |
| 17.3 | `.bak` backup exists after 2+ saves | Previous save preserved | `game_state.gd` → `_atomic_write()` backup |
| 17.4 | Corrupt primary: loads from backup | Rename/break `.json`; load still works | `game_state.gd` → `load_game()` fallback |
| 17.5 | Corrupt both: clean error, no crash | Error signal emitted | `game_state.gd` → `load_game()` |
| 17.6 | Save includes employee UIDs | `employees[].uid` non-empty in JSON | `game_state.gd` → `_serialize()` |
| 17.7 | Save includes `achieved_wins` + `interviewer_busy_quarters` | Both keys present | Same |
| 17.8 | Load → clamp pass sanitizes values | Edit JSON with out-of-range; load clamps | `game_state.gd` → clamp block in `_deserialize()` |
| 17.9 | Delete save cleans all files | Primary + tmp + bak removed | `game_state.gd` → `delete_save()` |
| 17.10 | Settings use atomic write + backup | `settings.json` and `settings.json.bak` exist | `src/autoload/analytics.gd` → `_atomic_write_settings()` |
| 17.11 | Async save doesn't skip latest state | Rapid advance → quit → reload: last Q is there | `game_state.gd` → `save_game_async()` with `wait_to_finish()` |
| 17.12 | Save size stays under 4MB limit | `MAX_SAVE_BYTES` enforced | `game_state.gd` → `MAX_SAVE_BYTES` |
| 17.13 | Load after version mismatch: clean error | Version != 1 → error, no crash | `game_state.gd` → `_deserialize()` version check |
| 17.14 | Save round-trip: all state preserved | Save → quit → load → every field matches | Full `_serialize()` / `_deserialize()` |
| 17.15 | Quit from main menu preserves latest run | Return to menu from dashboard, press Quit, relaunch, load same slot successfully | `main_menu.gd` → `_on_quit()`, `game_state.gd` → `autosave_now()` |
| 17.16 | Save payload remains compact over long sessions | After 60+ quarters, serialized save keeps only compact windows for `history` and `event_log` (no unbounded growth) | `game_state.gd` → `_compact_history_for_save()`, `_compact_event_log_for_save()` |

---

## 18. Product Visuals & Animations

| # | Test | Expected | Source |
|---|------|----------|--------|
| 18.1 | Consumer App: product visual loads | Brand badge icon in header | `src/ui/product/product_visual.gd` → `_build_consumer()` |
| 18.2 | Ship `social_feed`: cards fade in + Ken Burns | Stagger-reveal, images slowly zoom 1.0→1.06 | `product_visual.gd` → `_start_ken_burns()` |
| 18.3 | Ship `stories`: bubbles cascade + pulse | Phase-offset scale breathing on each bubble | `product_visual.gd` → story block |
| 18.4 | In-progress feature: shimmer sweep | White strip loops across ghosted card | `product_visual.gd` → `_start_shimmer()` |
| 18.5 | Shimmer stops on ship | Killed, reveal plays | `product_visual.gd` → `_stop_shimmer()` |
| 18.6 | Visual preset switcher (Starter → Full) | Product rebuilds with crossfade | `product_overview.gd` → `_set_visual_preset_mode()` |
| 18.7 | Showcase mode auto-cycles | Presets rotate every 2.8s | `product_overview.gd` → `_start_showcase_mode()` |
| 18.8 | Missing image: solid color fallback | Delete a PNG; card still renders | `product_visual.gd` → `_img_card()` fallback |
| 18.9 | All 4 company types have product visuals | Each type builds its own layout | `product_visual.gd` → `setup()` |
| 18.10 | Animations clean up on scene exit | No orphaned tweens after leaving Product | `product_visual.gd` → `_exit_tree()` / tween cleanup |

---

## 19. Scene Navigation & Memory

| # | Test | Expected | Source |
|---|------|----------|--------|
| 19.1 | ★ Every screen is reachable from dashboard | People, Product, Finances, Market all load | `src/autoload/scene_loader.gd` → `goto_scene()` |
| 19.2 | Back button works on every sub-screen | Returns to dashboard cleanly | Each screen's `back_btn.pressed` |
| 19.3 | Rapid screen switching: no crash | Tap People → Back → Product → Back quickly | `scene_loader.gd` → `free_children()` |
| 19.4 | No orphaned nodes after 20+ transitions | Monitor node count in Godot debugger | `scene_loader.gd` |
| 19.5 | Overlays clean up on dismiss | Tutorial, paywall, event, interview picker all free | Each overlay's dismiss/close logic |
| 19.6 | Multiple overlays don't stack incorrectly | Only one event popup at a time, etc. | `event_popup.gd`, `employee_list.gd` |

---

## 20. Founder Systems

| # | Test | Expected | Source |
|---|------|----------|--------|
| 20.1 | Founder energy drains from stress events | Energy decreases, shown on dashboard | `game_state.gd` → `founder_energy` |
| 20.2 | Founder energy recovers from positive events | Win milestone → energy boost | Events in `events.json` |
| 20.3 | Burnout at energy 0 = game over | Immediate loss | `game_state.gd` → `_check_end_conditions()` |
| 20.4 | Founder interview costs energy (-4) | Energy decreases, no crash at low energy | `employee_list.gd` → `_complete_interview()` |
| 20.5 | CEO stats affect gameplay | Engineer CEO contributes to product, Finance CEO gets better VC terms | `company_data.gd` → `founder_stat()`, various engines |

---

## 21. Settings & Analytics

| # | Test | Expected | Source |
|---|------|----------|--------|
| 21.1 | Settings screen opens from menu and dashboard | All elements render | `src/ui/settings/settings_screen.gd` |
| 21.2 | Analytics toggle persists | Flip on/off, restart, still set | `analytics.gd` → `_save_settings()` |
| 21.3 | Premium status persists across sessions | `is_premium` stored in settings | `analytics.gd` → `set_premium()` |
| 21.4 | Version label shows correct version | Matches `project.godot` | `settings_screen.gd` |
| 21.5 | Privacy policy link works | Opens URL or shows text | `settings_screen.gd` |
| 21.6 | Settings screen scroll reaches both top and bottom on small phones | Back/analytics controls and lower premium/tutorial controls are both reachable via touch scroll with no clipped dead zones | `settings_screen.tscn`, `settings_screen.gd`, `ui_touch_helper.gd` |
| 21.7 | Age confirmation gate works for analytics | Confirming age enables analytics toggle; denying hides analytics row | `settings_screen.gd` → `_on_age_confirmed()`, `_on_age_denied()` |

---

## 22. Edge Cases & Stress

| # | Test | Expected | Source |
|---|------|----------|--------|
| 22.1 | ★ Year 1 Q1: no employees, advance quarter | Game survives with $0 revenue, no crash | `simulation_engine.gd` → empty employee guard |
| 22.2 | Advance 40+ quarters in one session | No memory bloat, history capped at 200 | `game_state.gd` → `MAX_HISTORY_SIZE` |
| 22.3 | Event log capped at 500 entries | Old entries trimmed | `game_state.gd` → `MAX_EVENT_LOG_SIZE` |
| 22.4 | Hire up to office capacity, then blocked | Clear error message, button disabled | `game_state.gd` → `hire_employee()` |
| 22.5 | Max employees: 500 cap | Enforced on deserialize | `game_state.gd` → `MAX_EMPLOYEES` |
| 22.6 | Rapid "Advance Quarter" tapping | Button disables during processing, no double-advance | `quarter_dashboard.gd` → `advance_btn.disabled` |
| 22.7 | $0 cash with no revenue: bankruptcy triggers | Not stuck, game over fires | `game_state.gd` → `_check_end_conditions()` |
| 22.8 | Empty company name | Defaults to "Unknown" on load | `game_state.gd` → `peek_save()` fallback |
| 22.9 | All employees fired mid-game | Game continues, just slow (no output) | `simulation_engine.gd` |
| 22.10 | Feature with no employees assigned | No progress, no crash, ETA shows N/A | `simulation_engine.gd`, `product_overview.gd` |

---

## 23. Mobile-Specific (iOS & Android)

These tests require deploying to a device or emulator, not just the editor.

| # | Test | Expected | Source |
|---|------|----------|--------|
| 23.1 | Portrait orientation locked | No landscape rotation | `project.godot` → `handheld/orientation=1` |
| 23.2 | Touch targets ≥ 44×44 pt | All buttons/tabs large enough for thumb tapping | All `.tscn` files → `custom_minimum_size` |
| 23.3 | Android back button behavior | Returns to previous screen or shows exit prompt (not just crash) | `scene_loader.gd`, each screen's `_unhandled_input()` |
| 23.4 | App backgrounding → foregrounding | State preserved, no crash, game resumes | Godot lifecycle: `NOTIFICATION_APPLICATION_FOCUS_OUT/IN` |
| 23.5 | App killed while playing → relaunch | Auto-save restores last quarter | `game_state.gd` → `auto_save()` |
| 23.6 | Low memory warning | Game doesn't crash; consider freeing cached scenes | Godot: `NOTIFICATION_WM_CLOSE_REQUEST` |
| 23.7 | Screen size: iPhone SE (small) | UI fits without overlap; scroll containers work | All `.tscn` → anchors, `SIZE_EXPAND_FILL` |
| 23.8 | Screen size: iPad / large tablet | No empty space or tiny elements; expands gracefully | `project.godot` → stretch mode `canvas_items`, aspect `expand` |
| 23.9 | Notch / safe area (iPhone 14+) | UI doesn't render under the notch or home indicator | Top/bottom margins in root containers |
| 23.10 | Performance: 60fps on mid-range device | No frame drops during animations or quarter advance | Profile with Godot debugger |
| 23.11 | Performance: no memory leak over 30 minutes | Node count stable, no unbounded growth | Godot debugger → Monitors |
| 23.12 | Offline play: fully functional | No network dependency for core gameplay | All game logic is local |
| 23.13 | Text readability at 1x display scale | Font sizes legible on physical device | All `font_size` overrides |
| 23.14 | ScrollContainer touch scrolling smooth | People list, finance screen, etc. scroll naturally | All `ScrollContainer` nodes |
| 23.15 | No accidental taps through overlays | Modal overlays block input below them | `mouse_filter = MOUSE_FILTER_STOP` on overlay backgrounds |
| 23.16 | Runtime-generated buttons still meet touch minimums | Dynamic controls (candidate cards, event choices, feature picker, save-slot cards) are >= 44-48px and maintain spacing | `ui_touch_helper.gd`, `scene_loader.gd`, dynamic UI builders in `employee_list.gd`, `event_popup.gd`, `product_overview.gd`, `save_slots.gd` |

---

## 24. Data Integrity & JSON

| # | Test | Expected | Source |
|---|------|----------|--------|
| 24.1 | `features.json` loads for all 4 types | No parse errors, 10 features per type | `src/data/features.json`, `product_data.gd` |
| 24.2 | `events.json` loads without errors | All events have required fields | `src/data/events.json`, `event_engine.gd` |
| 24.3 | `headlines.json` templates resolve | No unsubstituted `{vars}` in output | `src/data/headlines.json`, `template_engine.gd` |
| 24.4 | `glossary.json` has all referenced terms | Every `show_term()` call has a matching key | `src/data/glossary.json`, `glossary.gd` |
| 24.5 | `vcs.json` loads for fundraising | VC firms initialized correctly | `src/data/vcs.json`, `fundraising_engine.gd` |
| 24.6 | `competitors.json` loads for all types | Rivals initialized per company type | `src/data/competitors.json`, `competitor_ai.gd` |
| 24.7 | `niches.json` loads for all company types | New game niche picker and modifiers are valid | `src/data/niches.json`, `company_data.gd`, `tools/backend_smoke.py` |
| 24.8 | `names.json` exists (future use) | Name pools available | `src/data/names.json` |
| 24.9 | UI button wiring contracts pass | Critical button handlers and scene button nodes exist for main flows | `tools/backend_smoke.py` → `validate_button_script_contracts()`, `validate_button_scene_contracts()` |
| 24.10 | `product_preview_prototypes.json` validates | Prototype concept names/descriptions/preview modes are valid for each company type | `src/data/product_preview_prototypes.json`, `product_overview.gd`, `tools/backend_smoke.py` |
| 24.11 | `world_events.json` validates | World event IDs/effects/durations/filter fields pass backend smoke schema checks | `src/data/world_events.json`, `world_event_engine.gd`, `tools/backend_smoke.py` |
| 24.12 | Glossary has no near-duplicate keys | No keys differing only by case (e.g., `mrr` vs `MRR`) | `tools/backend_smoke.py` → `validate_glossary_no_near_duplicates()` |
| 24.13 | Every niche has tagged competitors | All niche IDs in `niches.json` have at least one competitor in `competitors.json` | `tools/backend_smoke.py` → `validate_niche_competitor_coverage()` |
| 24.14 | Headlines have no broken dollar amounts | No templates with missing numbers like `"a M company"` | `tools/backend_smoke.py` → `validate_headline_content_quality()` |
| 24.15 | `GAME_VERSION` constant exists and is referenced | Version constant in `game_state.gd`, used by settings and analytics | `tools/backend_smoke.py` → `validate_version_constant()` |
| 24.16 | Event cooldown reset wired | `EventEngine.reset_cooldowns()` exists and is called in `new_game()` | `tools/backend_smoke.py` → `validate_event_cooldown_reset()` |
| 24.17 | History snapshots include feature count | `_take_snapshot()` records `"features"` for board patience tracking | `tools/backend_smoke.py` → `validate_history_snapshot_features()` |
| 24.18 | Scene transitions use SceneLoader only | No raw `change_scene_to_file()` in game screens | `tools/backend_smoke.py` → `validate_scene_loader_usage()` |

---

## Quick regression protocol

After any code change:

0. **Execution order** — Follow `docs/current-execution-path.md` for current quality-first sequencing (stability -> balance -> phone gates -> beta)
0.5 **Edge-case slots (recommended)** — Re-run impacted slot(s) from `docs/dev-edge-case-test-matrix.md` to catch regression spillover quickly
1. **Backend smoke script** — run `python3 tools/backend_smoke.py` (fast structural/data checks + UI button wiring contracts)
2. **Lint check** — `ReadLints` on all modified `.gd` files
3. **★ items** — Marked with ★ above: new game, dashboard, advance quarter, events, hiring, employee list, product, finances, navigation, edge cases (~15 min)
4. **Section 17** — Save/load round-trip if persistence code changed
5. **Relevant section** — If you changed a specific system, run its full section
6. **Section 23** — On-device pass before any release build

Full checklist: ~35 minutes in-editor, plus ~15 minutes on-device for Section 23.

---

## Pre-release checklist (before App Store / Play Store submission)

| # | Gate | Details |
|---|------|---------|
| R.1 | All ★ items pass | Core loop end-to-end |
| R.2 | Section 23 passes on both iOS + Android device | Real hardware, not just emulator |
| R.3 | Export presets configured | `export_presets.cfg` checked in with signing, bundle ID, permissions |
| R.4 | App icon set in project.godot | `config/icon` pointing to `app_icon.png` |
| R.5 | IAP wired for target platform | StoreKit (iOS) / Google Play Billing (Android) callbacks work |
| R.6 | Ad SDK integrated (if shipping with ads) | AdMob or equivalent returns true for `_detect_ad_sdk()` |
| R.7 | Privacy policy URL accessible | Settings link works, policy hosted |
| R.8 | Analytics consent flow compliant | GDPR/CCPA toggle before any tracking |
| R.9 | No placeholder/debug text in UI | "TODO", "test", lorem ipsum removed |
| R.10 | Performance profiled on lowest-target device | iPhone SE 2 / budget Android |
| R.11 | Save migration strategy decided | What happens when v2 save format ships |
| R.12 | Crash reporting integrated | Firebase Crashlytics or equivalent |

---

*Last updated: March 2026. Covers all 6 autoloads, 13 UI screens, 11 engines, 6 data models, 9 JSON files, 7 code-quality validators, mobile QA, and pre-release gates.*
