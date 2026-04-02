extends Control
## Main gameplay screen.

@onready var quarter_label: Label = %QuarterLabel
@onready var company_label: Label = %CompanyLabel
@onready var office_banner: TextureRect = %OfficeBanner
@onready var stats_grid: GridContainer = $MarginContainer/VBox/StatsGrid
@onready var cash_label: Label = %CashLabel
@onready var users_label: Label = %UsersLabel
@onready var runway_label: Label = %RunwayLabel
@onready var employees_label: Label = %EmployeesLabel
@onready var revenue_label: Label = %RevenueLabel
@onready var burn_label: Label = %BurnLabel
@onready var cash_title_btn: Button = %CashTitle
@onready var revenue_title_btn: Button = %RevenueTitle
@onready var burn_title_btn: Button = %BurnTitle
@onready var runway_title_btn: Button = %RunwayTitle
@onready var advance_btn: Button = %AdvanceButton
@onready var people_btn: Button = %PeopleButton
@onready var product_btn: Button = %ProductButton
@onready var finance_btn: Button = %FinanceButton
@onready var market_btn: Button = %MarketButton
@onready var menu_btn: Button = %MenuButton
@onready var event_log_container: VBoxContainer = %EventLogContainer
@onready var team_container: VBoxContainer = %TeamContainer
@onready var event_popup: EventPopup = %EventPopup
@onready var report_panel: PanelContainer = %ReportPanel
@onready var report_body: Label = %ReportBody
@onready var events_label: Label = $MarginContainer/VBox/EventsLabel
@onready var headline_label: Label = %HeadlineLabel
@onready var economy_label: Label = %EconomyLabel
@onready var energy_label: Label = %EnergyLabel
@onready var key_metric_title: Label = %KeyMetricTitle
@onready var key_metric_label: Label = %KeyMetricLabel
@onready var ticker_strip: Label = %TickerStrip
@onready var quarter_transition_tint: ColorRect = %QuarterTransitionTint

const MAX_VISIBLE_EVENTS := 10
const HEADLINE_ROTATE_SECONDS := 4.0

const OFFICE_BANNER_PATHS := [
	"res://assets/office/office_0_garage.png",
	"res://assets/office/office_1_coworking.png",
	"res://assets/office/office_2_small.png",
	"res://assets/office/office_3_hq.png",
]
const OFFICE_WORKSPACE_STYLES := {
	0: {"rows": 1, "per_row": 3, "base_y_ratio": 0.70, "row_gap": 14.0, "desk_w": 16.0, "desk_h": 4.0},
	1: {"rows": 1, "per_row": 5, "base_y_ratio": 0.66, "row_gap": 14.0, "desk_w": 17.0, "desk_h": 4.0},
	2: {"rows": 2, "per_row": 5, "base_y_ratio": 0.60, "row_gap": 15.0, "desk_w": 18.0, "desk_h": 4.0},
	3: {"rows": 2, "per_row": 6, "base_y_ratio": 0.56, "row_gap": 14.0, "desk_w": 18.0, "desk_h": 4.0},
}

var _pending_events: Array[EventData] = []
var _headlines: Array[String] = []
var _headline_index: int = 0
var _headline_timer: Timer
var _prev_valuation: float = 0.0

# Dynamically created delta labels next to each stat
var _cash_delta_label: Label
var _revenue_delta_label: Label
var _burn_delta_label: Label
# Feature-shipped celebration shown briefly on the dashboard
var _feature_banner: Label
var _turn_summary_panel: PanelContainer
var _turn_summary_label: Label
var _next_action_label: Label
var _advance_hint_label: Label
var _advance_toast_panel: PanelContainer
var _advance_toast_label: Label
var _hosting_status_label: Label
var _office_worker_layer: Control
var _finance_plain_label: Label


func _ready() -> void:
	advance_btn.pressed.connect(_on_advance)
	people_btn.pressed.connect(_on_people)
	product_btn.pressed.connect(_on_product)
	finance_btn.pressed.connect(_on_finance)
	market_btn.pressed.connect(_on_market)
	menu_btn.pressed.connect(_on_menu)
	event_popup.event_resolved.connect(_on_event_resolved)

	_apply_plain_finance_titles()
	_wire_glossary_button(cash_title_btn, "cash_on_hand")
	_wire_glossary_button(revenue_title_btn, "quarterly_revenue")
	_wire_glossary_button(burn_title_btn, "quarterly_burn")
	_wire_glossary_button(runway_title_btn, "runway")

	GameState.quarter_advanced.connect(_refresh)
	GameState.game_over.connect(_on_game_over)
	GameState.game_won.connect(_on_game_won)
	GameState.event_triggered.connect(_on_event)
	GameState.save_error.connect(_on_save_error)
	GameState.feature_shipped.connect(_on_feature_shipped_dashboard)

	_headline_timer = Timer.new()
	_headline_timer.wait_time = HEADLINE_ROTATE_SECONDS
	_headline_timer.timeout.connect(_rotate_headline)
	add_child(_headline_timer)

	_build_delta_labels()
	_build_feature_banner()
	_build_turn_summary_panel()
	_build_next_action_label()
	_build_advance_hint_label()
	_build_advance_toast()
	_build_hosting_status_label()
	_build_office_worker_layer()
	_build_finance_plain_label()
	_move_nav_to_top()

	_refresh(GameState.current_quarter)
	Analytics.track_screen("dashboard")

	# Start tutorial on first run (deferred so all nodes are fully laid out).
	TutorialManager.start_if_needed.call_deferred()


func _wire_glossary_button(btn: Button, glossary_key: String) -> void:
	if btn == null:
		return
	btn.pressed.connect(Glossary.show_term.bind(glossary_key))
	_set_glossary_tooltip(btn, glossary_key)


