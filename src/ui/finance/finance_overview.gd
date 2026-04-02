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
var _quarter_delta_label: Label
var _next_move_label: Label
var _hosting_plan_picker: OptionButton
var _hosting_meta_label: Label
var _hosting_cost_value: Label
var _logistics_btn: Button


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
	_build_context_hints()
	_build_hosting_controls()
	_refresh()
	Analytics.track_screen("finance")


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
	_hosting_plan_picker.custom_minimum_size = Vector2(170, 0)
	_hosting_plan_picker.add_item(CompanyData.HOSTING_PLAN_NAMES.get(CompanyData.HostingPlan.MANAGED_CLOUD, "Managed Cloud"))
	_hosting_plan_picker.add_item(CompanyData.HOSTING_PLAN_NAMES.get(CompanyData.HostingPlan.HYBRID, "Hybrid"))
	_hosting_plan_picker.add_item(CompanyData.HOSTING_PLAN_NAMES.get(CompanyData.HostingPlan.IN_HOUSE, "In-house"))
	_hosting_plan_picker.item_selected.connect(_on_hosting_plan_selected)
	row.add_child(_hosting_plan_picker)

	_logistics_btn = Button.new()
	_logistics_btn.text = "Open Logistics"
	_logistics_btn.custom_minimum_size = Vector2(120, 0)
	_logistics_btn.pressed.connect(_on_open_logistics)
	row.add_child(_logistics_btn)

	vbox.add_child(row)
	vbox.move_child(row, cash_value.get_parent().get_index() + 3)

	_hosting_meta_label = Label.new()
	_hosting_meta_label.add_theme_font_size_override("font_size", 11)
	_hosting_meta_label.add_theme_color_override("font_color", Color(0.62, 0.67, 0.82))
	_hosting_meta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_hosting_meta_label)
	vbox.move_child(_hosting_meta_label, cash_value.get_parent().get_index() + 4)

	var hosting_title := Label.new()
	hosting_title.text = "Hosting"
	costs_grid.add_child(hosting_title)
	_hosting_cost_value = Label.new()
	_hosting_cost_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hosting_cost_value.text = "$0"
	costs_grid.add_child(_hosting_cost_value)


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
		runway_value.add_theme_color_override("font_color", Color(0.3, 0.85, 0.4))
	elif rw < 1.0:
		runway_value.text = "Critical — less than 1 quarter"
		runway_value.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	elif rw < 3.0:
		runway_value.text = "~%d quarters — start fundraising" % roundi(rw)
		runway_value.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2))
	else:
		runway_value.text = "~%d quarters" % roundi(rw)
		runway_value.add_theme_color_override("font_color", Color(0.3, 0.85, 0.4))

	var costs: Dictionary = GameState.financials.costs_breakdown
	salary_cost.text = "$%s" % SceneLoader.format_money(costs.get("salaries", 0.0))
	infra_cost.text = "$%s" % SceneLoader.format_money(costs.get("infrastructure", 0.0))
	office_cost.text = "$%s" % SceneLoader.format_money(costs.get("office", 0.0))
	if _hosting_cost_value:
		_hosting_cost_value.text = "$%s" % SceneLoader.format_money(costs.get("hosting", 0.0))
	_refresh_hosting_controls()
	_refresh_context_hints(rw)
	_refresh_trend_chart()
	_refresh_health_trend_chart()

	if GameState.financials.funding_rounds.is_empty():
		board_label.visible = false
	else:
		board_label.visible = true
		var bp: int = GameState.board_patience
		if bp >= 5:
			board_label.text = "Board: Satisfied"
			board_label.add_theme_color_override("font_color", Color(0.3, 0.85, 0.4))
		elif bp >= 3:
			board_label.text = "Board: Watching closely"
			board_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2))
		elif bp >= 2:
			board_label.text = "Board: Impatient"
			board_label.add_theme_color_override("font_color", Color(0.95, 0.5, 0.2))
		else:
			board_label.text = "Board: Furious — your position is at risk"
			board_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))


