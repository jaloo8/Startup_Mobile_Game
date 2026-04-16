extends Control
## Finance screen — costs, revenue, runway, equity.

@onready var cash_value: Label = %CashValue
@onready var revenue_value: Label = %RevenueValue
@onready var burn_value: Label = %BurnValue
@onready var runway_value: Label = %RunwayValue
@onready var cash_title_btn: Button = %CashTitle
@onready var revenue_title_btn: Button = %RevenueTitle
@onready var burn_title_btn: Button = %BurnTitle
@onready var runway_title_btn: Button = %RunwayTitle
@onready var equity_value: Label = %EquityValue
@onready var valuation_value: Label = %ValuationValue
@onready var trend_chart: Control = %TrendChart
@onready var trend_meta: Label = %TrendMeta
@onready var health_trend_chart: Control = %HealthTrendChart
@onready var health_trend_meta: Label = %HealthTrendMeta

@onready var salary_cost: Label = %SalaryCost
@onready var infra_cost: Label = %InfraCost
@onready var office_cost: Label = %OfficeCost
@onready var costs_grid: GridContainer = %CostsGrid

@onready var board_label: Label = %BoardLabel
@onready var back_btn: Button = %BackButton
@onready var fundraise_btn: Button = %FundraiseButton
@onready var offer_panel: PanelContainer = %OfferPanel
@onready var offer_label: Label = %OfferLabel
@onready var accept_btn: Button = %AcceptButton
@onready var decline_btn: Button = %DeclineButton

var _current_offer: Dictionary = {}
var _board_row: HBoxContainer  # HBox wrapper around board_label + info button
var _quarter_delta_label: Label
var _next_move_label: Label
var _hosting_plan_picker: OptionButton
var _hosting_meta_label: Label
var _hosting_cost_value: Label
var _logistics_btn: Button
var _drilldown_label: Label
var _marketing_picker: OptionButton
var _marketing_cost_value: Label

const MARKETING_TIERS: Array = [0.0, 1_000.0, 3_000.0, 6_000.0, 12_000.0, 20_000.0]
const MARKETING_TIER_NAMES: Array = ["None ($0)", "Minimal ($1K)", "Light ($3K)", "Moderate ($6K)", "Aggressive ($12K)", "Heavy ($20K)"]


func _ready() -> void:
	back_btn.pressed.connect(_on_back)
	fundraise_btn.pressed.connect(_on_fundraise)
	accept_btn.pressed.connect(_on_accept_offer)
	decline_btn.pressed.connect(_on_decline_offer)
	offer_panel.visible = false

	_apply_plain_finance_titles()
	_wire_glossary(cash_title_btn, "cash_on_hand")
	_wire_glossary(revenue_title_btn, "quarterly_revenue")
	_wire_glossary(burn_title_btn, "quarterly_burn")
	_wire_glossary(runway_title_btn, "runway")
	_wire_glossary(%EquityTitle, "equity")
	_wire_glossary(%ValuationTitle, "valuation")
	_add_info_button_near(board_label, "board_patience")
	_build_context_hints()
	_build_hosting_controls()
	_build_marketing_controls()
	_refresh()
	UITouchHelper.harden_tree(self)
	Analytics.track_screen("finance")
	# Entrance: slide the content up from below.
	var content := get_node_or_null("MarginContainer/VBox")
	if content is Control:
		AnimHelper.slide_in(content, Vector2(0, 30), 0.0, 0.22)


func _apply_plain_finance_titles() -> void:
	if cash_title_btn:
		cash_title_btn.text = "Cash (On Hand) ⓘ"
	if revenue_title_btn:
		revenue_title_btn.text = "Revenue (Qtr) ⓘ"
	if burn_title_btn:
		burn_title_btn.text = "Burn Rate (Qtr) ⓘ"
	if runway_title_btn:
		runway_title_btn.text = "Runway (Time Left) ⓘ"