func _set_glossary_tooltip(btn: Control, glossary_key: String) -> void:
	if not Glossary.has_term(glossary_key):
		btn.tooltip_text = "Click for metric details."
		return
	var term: String = Glossary.get_term(glossary_key)
	var short_desc: String = Glossary.get_short(glossary_key)
	var tip: String = Glossary.get_tip(glossary_key)

	var first_line: String = term
	if first_line.is_empty():
		first_line = short_desc
	elif not short_desc.is_empty():
		first_line = "%s — %s" % [term, short_desc]

	var parts: Array[String] = []
	if not first_line.is_empty():
		parts.append(first_line)
	if not tip.is_empty():
		parts.append(tip)
	if parts.is_empty():
		return
	btn.tooltip_text = "\n".join(parts)


func _apply_plain_finance_titles() -> void:
	if cash_title_btn:
		cash_title_btn.text = "Cash (On Hand) ⓘ"
	if revenue_title_btn:
		revenue_title_btn.text = "Revenue (Qtr) ⓘ"
	if burn_title_btn:
		burn_title_btn.text = "Burn Rate (Qtr) ⓘ"
	if runway_title_btn:
		runway_title_btn.text = "Runway (Time Left) ⓘ"


func _exit_tree() -> void:
	_headline_timer.stop()
	_safe_disconnect(GameState.quarter_advanced, _refresh)
	_safe_disconnect(GameState.game_over, _on_game_over)
	_safe_disconnect(GameState.game_won, _on_game_won)
	_safe_disconnect(GameState.event_triggered, _on_event)
	_safe_disconnect(GameState.save_error, _on_save_error)
	_safe_disconnect(GameState.feature_shipped, _on_feature_shipped_dashboard)
	if office_banner and office_banner.resized.is_connected(_refresh_office_worker_ambient):
		office_banner.resized.disconnect(_refresh_office_worker_ambient)


func _build_finance_plain_label() -> void:
	_finance_plain_label = Label.new()
	_finance_plain_label.add_theme_font_size_override("font_size", 11)
	_finance_plain_label.add_theme_color_override("font_color", Color(0.66, 0.74, 0.9))
	_finance_plain_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var vbox := quarter_label.get_parent().get_parent()
	if vbox == null:
		return
	vbox.add_child(_finance_plain_label)
	if stats_grid:
		vbox.move_child(_finance_plain_label, stats_grid.get_index() + 1)


func _build_delta_labels() -> void:
	# Insert small delta labels (e.g. "+$12K") below the main stat labels.
	# Each is parented to the same VBoxContainer as its stat value label.
	_cash_delta_label = _make_delta_label()
	_revenue_delta_label = _make_delta_label()
	_burn_delta_label = _make_delta_label()
	_insert_delta_after(cash_label, _cash_delta_label)
	_insert_delta_after(revenue_label, _revenue_delta_label)
	_insert_delta_after(burn_label, _burn_delta_label)


func _make_delta_label() -> Label:
	var lbl := Label.new()
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.visible = false
	return lbl


func _insert_delta_after(stat_label: Label, delta_label: Label) -> void:
	var parent := stat_label.get_parent()
	if parent == null:
		return
	parent.add_child(delta_label)
	parent.move_child(delta_label, stat_label.get_index() + 1)


func _move_nav_to_top() -> void:
	# Move the navigation row (People / Product / Finances / Market) to sit
	# right after the header row, so it works like a proper top tab bar.
	var vbox := people_btn.get_parent().get_parent()  # NavRow -> VBox
	var nav_row: Node = people_btn.get_parent()       # NavRow itself
	if vbox == null or nav_row == null:
		return

	# Insert right after TopRow (index 0) — i.e. at index 1
	vbox.move_child(nav_row, 1)

	# Also style the nav buttons to look more like tabs
	for btn: Button in [people_btn, product_btn, finance_btn, market_btn]:
		btn.custom_minimum_size = Vector2(0, 40)
		btn.add_theme_font_size_override("font_size", 13)


func _play_quarter_transition_placeholder() -> void:
	# Visual hook layer for future bespoke quarter transition art.
	if quarter_transition_tint == null:
		return
	quarter_transition_tint.visible = true
	quarter_transition_tint.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(quarter_transition_tint, "modulate:a", 0.26, 0.10)
	tw.tween_property(quarter_transition_tint, "modulate:a", 0.0, 0.22)
	tw.finished.connect(func() -> void:
		if quarter_transition_tint:
			quarter_transition_tint.visible = false
	)


func _build_feature_banner() -> void:
	# A slim banner near the top of the event log area that shows when a
	# feature ships (for players who are on the dashboard when it happens).
	_feature_banner = Label.new()
	_feature_banner.add_theme_font_size_override("font_size", 13)
	_feature_banner.add_theme_color_override("font_color", Color(0.4, 0.95, 0.55))
	_feature_banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_feature_banner.visible = false
	var parent := event_log_container.get_parent()
	if parent:
		parent.add_child(_feature_banner)
		parent.move_child(_feature_banner, event_log_container.get_index())


func _build_turn_summary_panel() -> void:
	var vbox := quarter_label.get_parent().get_parent()
	if vbox == null:
		return

	_turn_summary_panel = PanelContainer.new()
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.12, 0.14, 0.2, 0.9)
	panel_style.set_corner_radius_all(8)
	panel_style.content_margin_left = 12
	panel_style.content_margin_right = 12
	panel_style.content_margin_top = 8
	panel_style.content_margin_bottom = 8
	_turn_summary_panel.add_theme_stylebox_override("panel", panel_style)

	_turn_summary_label = Label.new()
	_turn_summary_label.add_theme_font_size_override("font_size", 12)
	_turn_summary_label.add_theme_color_override("font_color", Color(0.72, 0.78, 0.9))
	_turn_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_turn_summary_panel.add_child(_turn_summary_label)
	_turn_summary_panel.visible = false

	vbox.add_child(_turn_summary_panel)
	var status_row := economy_label.get_parent()
	vbox.move_child(_turn_summary_panel, status_row.get_index() + 1)


