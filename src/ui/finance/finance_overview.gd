extends Control
## Finance screen — costs, revenue, runway, equity.

@onready var cash_value: Label = %CashValue
@onready var revenue_value: Label = %RevenueValue
@onready var burn_value: Label = %BurnValue
@onready var runway_value: Label = %RunwayValue
@onready var equity_value: Label = %EquityValue
@onready var valuation_value: Label = %ValuationValue
@onready var trend_chart: Control = %TrendChart
@onready var trend_meta: Label = %TrendMeta

@onready var salary_cost: Label = %SalaryCost
@onready var infra_cost: Label = %InfraCost
@onready var office_cost: Label = %OfficeCost

@onready var board_label: Label = %BoardLabel
@onready var back_btn: Button = %BackButton
@onready var fundraise_btn: Button = %FundraiseButton
@onready var offer_panel: PanelContainer = %OfferPanel
@onready var offer_label: Label = %OfferLabel
@onready var accept_btn: Button = %AcceptButton
@onready var decline_btn: Button = %DeclineButton

var _current_offer: Dictionary = {}


func _ready() -> void:
	back_btn.pressed.connect(_on_back)
	fundraise_btn.pressed.connect(_on_fundraise)
	accept_btn.pressed.connect(_on_accept_offer)
	decline_btn.pressed.connect(_on_decline_offer)
	offer_panel.visible = false

	_wire_glossary(%CashTitle, "runway")
	_wire_glossary(%RevenueTitle, "ARR")
	_wire_glossary(%BurnTitle, "burn_rate")
	_wire_glossary(%RunwayTitle, "runway")
	_wire_glossary(%EquityTitle, "equity")
	_wire_glossary(%ValuationTitle, "valuation")
	_refresh()
	Analytics.track_screen("finance")


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
	_refresh_trend_chart()

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


func _wire_glossary(btn: Button, key: String) -> void:
	btn.pressed.connect(Glossary.show_term.bind(key))


func _refresh_trend_chart() -> void:
	if trend_chart == null:
		return

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
	}
	if points.is_empty():
		points.append(live_point)
	else:
		var last: Dictionary = points[-1]
		var same_period := int(last.get("quarter", -1)) == GameState.current_quarter \
			and int(last.get("year", -1)) == GameState.current_year
		var same_values := is_equal_approx(float(last.get("cash", -1.0)), GameState.company.cash) \
			and is_equal_approx(float(last.get("revenue", -1.0)), GameState.financials.revenue) \
			and int(last.get("users", -1)) == GameState.product.users
		if not (same_period and same_values):
			points.append(live_point)

	if points.size() > 12:
		points = points.slice(-12)

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