func _build_context_hints() -> void:
	var vbox := cash_value.get_parent().get_parent()
	if vbox == null:
		return

	_quarter_delta_label = Label.new()
	_quarter_delta_label.add_theme_font_size_override("font_size", 12)
	_quarter_delta_label.add_theme_color_override("font_color", Color(0.66, 0.74, 0.9))
	_quarter_delta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_quarter_delta_label)
	vbox.move_child(_quarter_delta_label, cash_value.get_parent().get_index() + 1)

	_next_move_label = Label.new()
	_next_move_label.add_theme_font_size_override("font_size", 12)
	_next_move_label.add_theme_color_override("font_color", Color(0.64, 0.82, 0.95))
	_next_move_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_next_move_label)
	vbox.move_child(_next_move_label, cash_value.get_parent().get_index() + 2)

	_drilldown_label = Label.new()
	_drilldown_label.add_theme_font_size_override("font_size", ThemeManager.FONT_XS)
	_drilldown_label.add_theme_color_override("font_color", Color(0.7, 0.75, 0.9))
	_drilldown_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_drilldown_label)
	vbox.move_child(_drilldown_label, cash_value.get_parent().get_index() + 3)


func _build_hosting_controls() -> void:
	var vbox := cash_value.get_parent().get_parent()
	if vbox == null:
		return

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var title := Label.new()
	title.text = "Hosting Plan"
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color(0.68, 0.72, 0.8))
	row.add_child(title)

	_hosting_plan_picker = OptionButton.new()
	_hosting_plan_picker.custom_minimum_size = Vector2(170, ThemeManager.TOUCH_MIN_H)
	_hosting_plan_picker.add_item(CompanyData.HOSTING_PLAN_NAMES.get(CompanyData.HostingPlan.MANAGED_CLOUD, "Managed Cloud"))
	_hosting_plan_picker.add_item(CompanyData.HOSTING_PLAN_NAMES.get(CompanyData.HostingPlan.HYBRID, "Hybrid"))
	_hosting_plan_picker.add_item(CompanyData.HOSTING_PLAN_NAMES.get(CompanyData.HostingPlan.IN_HOUSE, "In-house"))
	_hosting_plan_picker.item_selected.connect(_on_hosting_plan_selected)
	row.add_child(_hosting_plan_picker)

	_logistics_btn = Button.new()
	_logistics_btn.text = "Open Logistics"
	_logistics_btn.custom_minimum_size = Vector2(120, ThemeManager.TOUCH_MIN_H)
	_logistics_btn.pressed.connect(_on_open_logistics)
	row.add_child(_logistics_btn)

	vbox.add_child(row)
	vbox.move_child(row, cash_value.get_parent().get_index() + 4)

	_hosting_meta_label = Label.new()
	_hosting_meta_label.add_theme_font_size_override("font_size", ThemeManager.FONT_XS)
	_hosting_meta_label.add_theme_color_override("font_color", Color(0.62, 0.67, 0.82))
	_hosting_meta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_hosting_meta_label)
	vbox.move_child(_hosting_meta_label, cash_value.get_parent().get_index() + 5)

	var hosting_title := Label.new()
	hosting_title.text = "Hosting"
	costs_grid.add_child(hosting_title)
	_hosting_cost_value = Label.new()
	_hosting_cost_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hosting_cost_value.text = "$0"
	costs_grid.add_child(_hosting_cost_value)


func _build_marketing_controls() -> void:
	var vbox := cash_value.get_parent().get_parent()
	if vbox == null:
		return

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var title := Label.new()
	title.text = "Marketing Budget"
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color(0.68, 0.72, 0.8))
	row.add_child(title)

	_marketing_picker = OptionButton.new()
	_marketing_picker.custom_minimum_size = Vector2(170, ThemeManager.TOUCH_MIN_H)
	for tier_name in MARKETING_TIER_NAMES:
		_marketing_picker.add_item(tier_name)
	_marketing_picker.item_selected.connect(_on_marketing_tier_selected)
	row.add_child(_marketing_picker)

	vbox.add_child(row)
	vbox.move_child(row, cash_value.get_parent().get_index() + 6)

	var marketing_title := Label.new()
	marketing_title.text = "Marketing"
	costs_grid.add_child(marketing_title)
	_marketing_cost_value = Label.new()
	_marketing_cost_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_marketing_cost_value.text = "$0"
	costs_grid.add_child(_marketing_cost_value)