func _build_next_action_label() -> void:
	_next_action_label = Label.new()
	_next_action_label.add_theme_font_size_override("font_size", 12)
	_next_action_label.add_theme_color_override("font_color", Color(0.66, 0.8, 0.96))
	_next_action_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var parent := advance_btn.get_parent()
	if parent:
		parent.add_child(_next_action_label)
		parent.move_child(_next_action_label, advance_btn.get_index())


func _build_advance_hint_label() -> void:
	_advance_hint_label = Label.new()
	_advance_hint_label.add_theme_font_size_override("font_size", 11)
	_advance_hint_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.35))
	_advance_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_advance_hint_label.visible = false
	var parent := advance_btn.get_parent()
	if parent:
		parent.add_child(_advance_hint_label)
		parent.move_child(_advance_hint_label, advance_btn.get_index() + 1)


func _build_advance_toast() -> void:
	_advance_toast_panel = PanelContainer.new()
	_advance_toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_advance_toast_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_advance_toast_panel.offset_left = 60
	_advance_toast_panel.offset_right = -60
	_advance_toast_panel.offset_top = 8
	_advance_toast_panel.offset_bottom = 52
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.24, 0.38, 0.96)
	panel_style.set_corner_radius_all(10)
	panel_style.content_margin_left = 10
	panel_style.content_margin_right = 10
	panel_style.content_margin_top = 8
	panel_style.content_margin_bottom = 8
	_advance_toast_panel.add_theme_stylebox_override("panel", panel_style)

	_advance_toast_label = Label.new()
	_advance_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_advance_toast_label.add_theme_font_size_override("font_size", 12)
	_advance_toast_label.add_theme_color_override("font_color", Color(0.9, 0.96, 1.0))
	_advance_toast_panel.add_child(_advance_toast_label)

	_advance_toast_panel.visible = false
	_advance_toast_panel.modulate.a = 0.0
	add_child(_advance_toast_panel)
	move_child(_advance_toast_panel, get_child_count() - 1)


func _build_hosting_status_label() -> void:
	_hosting_status_label = Label.new()
	_hosting_status_label.add_theme_font_size_override("font_size", 13)
	var status_row := economy_label.get_parent()
	if status_row:
		status_row.add_child(_hosting_status_label)


func _build_office_worker_layer() -> void:
	if office_banner == null:
		return
	_office_worker_layer = Control.new()
	_office_worker_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_office_worker_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	office_banner.add_child(_office_worker_layer)
	if not office_banner.resized.is_connected(_refresh_office_worker_ambient):
		office_banner.resized.connect(_refresh_office_worker_ambient)


func _refresh(_q: int) -> void:
	if GameState.company == null:
		return
	quarter_label.text = "Year %d, Q%d" % [GameState.current_year, GameState.current_quarter]
	company_label.text = "%s — %s" % [GameState.company.company_name, GameState.company.type_name_with_niche()]
	cash_label.text = "$%s" % SceneLoader.format_money(GameState.company.cash)
	users_label.text = "%s users" % SceneLoader.format_number(GameState.product.users)
	employees_label.text = "%d / %d" % [GameState.employees.size(), GameState.company.office_capacity()]
	revenue_label.text = "$%s/qtr" % SceneLoader.format_money(GameState.financials.revenue)
	burn_label.text = "$%s/qtr" % SceneLoader.format_money(GameState.financials.burn_rate)

	var rw: float = GameState.financials.runway_quarters(GameState.company.cash)
	if rw == INF:
		runway_label.text = "Profitable"
	elif rw < 0:
		runway_label.text = "In debt"
	elif rw < 1.0:
		runway_label.text = "< 1 quarter"
	elif rw < 2.0:
		runway_label.text = "~1 quarter"
	else:
		runway_label.text = "~%d quarters" % roundi(rw)

	_refresh_deltas()
	_refresh_headlines()
	_refresh_ticker_strip()
	_refresh_key_metric()
	_refresh_economy()
	_refresh_energy()
	_refresh_hosting_status()
	_refresh_team()
	_refresh_office_banner()
	_refresh_turn_summary()
	_refresh_next_action_hint()
	_refresh_events_heading()
	_update_advance_button_label()
	_refresh_finance_plain_hint()


func _refresh_deltas() -> void:
	# Use the last two history snapshots for quarter-over-quarter changes.
	var hist := GameState.history
	if hist.size() < 2:
		if _cash_delta_label:
			_cash_delta_label.visible = false
		if _revenue_delta_label:
			_revenue_delta_label.visible = false
		if _burn_delta_label:
			_burn_delta_label.visible = false
		return

	var prev: Dictionary = hist[-2]
	var curr: Dictionary = hist[-1]

	_apply_delta(_cash_delta_label,
		curr.get("cash", 0.0) - prev.get("cash", 0.0), true)
	_apply_delta(_revenue_delta_label,
		curr.get("revenue", 0.0) - prev.get("revenue", 0.0), true)
	_apply_delta(_burn_delta_label,
		curr.get("burn_rate", 0.0) - prev.get("burn_rate", 0.0), false)


func _apply_delta(lbl: Label, delta: float, higher_is_good: bool) -> void:
	if lbl == null:
		return
	if absf(delta) < 1.0:
		lbl.visible = false
		return
	lbl.visible = true
	var sign_str := "+" if delta >= 0 else ""
	lbl.text = "%s$%s vs last Q" % [sign_str, SceneLoader.format_money(delta)]
	var positive: bool = delta > 0
	var good: bool = positive == higher_is_good
	if good:
		lbl.add_theme_color_override("font_color", Color(0.35, 0.85, 0.45))
	else:
		lbl.add_theme_color_override("font_color", Color(0.9, 0.4, 0.35))


