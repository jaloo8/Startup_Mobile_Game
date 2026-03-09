extends Control
## Main gameplay screen.

@onready var quarter_label: Label = %QuarterLabel
@onready var company_label: Label = %CompanyLabel
@onready var cash_label: Label = %CashLabel
@onready var users_label: Label = %UsersLabel
@onready var runway_label: Label = %RunwayLabel
@onready var employees_label: Label = %EmployeesLabel
@onready var revenue_label: Label = %RevenueLabel
@onready var burn_label: Label = %BurnLabel
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
@onready var headline_label: Label = %HeadlineLabel
@onready var economy_label: Label = %EconomyLabel
@onready var energy_label: Label = %EnergyLabel
@onready var key_metric_title: Label = %KeyMetricTitle
@onready var key_metric_label: Label = %KeyMetricLabel
@onready var ticker_strip: Label = %TickerStrip

const MAX_VISIBLE_EVENTS := 10
const HEADLINE_ROTATE_SECONDS := 4.0

var _pending_events: Array[EventData] = []
var _headlines: Array[String] = []
var _headline_index: int = 0
var _headline_timer: Timer
var _prev_valuation: float = 0.0


func _ready() -> void:
	advance_btn.pressed.connect(_on_advance)
	people_btn.pressed.connect(_on_people)
	product_btn.pressed.connect(_on_product)
	finance_btn.pressed.connect(_on_finance)
	market_btn.pressed.connect(_on_market)
	menu_btn.pressed.connect(_on_menu)
	event_popup.event_resolved.connect(_on_event_resolved)

	_wire_glossary_button(%CashTitle, "runway")
	_wire_glossary_button(%RevenueTitle, "ARR")
	_wire_glossary_button(%BurnTitle, "burn_rate")
	_wire_glossary_button(%RunwayTitle, "runway")

	GameState.quarter_advanced.connect(_refresh)
	GameState.game_over.connect(_on_game_over)
	GameState.game_won.connect(_on_game_won)
	GameState.event_triggered.connect(_on_event)
	GameState.save_error.connect(_on_save_error)

	_headline_timer = Timer.new()
	_headline_timer.wait_time = HEADLINE_ROTATE_SECONDS
	_headline_timer.timeout.connect(_rotate_headline)
	add_child(_headline_timer)

	_refresh(GameState.current_quarter)
	Analytics.track_screen("dashboard")


func _wire_glossary_button(btn: Button, glossary_key: String) -> void:
	btn.pressed.connect(Glossary.show_term.bind(glossary_key))


func _exit_tree() -> void:
	_headline_timer.stop()
	_safe_disconnect(GameState.quarter_advanced, _refresh)
	_safe_disconnect(GameState.game_over, _on_game_over)
	_safe_disconnect(GameState.game_won, _on_game_won)
	_safe_disconnect(GameState.event_triggered, _on_event)
	_safe_disconnect(GameState.save_error, _on_save_error)


func _refresh(_q: int) -> void:
	if GameState.company == null:
		return
	quarter_label.text = "Year %d, Q%d" % [GameState.current_year, GameState.current_quarter]
	company_label.text = "%s — %s" % [GameState.company.company_name, GameState.company.type_name()]
	cash_label.text = "$%s" % SceneLoader.format_money(GameState.company.cash)
	users_label.text = "%s users" % SceneLoader.format_number(GameState.product.users)
	employees_label.text = "%d / %d" % [GameState.employees.size(), GameState.company.office_capacity()]
	revenue_label.text = "$%s" % SceneLoader.format_money(GameState.financials.revenue)
	burn_label.text = "$%s" % SceneLoader.format_money(GameState.financials.burn_rate)

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

	_refresh_headlines()
	_refresh_ticker_strip()
	_refresh_key_metric()
	_refresh_economy()
	_refresh_energy()
	_refresh_team()


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


func _on_advance() -> void:
	advance_btn.disabled = true
	SceneLoader.free_children(event_log_container)
	_pending_events.clear()
	Analytics.track_quarter_advanced(GameState.current_year, GameState.current_quarter)
	GameState.advance_quarter()
	Analytics.track_revenue(GameState.financials.revenue)

	_show_quarterly_report()

	AdManager.show_ad("interstitial_quarter_end")

	if not _pending_events.is_empty():
		advance_btn.disabled = true
		_show_next_event()
	else:
		advance_btn.disabled = false


func _show_next_event() -> void:
	if _pending_events.is_empty():
		advance_btn.disabled = false
		_refresh(GameState.current_quarter)
		return
	var ev: EventData = _pending_events[0]
	event_popup.show_event(ev)


func _on_event_resolved(_event: EventData, _choice_index: int) -> void:
	Analytics.track_event_choice(_event.id, _choice_index)
	if not _pending_events.is_empty():
		_pending_events.remove_at(0)
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
	GameState.set_meta("win_type", win_type)
	SceneLoader.goto_scene("res://src/ui/victory/victory_screen.tscn")


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
		var lbl := Label.new()
		var assign_name: String = EmployeeData.ASSIGNMENT_NAMES.get(emp.assignment, "Unassigned")
		lbl.text = "%s — %s · %s" % [emp.employee_name, emp.display_title(), assign_name]
		lbl.add_theme_font_size_override("font_size", 13)
		var morale_color: Color
		if emp.morale >= 70:
			morale_color = Color(0.55, 0.8, 0.55)
		elif emp.morale >= 40:
			morale_color = Color(0.85, 0.75, 0.35)
		else:
			morale_color = Color(0.9, 0.4, 0.35)
		lbl.add_theme_color_override("font_color", morale_color)
		team_container.add_child(lbl)


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