func _on_marketing_tier_selected(index: int) -> void:
	if GameState.company == null:
		return
	var tier_idx := clampi(index, 0, MARKETING_TIERS.size() - 1)
	var new_budget: float = MARKETING_TIERS[tier_idx]
	if is_equal_approx(GameState.company.marketing_budget, new_budget):
		return
	GameState.company.marketing_budget = new_budget
	if not GameState.current_slot.is_empty():
		GameState.auto_save()
	_refresh()


func _refresh() -> void:
	if GameState.company == null:
		return

	cash_value.text = "$%s" % SceneLoader.format_money(GameState.company.cash)
	revenue_value.text = "$%s / quarter" % SceneLoader.format_money(GameState.financials.revenue)
	burn_value.text = "$%s / quarter" % SceneLoader.format_money(GameState.financials.burn_rate)
	equity_value.text = "%.1f%%" % GameState.company.equity_owned
	valuation_value.text = "$%s" % SceneLoader.format_money(GameState.company.valuation)

	var rw: float = GameState.financials.runway_quarters(GameState.company.cash)
	if rw == INF:
		runway_value.text = "Profitable — no runway needed"
		runway_value.add_theme_color_override("font_color", ThemeManager.C_GREEN)
	elif rw < 1.0:
		runway_value.text = "Critical — less than 1 quarter"
		runway_value.add_theme_color_override("font_color", ThemeManager.C_RED)
	elif rw < 3.0:
		runway_value.text = "~%d quarters — start fundraising" % roundi(rw)
		runway_value.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2))
	else:
		runway_value.text = "~%d quarters" % roundi(rw)
		runway_value.add_theme_color_override("font_color", ThemeManager.C_GREEN)

	var costs: Dictionary = GameState.financials.costs_breakdown
	salary_cost.text = "$%s" % SceneLoader.format_money(costs.get("salaries", 0.0))
	infra_cost.text = "$%s" % SceneLoader.format_money(costs.get("infrastructure", 0.0))
	office_cost.text = "$%s" % SceneLoader.format_money(costs.get("office", 0.0))
	if _hosting_cost_value:
		_hosting_cost_value.text = "$%s" % SceneLoader.format_money(costs.get("hosting", 0.0))
	if _marketing_cost_value:
		_marketing_cost_value.text = "$%s" % SceneLoader.format_money(costs.get("marketing", 0.0))
	_refresh_hosting_controls()
	_refresh_marketing_controls()
	_refresh_context_hints(rw)
	_refresh_trend_chart()
	_refresh_health_trend_chart()

	var _board_container: Control = _board_row if _board_row else board_label
	if GameState.financials.funding_rounds.is_empty():
		_board_container.visible = false
	elif not _board_container.visible:
		_board_container.visible = true
		AnimHelper.fade_in(_board_container, 0.0, 0.2)
	else:
		_board_container.visible = true
		var bp: int = GameState.board_patience
		if bp >= 5:
			board_label.text = "Board: Satisfied"
			board_label.add_theme_color_override("font_color", ThemeManager.C_GREEN)
		elif bp >= 3:
			board_label.text = "Board: Watching closely"
			board_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2))
		elif bp >= 2:
			board_label.text = "Board: Impatient"
			board_label.add_theme_color_override("font_color", Color(0.95, 0.5, 0.2))
		else:
			board_label.text = "Board: Furious — your position is at risk"
			board_label.add_theme_color_override("font_color", ThemeManager.C_RED)


func _refresh_context_hints(runway_quarters: float) -> void:
	_refresh_quarter_delta_hint()
	_refresh_next_move_hint(runway_quarters)
	_refresh_drilldown_hint()