func _refresh_turn_summary() -> void:
	if _turn_summary_panel == null or _turn_summary_label == null:
		return
	var hist: Array = GameState.history
	if hist.size() < 2:
		_turn_summary_panel.visible = false
		return

	var prev: Dictionary = _as_dict(hist[hist.size() - 2])
	var curr: Dictionary = _as_dict(hist[hist.size() - 1])
	var cash_delta: float = float(curr.get("cash", 0.0)) - float(prev.get("cash", 0.0))
	var rev_delta: float = float(curr.get("revenue", 0.0)) - float(prev.get("revenue", 0.0))
	var users_delta: int = int(curr.get("users", 0)) - int(prev.get("users", 0))
	var val_delta: float = float(curr.get("valuation", 0.0)) - float(prev.get("valuation", 0.0))

	var score: int = 0
	if cash_delta > 0.0:
		score += 1
	elif cash_delta < 0.0:
		score -= 1
	if rev_delta > 0.0:
		score += 1
	elif rev_delta < 0.0:
		score -= 1
	if users_delta > 0:
		score += 1
	elif users_delta < 0:
		score -= 1
	if val_delta > 0.0:
		score += 1
	elif val_delta < 0.0:
		score -= 1

	var mood: String = "Last quarter: mixed"
	if score >= 3:
		mood = "Last quarter: strong momentum"
	elif score <= -3:
		mood = "Last quarter: rough patch"

	_turn_summary_label.text = "%s  ·  Cash %s  ·  Rev %s  ·  Users %s  ·  Valuation %s" % [
		mood,
		_delta_money_text(cash_delta),
		_delta_money_text(rev_delta),
		_delta_int_text(users_delta),
		_delta_money_text(val_delta),
	]
	if score >= 2:
		_turn_summary_label.add_theme_color_override("font_color", Color(0.55, 0.9, 0.55))
	elif score <= -2:
		_turn_summary_label.add_theme_color_override("font_color", Color(0.95, 0.58, 0.5))
	else:
		_turn_summary_label.add_theme_color_override("font_color", Color(0.72, 0.78, 0.9))
	_turn_summary_panel.visible = true


func _refresh_next_action_hint() -> void:
	if _next_action_label == null or GameState.company == null or GameState.product == null:
		return

	var hint := ""
	if GameState.employees.is_empty():
		hint = "Next best action: hire your first teammate in People."
	elif _features_assigned_count() == 0:
		hint = "Next best action: assign at least 1 teammate to Features in People."
	elif GameState.product.get_target_feature(GameState.company.type).is_empty():
		hint = "Next best action: pick a feature in Product to keep progress moving."
	else:
		var rw: float = GameState.financials.runway_quarters(GameState.company.cash)
		var peak_util: float = maxf(
			GameState.company.hosting_util_web,
			maxf(GameState.company.hosting_util_cache, GameState.company.hosting_util_data)
		)
		var hosting_upgrade_total: int = GameState.company.hosting_upgrade_web_level \
			+ GameState.company.hosting_upgrade_cache_level \
			+ GameState.company.hosting_upgrade_data_level
		if peak_util > 1.05 and hosting_upgrade_total < 2:
			hint = "Next best action: open Logistics and buy a lane capacity upgrade before demand spikes."
		elif GameState.company.hosting_reliability < 94.0:
			hint = "Next best action: hosting is unstable — add Infra staffing or switch to a safer hosting plan."
		elif rw < 1.0:
			hint = "Next best action: runway is critical — open Finances and raise now."
		elif rw < 3.0:
			hint = "Next best action: runway is tight — plan fundraising soon."
		elif GameState.product.feature_count() == 0:
			hint = "Next best action: keep shipping features to unlock user growth."
		else:
			hint = "Next best action: continue shipping and watch churn + runway."

	_next_action_label.text = hint


func _refresh_hosting_status() -> void:
	if _hosting_status_label == null or GameState.company == null:
		return
	var c: CompanyData = GameState.company
	var max_util: float = maxf(c.hosting_util_web, maxf(c.hosting_util_cache, c.hosting_util_data))
	var upgrades_total: int = c.hosting_upgrade_web_level + c.hosting_upgrade_cache_level + c.hosting_upgrade_data_level
	var workload_profile: String = c.hosting_workload_profile.strip_edges()
	if workload_profile.is_empty():
		workload_profile = "General Cloud"
	var pressure: float = c.hosting_data_center_pressure
	_hosting_status_label.text = "Hosting: %s · %.1f%% reliability · peak %.0f%% load · %s" % [
		c.hosting_plan_name(),
		c.hosting_reliability,
		max_util * 100.0,
		workload_profile,
	]
	if pressure >= 2.2:
		_hosting_status_label.text += " · data-center pressure high"
	elif pressure >= 1.25:
		_hosting_status_label.text += " · scaling pressure rising"
	if upgrades_total > 0 or c.hosting_optimization_level > 0:
		_hosting_status_label.text += " · upgrades %d · opt L%d" % [upgrades_total, c.hosting_optimization_level]
	if c.hosting_reliability < 93.0:
		_hosting_status_label.add_theme_color_override("font_color", Color(0.95, 0.50, 0.42))
	elif pressure >= 2.2:
		_hosting_status_label.add_theme_color_override("font_color", Color(0.95, 0.72, 0.42))
	elif c.hosting_reliability < 97.0 or pressure >= 1.25:
		_hosting_status_label.add_theme_color_override("font_color", Color(0.95, 0.80, 0.40))
	else:
		_hosting_status_label.add_theme_color_override("font_color", Color(0.55, 0.88, 0.56))