func _refresh_context_hints(runway_quarters: float) -> void:
	_refresh_quarter_delta_hint()
	_refresh_next_move_hint(runway_quarters)


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
	_hosting_meta_label.text = "%s · Reliability %.1f%% · Web %.0f%% · Cache %.0f%% · Data %.0f%% · Overage $%s" % [
		GameState.company.hosting_plan_name(),
		GameState.company.hosting_reliability,
		GameState.company.hosting_util_web * 100.0,
		GameState.company.hosting_util_cache * 100.0,
		GameState.company.hosting_util_data * 100.0,
		SceneLoader.format_money(GameState.company.hosting_overage_cost),
	]
	if GameState.company.hosting_reliability < 93.0 or peak_util > 1.15:
		_hosting_meta_label.add_theme_color_override("font_color", Color(0.95, 0.56, 0.45))
	elif GameState.company.hosting_reliability < 97.0 or peak_util > 0.95:
		_hosting_meta_label.add_theme_color_override("font_color", Color(0.95, 0.8, 0.4))
	else:
		_hosting_meta_label.add_theme_color_override("font_color", Color(0.62, 0.82, 0.62))


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


func _refresh_next_move_hint(runway_quarters: float) -> void:
	if _next_move_label == null:
		return
	var hint: String
	if GameState.company.hosting_reliability < 93.0:
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


func _trend_points(limit: int = 12) -> Array[Dictionary]:
	var points: Array[Dictionary] = []
	for item in GameState.history:
		if item is Dictionary:
			points.append(item)

	var live_point := {
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
	var users_series: Array[float] = []
	for p in points:
		cash_series.append(float(p.get("cash", 0.0)))
		revenue_series.append(float(p.get("revenue", 0.0)))
		users_series.append(float(p.get("users", 0.0)))

	if trend_chart.has_method("set_series"):
		trend_chart.set_series(cash_series, revenue_series, users_series)

	if trend_meta:
		var n := points.size()
		trend_meta.text = "Last %d quarter%s (normalized per metric)" % [n, "s" if n != 1 else ""]


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
		health_trend_chart.set_series(valuation_series, team_series, morale_series)

	if health_trend_meta:
		var n := points.size()
		health_trend_meta.text = "Last %d quarter%s (valuation / team / morale)" % [n, "s" if n != 1 else ""]


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
		var header := "%s\n%s" % [firm_name, style] if not style.is_empty() else firm_name
		offer_label.text = "%s\n\nYou pitched your %s round.\n\n\"%s\"\n\nTry again next quarter — or build more traction first." % [header, o["round"], reason]
		accept_btn.visible = false
		decline_btn.text = "Back to It"
		offer_panel.visible = true
		fundraise_btn.visible = false
		return

	var firm_name: String = o.get("firm_name", "Investors")
	var style: String = o.get("firm_style", "")
	var tier: String = o.get("tier", "mid")

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

	offer_label.text = "%s%s\n\n%s Round\n\nOffering $%s at a $%s pre-money valuation.\n\nYou'd give up %.1f%% of the company.%s" % [
		header, tier_label,
		o["round"],
		SceneLoader.format_money(o["amount"]),
		SceneLoader.format_money(o["valuation"]),
		o["dilution"],
		board_note,
	]
	accept_btn.visible = true
	decline_btn.text = "Walk Away"
	offer_panel.visible = true
	fundraise_btn.visible = false


func _on_accept_offer() -> void:
	if _current_offer.get("rejected", false):
		return
	var firm_name: String = _current_offer.get("firm_name", "unknown")
	var amount: float = _current_offer.get("amount", 0.0)
	Analytics.track_fundraise_result(true, firm_name, amount)
	FundraisingEngine.accept_offer(GameState, _current_offer)
	offer_panel.visible = false
	fundraise_btn.visible = true
	fundraise_btn.text = "Raise Another Round"
	_refresh()


func _on_decline_offer() -> void:
	var firm_name: String = _current_offer.get("firm_name", "unknown")
	Analytics.track_fundraise_result(false, firm_name, 0.0)
	offer_panel.visible = false
	fundraise_btn.visible = true
	fundraise_btn.text = "Talk to Investors"


func _on_back() -> void:
	SceneLoader.goto_scene("res://src/ui/dashboard/quarter_dashboard.tscn")