func _refresh_hosting_controls() -> void:
	if _hosting_plan_picker == null or _hosting_meta_label == null or GameState.company == null:
		return
	var max_idx: int = maxi(0, _hosting_plan_picker.get_item_count() - 1)
	var selected_plan: int = clampi(GameState.company.hosting_plan, 0, max_idx)
	if _hosting_plan_picker.selected != selected_plan:
		_hosting_plan_picker.select(selected_plan)

	var peak_util: float = maxf(
		GameState.company.hosting_util_web,
		maxf(GameState.company.hosting_util_cache, GameState.company.hosting_util_data)
	)
	var workload_profile: String = GameState.company.hosting_workload_profile.strip_edges()
	if workload_profile.is_empty():
		workload_profile = "General Cloud"
	var pressure: float = GameState.company.hosting_data_center_pressure
	_hosting_meta_label.text = "%s · Reliability %.1f%% · Web %.0f%% · Cache %.0f%% · Data %.0f%% · Overage $%s" % [
		GameState.company.hosting_plan_name(),
		GameState.company.hosting_reliability,
		GameState.company.hosting_util_web * 100.0,
		GameState.company.hosting_util_cache * 100.0,
		GameState.company.hosting_util_data * 100.0,
		SceneLoader.format_money(GameState.company.hosting_overage_cost),
	]
	_hosting_meta_label.text += " · Workload %s" % workload_profile
	if pressure >= 2.2:
		_hosting_meta_label.text += " · data-center pressure high"
	elif pressure >= 1.25:
		_hosting_meta_label.text += " · scaling pressure rising"
	var upgrades_total: int = GameState.company.hosting_upgrade_web_level \
		+ GameState.company.hosting_upgrade_cache_level \
		+ GameState.company.hosting_upgrade_data_level
	if upgrades_total > 0 or GameState.company.hosting_optimization_level > 0:
		_hosting_meta_label.text += " · Upgrades %d · Opt L%d" % [
			upgrades_total,
			GameState.company.hosting_optimization_level,
		]
	if GameState.company.hosting_reliability < 93.0 or peak_util > 1.15:
		_hosting_meta_label.add_theme_color_override("font_color", ThemeManager.C_ORANGE)
	elif pressure >= 2.2:
		_hosting_meta_label.add_theme_color_override("font_color", Color(0.95, 0.72, 0.42))
	elif GameState.company.hosting_reliability < 97.0 or peak_util > 0.95 or pressure >= 1.25:
		_hosting_meta_label.add_theme_color_override("font_color", Color(0.95, 0.8, 0.4))
	else:
		_hosting_meta_label.add_theme_color_override("font_color", Color(0.62, 0.82, 0.62))


func _refresh_marketing_controls() -> void:
	if _marketing_picker == null or GameState.company == null:
		return
	var current_budget: float = GameState.company.marketing_budget
	var best_idx: int = 0
	for i in MARKETING_TIERS.size():
		if current_budget >= MARKETING_TIERS[i]:
			best_idx = i
	if _marketing_picker.selected != best_idx:
		_marketing_picker.select(best_idx)


func _refresh_quarter_delta_hint() -> void:
	if _quarter_delta_label == null:
		return
	var hist: Array = GameState.history
	if hist.size() < 2:
		_quarter_delta_label.text = "Quarter delta: not enough history yet."
		return
	var prev: Dictionary = _as_dict(hist[hist.size() - 2])
	var curr: Dictionary = _as_dict(hist[hist.size() - 1])
	var cash_delta: float = float(curr.get("cash", 0.0)) - float(prev.get("cash", 0.0))
	var rev_delta: float = float(curr.get("revenue", 0.0)) - float(prev.get("revenue", 0.0))
	var users_delta: int = int(curr.get("users", 0)) - int(prev.get("users", 0))

	_quarter_delta_label.text = "Quarter delta  ·  Cash %s  ·  Revenue %s  ·  Users %s" % [
		_delta_money_text(cash_delta),
		_delta_money_text(rev_delta),
		_delta_int_text(users_delta),
	]
	if cash_delta > 0.0 and rev_delta >= 0.0:
		_quarter_delta_label.add_theme_color_override("font_color", Color(0.55, 0.88, 0.56))
	elif cash_delta < 0.0 and rev_delta < 0.0:
		_quarter_delta_label.add_theme_color_override("font_color", Color(0.95, 0.6, 0.5))
	else:
		_quarter_delta_label.add_theme_color_override("font_color", Color(0.66, 0.74, 0.9))