func _refresh_finance_plain_hint() -> void:
	if _finance_plain_label == null:
		return
	var net_q: float = GameState.financials.revenue - GameState.financials.burn_rate
	if net_q >= 0.0:
		_finance_plain_label.text = "Operator read: cashflow positive by about $%s per quarter (revenue > burn)." % [
			SceneLoader.format_money(net_q)
		]
		_finance_plain_label.add_theme_color_override("font_color", Color(0.56, 0.88, 0.56))
		return

	var shortfall: float = absf(net_q)
	var rw: float = GameState.financials.runway_quarters(GameState.company.cash)
	if rw == INF:
		_finance_plain_label.text = "Operator read: cashflow is currently stable."
	elif rw < 1.0:
		_finance_plain_label.text = "Operator read: cashflow negative by about $%s/qtr and runway is critical." % SceneLoader.format_money(shortfall)
	else:
		_finance_plain_label.text = "Operator read: cashflow negative by about $%s/qtr; runway is around %d quarter%s." % [
			SceneLoader.format_money(shortfall),
			maxi(1, roundi(rw)),
			"s" if roundi(rw) != 1 else "",
		]
	_finance_plain_label.add_theme_color_override("font_color", Color(0.95, 0.74, 0.46))


func _refresh_events_heading() -> void:
	if events_label == null:
		return
	var count: int = event_log_container.get_child_count()
	events_label.text = "This Quarter · %d event%s" % [count, "s" if count != 1 else ""]


func _update_advance_button_label() -> void:
	if advance_btn == null:
		return
	if advance_btn.disabled and _pending_events.size() > 0:
		advance_btn.text = "Resolve Events to Continue"
		return
	var next_year: int = GameState.current_year
	var next_quarter: int = GameState.current_quarter + 1
	if next_quarter > 4:
		next_quarter = 1
		next_year += 1
	advance_btn.text = "Advance to Y%d Q%d →" % [next_year, next_quarter]


func _show_advance_toast() -> void:
	if _advance_toast_panel == null or _advance_toast_label == null:
		return
	var hist: Array = GameState.history
	var cash_delta: float = 0.0
	var users_delta: int = 0
	if hist.size() >= 2:
		var prev: Dictionary = _as_dict(hist[hist.size() - 2])
		var curr: Dictionary = _as_dict(hist[hist.size() - 1])
		cash_delta = float(curr.get("cash", 0.0)) - float(prev.get("cash", 0.0))
		users_delta = int(curr.get("users", 0)) - int(prev.get("users", 0))

	_advance_toast_label.text = "Now in Year %d Q%d  ·  Cash %s  ·  Users %s" % [
		GameState.current_year,
		GameState.current_quarter,
		_delta_money_text(cash_delta),
		_delta_int_text(users_delta),
	]
	_advance_toast_panel.visible = true
	_advance_toast_panel.modulate.a = 0.0
	_advance_toast_panel.scale = Vector2(0.97, 0.97)
	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_advance_toast_panel, "modulate:a", 1.0, 0.16)
	tw.parallel().tween_property(_advance_toast_panel, "scale", Vector2.ONE, 0.2)
	tw.tween_interval(2.1)
	tw.tween_property(_advance_toast_panel, "modulate:a", 0.0, 0.32)
	tw.tween_callback(func() -> void:
		if _advance_toast_panel:
			_advance_toast_panel.visible = false
	)


func _delta_money_text(delta: float) -> String:
	if absf(delta) < 1.0:
		return "$0"
	var sign := "+" if delta > 0.0 else "-"
	return "%s$%s" % [sign, SceneLoader.format_money(absf(delta))]


func _delta_int_text(delta: int) -> String:
	if delta == 0:
		return "0"
	var sign := "+" if delta > 0 else "-"
	return "%s%s" % [sign, SceneLoader.format_number(absi(delta))]


func _set_advance_hint(text: String, color: Color = Color(0.9, 0.7, 0.35)) -> void:
	if _advance_hint_label == null:
		return
	var trimmed := text.strip_edges()
	if trimmed.is_empty():
		_advance_hint_label.visible = false
		return
	_advance_hint_label.visible = true
	_advance_hint_label.text = trimmed
	_advance_hint_label.add_theme_color_override("font_color", color)


func _features_assigned_count() -> int:
	var count := 0
	for emp: EmployeeData in GameState.employees:
		if emp.assignment == EmployeeData.Assignment.FEATURES:
			count += 1
	return count


func _as_dict(v: Variant) -> Dictionary:
	if v is Dictionary:
		return v
	return {}


func _refresh_headlines() -> void:
	_headlines = HeadlineEngine.generate_headlines(GameState, 5)
	_headline_index = 0
	_headline_timer.stop()
	if _headlines.is_empty():
		headline_label.visible = false
		return
	headline_label.visible = true
	headline_label.modulate.a = 1.0
	headline_label.text = _headlines[0]
	if _headlines.size() > 1:
		_headline_timer.start()


func _rotate_headline() -> void:
	if _headlines.is_empty():
		return
	var tw := create_tween()
	tw.tween_property(headline_label, "modulate:a", 0.0, 0.3)
	tw.tween_callback(func():
		_headline_index = (_headline_index + 1) % _headlines.size()
		headline_label.text = _headlines[_headline_index]
	)
	tw.tween_property(headline_label, "modulate:a", 1.0, 0.3)


func _refresh_ticker_strip() -> void:
	if GameState.company == null:
		ticker_strip.visible = false
		return
	var val: float = GameState.company.valuation
	var parts: Array[String] = []
	parts.append("$%s  %s" % [GameState.company.company_name.to_upper().replace(" ", ""), SceneLoader.format_money(val)])
	if _prev_valuation > 0.0 and val != _prev_valuation:
		var pct: float = ((val - _prev_valuation) / _prev_valuation) * 100.0
		if pct > 0:
			parts[0] += "  ▲%.1f%%" % pct
		else:
			parts[0] += "  ▼%.1f%%" % absf(pct)
	_prev_valuation = val

	match GameState.market.economy_state:
		MarketData.EconomyState.BULL:
			parts.append("MKTS ▲")
		MarketData.EconomyState.BEAR:
			parts.append("MKTS ▼")
		_:
			parts.append("MKTS —")

	if GameState.financials.revenue > 0:
		parts.append("REV %s" % SceneLoader.format_money(GameState.financials.revenue))

	ticker_strip.text = "    ".join(parts)
	ticker_strip.visible = true