func _refresh_drilldown_hint() -> void:
	if _drilldown_label == null:
		return
	var hist: Array = GameState.history
	if hist.size() < 2:
		_drilldown_label.text = "Driver read: appears after one completed quarter."
		return

	var prev: Dictionary = _as_dict(hist[hist.size() - 2])
	var curr: Dictionary = _as_dict(hist[hist.size() - 1])
	var rev_delta: float = float(curr.get("revenue", 0.0)) - float(prev.get("revenue", 0.0))
	var cash_delta: float = float(curr.get("cash", 0.0)) - float(prev.get("cash", 0.0))
	var salary_delta: float = _snapshot_cost(curr, "salaries_cost") - _snapshot_cost(prev, "salaries_cost")
	var infra_delta: float = _snapshot_cost(curr, "infrastructure_cost") - _snapshot_cost(prev, "infrastructure_cost")
	var hosting_delta: float = _snapshot_cost(curr, "hosting_cost") - _snapshot_cost(prev, "hosting_cost")
	var office_delta: float = _snapshot_cost(curr, "office_cost") - _snapshot_cost(prev, "office_cost")
	var marketing_delta: float = _snapshot_cost(curr, "marketing_cost") - _snapshot_cost(prev, "marketing_cost")
	var incidents: int = int(curr.get("hosting_incidents", 0))

	var parts: Array[String] = []
	parts.append("Revenue %s" % _delta_money_text(rev_delta))
	_append_cost_driver(parts, "Salaries", salary_delta)
	_append_cost_driver(parts, "Infra", infra_delta)
	_append_cost_driver(parts, "Hosting", hosting_delta)
	_append_cost_driver(parts, "Office", office_delta)
	_append_cost_driver(parts, "Marketing", marketing_delta)
	if incidents > 0:
		parts.append("%d hosting incident%s" % [incidents, "s" if incidents != 1 else ""])
	if parts.size() > 5:
		parts = parts.slice(0, 5)
	parts.append("Cash %s" % _delta_money_text(cash_delta))

	_drilldown_label.text = "Driver read: %s." % "; ".join(parts)
	if cash_delta >= 0.0:
		_drilldown_label.add_theme_color_override("font_color", Color(0.62, 0.84, 0.62))
	else:
		_drilldown_label.add_theme_color_override("font_color", Color(0.95, 0.7, 0.46))


func _snapshot_cost(snapshot: Dictionary, key: String) -> float:
	return float(snapshot.get(key, 0.0))


func _append_cost_driver(parts: Array[String], label: String, delta: float) -> void:
	if absf(delta) < 25.0:
		return
	parts.append("%s %s" % [label, _delta_money_text(delta)])


func _refresh_next_move_hint(runway_quarters: float) -> void:
	if _next_move_label == null:
		return
	var hint: String
	var peak_util: float = maxf(
		GameState.company.hosting_util_web,
		maxf(GameState.company.hosting_util_cache, GameState.company.hosting_util_data)
	)
	var pressure: float = GameState.company.hosting_data_center_pressure
	var upgrades_total: int = GameState.company.hosting_upgrade_web_level \
		+ GameState.company.hosting_upgrade_cache_level \
		+ GameState.company.hosting_upgrade_data_level
	if pressure >= 2.2 and upgrades_total < 3:
		hint = "Next best move: your workload is data-center-heavy — prioritize data/cache capacity and infra staffing now."
	elif peak_util > 1.05 and upgrades_total < 2:
		hint = "Next best move: load is peaking — open Logistics and buy lane capacity before incidents pile up."
	elif GameState.company.hosting_reliability < 93.0:
		hint = "Next best move: hosting reliability is unstable — add Infra capacity or switch to a safer hosting plan."
	elif GameState.company.hosting_overage_cost >= 600.0:
		hint = "Next best move: hosting overage is high — rebalance Infra staffing or move to a cheaper plan."
	elif runway_quarters < 1.0:
		hint = "Next best move: runway is critical — raise now or reduce burn this quarter."
	elif runway_quarters < 3.0:
		hint = "Next best move: runway is getting tight — plan a raise before it becomes urgent."
	elif GameState.financials.burn_rate > (GameState.financials.revenue * 1.4):
		hint = "Next best move: burn is outpacing revenue — prioritize retention and monetization features."
	elif GameState.company.equity_owned < 50.0:
		hint = "Next best move: you have strong runway, so be selective with further dilution."
	else:
		hint = "Next best move: keep compounding revenue while monitoring burn and board patience."
	_next_move_label.text = hint