func _refresh_key_metric() -> void:
	var p: ProductData = GameState.product
	match GameState.company.type:
		CompanyData.CompanyType.SAAS:
			key_metric_title.text = "MRR"
			var mrr: float = GameState.financials.revenue / 3.0
			key_metric_label.text = "$%s" % SceneLoader.format_money(mrr)
		CompanyData.CompanyType.CONSUMER:
			key_metric_title.text = "DAU / MAU"
			var mau: int = maxi(1, p.users)
			var ratio: float = float(p.dau) / float(mau)
			key_metric_label.text = "%.0f%%" % (ratio * 100)
		CompanyData.CompanyType.MARKETPLACE:
			key_metric_title.text = "GMV / Q"
			var gmv: float = p.users * 50.0 * 3.0
			key_metric_label.text = "$%s" % SceneLoader.format_money(gmv)
		CompanyData.CompanyType.DEV_TOOLS:
			key_metric_title.text = "API Calls / Q"
			var calls: float = p.users * 1000.0 * 3.0
			key_metric_label.text = "%s" % SceneLoader.format_number(roundi(calls))
		_:
			key_metric_title.text = "Valuation"
			key_metric_label.text = "$%s" % SceneLoader.format_money(GameState.company.valuation)


func _refresh_economy() -> void:
	match GameState.market.economy_state:
		MarketData.EconomyState.BULL:
			economy_label.text = "Market: Bull"
		MarketData.EconomyState.BEAR:
			economy_label.text = "Market: Bear"
		_:
			economy_label.text = "Market: Neutral"


func _refresh_energy() -> void:
	var e: int = GameState.founder_energy
	var desc: String
	if e >= 80:
		desc = "Fresh"
	elif e >= 60:
		desc = "Steady"
	elif e >= 40:
		desc = "Tired"
	elif e >= 20:
		desc = "Exhausted"
	else:
		desc = "Burning out!"
	energy_label.text = "Energy: %d%% (%s)" % [e, desc]


func _on_feature_shipped_dashboard(feature_name: String, quality: int) -> void:
	if _feature_banner == null:
		return
	var q_word := "great" if quality >= 70 else ("decent" if quality >= 45 else "rough")
	_feature_banner.text = "Feature shipped: %s  (%s quality, %d/100) — check Product for details" % [feature_name, q_word, quality]
	_feature_banner.modulate.a = 1.0
	_feature_banner.visible = true
	var tw := create_tween()
	tw.tween_interval(5.0)
	tw.tween_property(_feature_banner, "modulate:a", 0.0, 0.8)
	tw.tween_callback(func() -> void: _feature_banner.visible = false)


func _on_event(event: EventData) -> void:
	_pending_events.append(event)

	var label := Label.new()
	label.text = "• %s" % event.title
	label.add_theme_font_size_override("font_size", 14)
	while event_log_container.get_child_count() >= MAX_VISIBLE_EVENTS:
		var oldest := event_log_container.get_child(0)
		event_log_container.remove_child(oldest)
		oldest.queue_free()
	event_log_container.add_child(label)
	_refresh_events_heading()
	_set_advance_hint(
		"Resolve %d pending event%s before the next quarter." % [
			_pending_events.size(),
			"s" if _pending_events.size() != 1 else "",
		],
		Color(0.95, 0.75, 0.4)
	)
	_update_advance_button_label()


func _on_advance() -> void:
	# Free-tier gate: after FREE_QUARTER_LIMIT quarters the player must unlock.
	if AdManager.is_game_locked():
		AdManager.show_paywall(
			# on_unlock: re-enable the button so the player can continue immediately.
			func() -> void: advance_btn.disabled = false,
			# on_cancel: just re-enable the button so they can try again later.
			func() -> void: advance_btn.disabled = false,
		)
		advance_btn.disabled = true
		_set_advance_hint("Unlock the full game to continue this run.", Color(0.95, 0.55, 0.45))
		_update_advance_button_label()
		return

	advance_btn.disabled = true
	_set_advance_hint("Simulating quarter...", Color(0.6, 0.78, 0.95))
	_update_advance_button_label()
	_play_quarter_transition_placeholder()
	SceneLoader.free_children(event_log_container)
	_pending_events.clear()
	_refresh_events_heading()
	Analytics.track_quarter_advanced(GameState.current_year, GameState.current_quarter)
	GameState.advance_quarter()
	_show_advance_toast()
	Analytics.track_revenue(GameState.financials.revenue)

	_show_quarterly_report()

	AdManager.show_ad("interstitial_quarter_end")

	if not _pending_events.is_empty():
		advance_btn.disabled = true
		_set_advance_hint(
			"Resolve %d pending event%s before the next quarter." % [
				_pending_events.size(),
				"s" if _pending_events.size() != 1 else "",
			],
			Color(0.95, 0.75, 0.4)
		)
		_update_advance_button_label()
		_show_next_event()
	else:
		advance_btn.disabled = false
		_set_advance_hint("Tip: review your report, then advance when ready.", Color(0.7, 0.82, 0.95))
		_update_advance_button_label()


func _show_next_event() -> void:
	if _pending_events.is_empty():
		advance_btn.disabled = false
		_set_advance_hint("Tip: review your report, then advance when ready.", Color(0.7, 0.82, 0.95))
		_update_advance_button_label()
		_refresh(GameState.current_quarter)
		return
	var ev: EventData = _pending_events[0]
	event_popup.show_event(ev)