func _on_hosting_plan_selected(index: int) -> void:
	if GameState.company == null:
		return
	var new_plan := clampi(index, 0, 2) as CompanyData.HostingPlan
	if GameState.company.hosting_plan == new_plan:
		return
	GameState.company.hosting_plan = new_plan
	if not GameState.current_slot.is_empty():
		GameState.auto_save()
	_refresh()


func _on_open_logistics() -> void:
	SceneLoader.goto_scene("res://src/ui/logistics/logistics_overview.tscn")


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


func _as_dict(v: Variant) -> Dictionary:
	if v is Dictionary:
		return v
	return {}


func _wire_glossary(btn: Button, key: String) -> void:
	if btn == null:
		return
	btn.pressed.connect(Glossary.show_term.bind(key))
	_set_glossary_tooltip(btn, key)


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


func _add_info_button_near(target: Label, glossary_key: String) -> void:
	if target == null:
		return
	var parent := target.get_parent()
	if parent == null:
		return
	# Wrap the label + info button in an HBox so they sit side-by-side.
	var idx := target.get_index()
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	parent.remove_child(target)
	hbox.add_child(target)
	var info_btn := Button.new()
	info_btn.text = "ⓘ"
	info_btn.flat = true
	info_btn.custom_minimum_size = Vector2(32, 32)
	info_btn.add_theme_font_size_override("font_size", 13)
	info_btn.pressed.connect(Glossary.show_term.bind(glossary_key))
	_set_glossary_tooltip(info_btn, glossary_key)
	hbox.add_child(info_btn)
	parent.add_child(hbox)
	parent.move_child(hbox, idx)
	_board_row = hbox


func _trend_points(limit: int = 12) -> Array[Dictionary]:
	var points: Array[Dictionary] = []
	for item in GameState.history:
		if item is Dictionary:
			points.append(item)

	var live_point: Dictionary = {
		"quarter": GameState.current_quarter,
		"year": GameState.current_year,
		"cash": GameState.company.cash,
		"revenue": GameState.financials.revenue,
		"users": GameState.product.users,
		"valuation": GameState.company.valuation,
		"employees": GameState.employees.size(),
		"avg_morale": GameState.average_team_morale(),
	}
	if points.is_empty():
		points.append(live_point)
	else:
		var last: Dictionary = points[-1]
		var same_period := int(last.get("quarter", -1)) == GameState.current_quarter \
			and int(last.get("year", -1)) == GameState.current_year
		var same_values := is_equal_approx(float(last.get("cash", -1.0)), GameState.company.cash) \
			and is_equal_approx(float(last.get("revenue", -1.0)), GameState.financials.revenue) \
			and int(last.get("users", -1)) == GameState.product.users \
			and is_equal_approx(float(last.get("valuation", -1.0)), GameState.company.valuation) \
			and int(last.get("employees", -1)) == GameState.employees.size() \
			and is_equal_approx(float(last.get("avg_morale", -1.0)), GameState.average_team_morale())
		if not (same_period and same_values):
			points.append(live_point)

	if points.size() > limit:
		points = points.slice(-limit)
	return points