func _on_event_resolved(_event: EventData, _choice_index: int) -> void:
	Analytics.track_event_choice(_event.id, _choice_index)
	if not _pending_events.is_empty():
		_pending_events.remove_at(0)
	_refresh_events_heading()
	if _pending_events.is_empty():
		_set_advance_hint("All events resolved. You can advance again.", Color(0.55, 0.88, 0.55))
	else:
		_set_advance_hint(
			"Resolve %d pending event%s before the next quarter." % [
				_pending_events.size(),
				"s" if _pending_events.size() != 1 else "",
			],
			Color(0.95, 0.75, 0.4)
		)
	_update_advance_button_label()
	_show_next_event()


const GAME_OVER_MESSAGES := {
	"bankruptcy": "Out of Money",
	"dead_product": "No Users Left",
	"founder_burnout": "Founder Burnout",
	"board_takeover": "Board Replaced You",
}

func _on_game_over(reason: String) -> void:
	Analytics.track_game_over(reason, GameState.current_year, GameState.current_quarter)
	GameState.set_meta("game_over_reason", reason)
	SceneLoader.goto_scene("res://src/ui/game_over/game_over_screen.tscn")


func _on_game_won(win_type: String) -> void:
	GameState.register_achieved_win(win_type)
	GameState.set_meta("win_type", win_type)
	SceneLoader.goto_scene("res://src/ui/victory/victory_screen.tscn")


func _refresh_office_banner() -> void:
	if office_banner == null or GameState.company == null:
		return
	var level: int = clampi(GameState.company.office_level, 0, OFFICE_BANNER_PATHS.size() - 1)
	var path: String = OFFICE_BANNER_PATHS[level]
	if office_banner.texture == null or not office_banner.texture.resource_path.ends_with(OFFICE_BANNER_PATHS[level].get_file()):
		var tex: Texture2D = ResourceLoader.load(path) as Texture2D
		if tex:
			office_banner.texture = tex
	_refresh_office_worker_ambient()


func _refresh_office_worker_ambient() -> void:
	if _office_worker_layer == null or GameState.company == null:
		return
	SceneLoader.free_children(_office_worker_layer)
	if GameState.employees.is_empty():
		return

	var width: float = maxf(120.0, office_banner.size.x)
	var height: float = maxf(80.0, office_banner.size.y)
	var office_level: int = clampi(GameState.company.office_level, 0, 3)
	var style: Dictionary = OFFICE_WORKSPACE_STYLES.get(office_level, OFFICE_WORKSPACE_STYLES[0])
	var accent: Color = _office_accent_color()

	var tint := ColorRect.new()
	tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tint.color = Color(accent.r, accent.g, accent.b, clampf(0.10 + float(office_level) * 0.02, 0.08, 0.18))
	_office_worker_layer.add_child(tint)

	var slots: Array[Vector2] = _build_desk_slots(style, width, height)
	var total_visible: int = mini(GameState.employees.size(), slots.size())
	var desk_w: float = float(style.get("desk_w", 16.0))
	var desk_h: float = float(style.get("desk_h", 4.0))
	for i in total_visible:
		var emp: EmployeeData = GameState.employees[i]
		var slot: Vector2 = slots[i]

		var desk := ColorRect.new()
		desk.custom_minimum_size = Vector2(desk_w, desk_h)
		desk.size = Vector2(desk_w, desk_h)
		desk.color = Color(0.18, 0.22, 0.3, 0.9).lerp(accent, 0.18)
		desk.position = Vector2(slot.x - (desk_w * 0.5), slot.y)
		_office_worker_layer.add_child(desk)

		var monitor := ColorRect.new()
		monitor.custom_minimum_size = Vector2(5, 2)
		monitor.size = Vector2(5, 2)
		monitor.color = Color(0.15, 0.2, 0.27, 0.95)
		monitor.position = Vector2(slot.x + (desk_w * 0.25), slot.y - 2.0)
		_office_worker_layer.add_child(monitor)

		var worker: Control = _make_worker_sprite(emp)
		worker.position = Vector2(slot.x - 4.0, slot.y - 11.0)
		_office_worker_layer.add_child(worker)

		var base_pos: Vector2 = worker.position
		var tw := worker.create_tween().set_loops()
		tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_interval(float(hash(emp.employee_uid) % 11) * 0.04)
		var bob: float = 1.1 + (float(emp.assignment % 3) * 0.25)
		tw.tween_property(worker, "position:y", base_pos.y + bob, 0.54)
		tw.tween_property(worker, "position:y", base_pos.y, 0.54)
		if emp.assignment == EmployeeData.Assignment.BUGS:
			tw.tween_property(worker, "position:x", base_pos.x + 0.6, 0.22)
			tw.tween_property(worker, "position:x", base_pos.x - 0.6, 0.22)
			tw.tween_property(worker, "position:x", base_pos.x, 0.22)


func _build_desk_slots(style: Dictionary, width: float, height: float) -> Array[Vector2]:
	var slots: Array[Vector2] = []
	var rows: int = maxi(1, int(style.get("rows", 1)))
	var per_row: int = maxi(1, int(style.get("per_row", 4)))
	var base_y_ratio: float = clampf(float(style.get("base_y_ratio", 0.62)), 0.40, 0.86)
	var row_gap: float = clampf(float(style.get("row_gap", 14.0)), 10.0, 24.0)
	for row in rows:
		var y: float = clampf((height * base_y_ratio) + (float(row) * row_gap), 24.0, height - 9.0)
		for col in per_row:
			var tx: float = float(col + 1) / float(per_row + 1)
			var x: float = lerpf(12.0, width - 12.0, tx)
			slots.append(Vector2(x, y))
	return slots


func _make_worker_sprite(emp: EmployeeData) -> Control:
	var root := Control.new()
	root.custom_minimum_size = Vector2(10, 10)
	root.size = Vector2(10, 10)

	var body := ColorRect.new()
	body.custom_minimum_size = Vector2(6, 5)
	body.size = Vector2(6, 5)
	body.position = Vector2(2, 4)
	body.color = _assignment_color(emp.assignment)
	root.add_child(body)

	var head := ColorRect.new()
	head.custom_minimum_size = Vector2(4, 3)
	head.size = Vector2(4, 3)
	head.position = Vector2(3, 1)
	head.color = _worker_skin_color(emp.employee_uid)
	root.add_child(head)

	var badge := ColorRect.new()
	badge.custom_minimum_size = Vector2(2, 2)
	badge.size = Vector2(2, 2)
	badge.position = Vector2(6, 6)
	badge.color = Color(0.9, 0.93, 0.98, 0.85)
	root.add_child(badge)

	return root


func _worker_skin_color(uid: String) -> Color:
	var palette: Array[Color] = [
		Color(0.93, 0.79, 0.66, 1.0),
		Color(0.85, 0.68, 0.52, 1.0),
		Color(0.73, 0.55, 0.41, 1.0),
		Color(0.58, 0.41, 0.29, 1.0),
	]
	var idx: int = absi(hash(uid)) % palette.size()
	return palette[idx]


func _office_accent_color() -> Color:
	if GameState.company == null:
		return Color(0.38, 0.62, 0.88, 1.0)
	var base := Color(0.38, 0.62, 0.88, 1.0)
	match GameState.company.type:
		CompanyData.CompanyType.SAAS:
			base = Color(0.36, 0.62, 0.9, 1.0)
		CompanyData.CompanyType.CONSUMER:
			base = Color(0.86, 0.52, 0.78, 1.0)
		CompanyData.CompanyType.MARKETPLACE:
			base = Color(0.9, 0.64, 0.42, 1.0)
		CompanyData.CompanyType.DEV_TOOLS:
			base = Color(0.58, 0.52, 0.94, 1.0)
		_:
			base = Color(0.38, 0.62, 0.88, 1.0)
	match GameState.company.hosting_plan:
		CompanyData.HostingPlan.MANAGED_CLOUD:
			return base.lightened(0.08)
		CompanyData.HostingPlan.IN_HOUSE:
			return base.darkened(0.12)
		_:
			return base


func _assignment_color(assignment: int) -> Color:
	match assignment:
		EmployeeData.Assignment.FEATURES:
			return Color(0.38, 0.88, 0.52, 0.95)
		EmployeeData.Assignment.BUGS:
			return Color(0.95, 0.58, 0.42, 0.95)
		EmployeeData.Assignment.TECH_DEBT:
			return Color(0.9, 0.78, 0.35, 0.95)
		EmployeeData.Assignment.INFRA:
			return Color(0.42, 0.72, 0.96, 0.95)
		EmployeeData.Assignment.RND:
			return Color(0.74, 0.56, 0.95, 0.95)
		_:
			return Color(0.7, 0.7, 0.75, 0.9)


func _refresh_team() -> void:
	SceneLoader.free_children(team_container)

	if GameState.employees.is_empty():
		var lbl := Label.new()
		lbl.text = "No team yet — visit People to hire"
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.45, 0.45, 0.5))
		team_container.add_child(lbl)
		return

	for emp: EmployeeData in GameState.employees:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		team_container.add_child(row)

		var avatar := TextureRect.new()
		avatar.custom_minimum_size = Vector2(32, 32)
		avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		avatar.clip_contents = true
		var avatar_idx: int = (hash(emp.employee_name) % 8) + 1
		var avatar_tex: Texture2D = ResourceLoader.load("res://assets/avatars/avatar_%d.png" % avatar_idx)
		if avatar_tex:
			avatar.texture = avatar_tex
		row.add_child(avatar)

		var lbl := Label.new()
		var assign_name: String = EmployeeData.ASSIGNMENT_NAMES.get(emp.assignment, "Unassigned")
		lbl.text = "%s — %s · %s" % [emp.employee_name, emp.display_title(), assign_name]
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var morale_color: Color
		if emp.morale >= 70:
			morale_color = Color(0.55, 0.8, 0.55)
		elif emp.morale >= 40:
			morale_color = Color(0.85, 0.75, 0.35)
		else:
			morale_color = Color(0.9, 0.4, 0.35)
		lbl.add_theme_color_override("font_color", morale_color)
		row.add_child(lbl)


func _show_quarterly_report() -> void:
	var bullets := QuarterlyReport.generate(GameState)
	if bullets.is_empty():
		report_panel.visible = false
		return
	var lines: Array[String] = []
	for b in bullets:
		lines.append("• " + b)
	report_body.text = "\n".join(lines)
	report_panel.visible = true


func _on_people() -> void:
	SceneLoader.goto_scene("res://src/ui/people/employee_list.tscn")


func _on_product() -> void:
	SceneLoader.goto_scene("res://src/ui/product/product_overview.tscn")


func _on_finance() -> void:
	SceneLoader.goto_scene("res://src/ui/finance/finance_overview.tscn")


func _on_market() -> void:
	SceneLoader.goto_scene("res://src/ui/market/market_leaderboard.tscn")


func _on_save_error(message: String) -> void:
	_headline_timer.stop()
	headline_label.text = message
	headline_label.modulate.a = 1.0
	headline_label.visible = true
	headline_label.add_theme_color_override("font_color", Color(0.95, 0.4, 0.3))
	var restore_tween := create_tween()
	restore_tween.tween_interval(4.0)
	restore_tween.tween_callback(func():
		headline_label.remove_theme_color_override("font_color")
		_refresh_headlines()
	)


func _on_menu() -> void:
	if not GameState.current_slot.is_empty():
		GameState.save_game(GameState.current_slot)
	SceneLoader.goto_scene("res://src/ui/main_menu/main_menu.tscn")


func _safe_disconnect(sig: Signal, callable: Callable) -> void:
	if sig.is_connected(callable):
		sig.disconnect(callable)