func _refresh_trend_chart() -> void:
	if trend_chart == null:
		return
	var points := _trend_points(12)

	var cash_series: Array[float] = []
	var revenue_series: Array[float] = []
	var burn_series: Array[float] = []
	var users_series: Array[float] = []
	for p in points:
		cash_series.append(float(p.get("cash", 0.0)))
		revenue_series.append(float(p.get("revenue", 0.0)))
		burn_series.append(float(p.get("burn_rate", GameState.financials.burn_rate)))
		users_series.append(float(p.get("users", 0.0)))

	if trend_chart.has_method("set_series"):
		trend_chart.set_series(
			cash_series,    Color(0.33, 0.80, 0.52), "Cash",
			revenue_series, Color(0.37, 0.63, 0.95), "Revenue",
			burn_series,    Color(0.92, 0.38, 0.38), "Burn",
			users_series,   ThemeManager.C_GOLD, "Users"
		)

	if trend_meta:
		var n := points.size()
		trend_meta.text = "Last %d quarter%s · Cash / Revenue / Burn / Users" % [n, "s" if n != 1 else ""]


func _refresh_health_trend_chart() -> void:
	if health_trend_chart == null:
		return
	var points := _trend_points(12)

	var valuation_series: Array[float] = []
	var team_series: Array[float] = []
	var morale_series: Array[float] = []
	for p in points:
		valuation_series.append(float(p.get("valuation", GameState.company.valuation)))
		team_series.append(float(p.get("employees", GameState.employees.size())))
		morale_series.append(float(p.get("avg_morale", GameState.average_team_morale())))

	if health_trend_chart.has_method("set_series"):
		health_trend_chart.set_series(
			valuation_series, Color(0.72, 0.45, 0.95), "Valuation",
			team_series,      Color(0.42, 0.78, 0.95), "Team",
			morale_series,    Color(0.55, 0.90, 0.60), "Morale"
		)

	if health_trend_meta:
		var n := points.size()
		health_trend_meta.text = "Last %d quarter%s · Valuation / Team / Morale" % [n, "s" if n != 1 else ""]


func _on_fundraise() -> void:
	Analytics.track_fundraise_attempt()
	if not FundraisingEngine.can_fundraise(GameState):
		fundraise_btn.text = "Too early — build more first"
		fundraise_btn.disabled = true
		return

	_current_offer = FundraisingEngine.generate_offer(GameState)
	var o := _current_offer

	if o.get("rejected", false):
		var firm_name: String = o.get("firm_name", "The firm")
		var style: String = o.get("firm_style", "")
		var reason: String = o.get("reason", "They passed.")
		var opening: String = o.get("opening", "")
		var reaction: String = o.get("reaction", "")
		var header := "%s\n%s" % [firm_name, style] if not style.is_empty() else firm_name

		var parts: Array[String] = [header, ""]
		if not opening.is_empty():
			parts.append("\"%s\"" % opening)
			parts.append("")
		parts.append("You pitched your %s round." % o["round"])
		if not reaction.is_empty():
			parts.append("")
			parts.append("\"%s\"" % reaction)
		parts.append("")
		parts.append("\"%s\"" % reason)
		parts.append("")
		parts.append("Try again next quarter — or build more traction first.")
		offer_label.text = "\n".join(parts)

		accept_btn.visible = false
		decline_btn.text = "Back to It"
		offer_panel.visible = true
		AnimHelper.pop_in(offer_panel, 0.0, 0.22)
		fundraise_btn.visible = false
		return

	var firm_name: String = o.get("firm_name", "Investors")
	var style: String = o.get("firm_style", "")
	var tier: String = o.get("tier", "mid")
	var opening: String = o.get("opening", "")
	var offer_dialogue: String = o.get("offer_line", "")

	var header := firm_name
	if not style.is_empty():
		header += "\n%s" % style

	var tier_label := ""
	match tier:
		"elite": tier_label = " (Elite Tier)"
		"top": tier_label = " (Top Tier)"

	var board_note := ""
	if o.get("board_seat", false):
		board_note = "\n\nThey want a board seat. That means oversight — and if you miss targets, they could push to replace you."
	else:
		board_note = "\n\nNo board seat. They're hands-off for now."

	var parts: Array[String] = ["%s%s" % [header, tier_label], ""]
	if not opening.is_empty():
		parts.append("\"%s\"" % opening)
		parts.append("")
	if not offer_dialogue.is_empty():
		parts.append("\"%s\"" % offer_dialogue)
		parts.append("")
	parts.append("%s Round" % o["round"])
	parts.append("")
	parts.append("Offering $%s at a $%s pre-money valuation." % [
		SceneLoader.format_money(o["amount"]),
		SceneLoader.format_money(o["valuation"]),
	])
	parts.append("")
	parts.append("You'd give up %.1f%% of the company.%s" % [o["dilution"], board_note])
	offer_label.text = "\n".join(parts)

	accept_btn.visible = true
	decline_btn.text = "Walk Away"
	offer_panel.visible = true
	AnimHelper.pop_in(offer_panel, 0.0, 0.22)
	fundraise_btn.visible = false


func _on_accept_offer() -> void:
	if _current_offer.get("rejected", false):
		return
	var firm_name: String = _current_offer.get("firm_name", "unknown")
	var amount: float = _current_offer.get("amount", 0.0)
	var round_name: String = _current_offer.get("round", "")
	Analytics.track_fundraise_result(true, firm_name, amount)
	FundraisingEngine.accept_offer(GameState, _current_offer)
	SfxPlayer.play("fundraise")
	AnimHelper.haptic(&"heavy")
	var accept_msg: String = FundraisingEngine.acceptance_line()
	if not accept_msg.is_empty():
		ToastManager.show("\"%s\" — Raised $%s! 🎉" % [accept_msg, SceneLoader.format_money(amount)], "💰", ThemeManager.C_GOLD)
	else:
		ToastManager.show("Raised $%s! 🎉" % SceneLoader.format_money(amount), "💰", ThemeManager.C_GOLD)

	# --- Fundraise celebration (scaled to round size) ---
	# Screen flash — green for money!
	AnimHelper.screen_flash(self, Color(0.2, 0.85, 0.3, 0.25), 0.40)
	AnimHelper.screen_shake(get_tree(), 0.3, 0.3)

	# Confetti burst from the offer panel — money colors.
	var burst_origin := Vector2(size.x * 0.5, offer_panel.global_position.y + offer_panel.size.y * 0.5 - global_position.y)
	var money_colors: Array[Color] = [
		Color(0.18, 0.80, 0.35),   # green
		Color(1.0, 0.84, 0.0),     # gold
		Color(0.30, 0.90, 0.55),   # light green
		Color(0.95, 0.75, 0.15),   # amber
	]
	# Bigger rounds get bigger celebrations.
	var burst_amount := 25
	if amount >= 2_000_000:
		burst_amount = 50
	elif amount >= 500_000:
		burst_amount = 35
	AnimHelper.confetti_burst(self, burst_origin, money_colors, burst_amount, 240.0, 2.0)

	# Series A+ gets a second delayed burst for extra drama.
	if amount >= 2_000_000:
		get_tree().create_timer(0.5).timeout.connect(func() -> void:
			if is_instance_valid(self):
				AnimHelper.confetti_burst(self, Vector2(burst_origin.x - 100, burst_origin.y), money_colors, 20, 180.0, 1.5)
				AnimHelper.confetti_burst(self, Vector2(burst_origin.x + 100, burst_origin.y), money_colors, 20, 180.0, 1.5)
		)

	AnimHelper.pop_out(offer_panel, 0.16, func() -> void:
		offer_panel.visible = false
		fundraise_btn.visible = true
		fundraise_btn.text = "Raise Another Round"
		_refresh()
	)


func _on_decline_offer() -> void:
	var firm_name: String = _current_offer.get("firm_name", "unknown")
	Analytics.track_fundraise_result(false, firm_name, 0.0)
	AnimHelper.pop_out(offer_panel, 0.14, func() -> void:
		offer_panel.visible = false
		fundraise_btn.visible = true
		fundraise_btn.text = "Talk to Investors"
	)


func _on_back() -> void:
	if OS.is_debug_build():
		print("[Finance] _on_back() called — transitioning=%s" % SceneLoader._transitioning)
	SceneLoader.goto_scene("res://src/ui/dashboard/quarter_dashboard.tscn")


