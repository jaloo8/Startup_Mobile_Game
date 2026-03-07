extends Control
## Main gameplay screen — the hub each quarter.
## Player navigates to People/Product/Finance from here, then advances.

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
@onready var event_popup: EventPopup = %EventPopup

const MAX_VISIBLE_EVENTS := 10

var _pending_events: Array[EventData] = []


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
	GameState.event_triggered.connect(_on_event)

	_refresh(GameState.current_quarter)


func _wire_glossary_button(btn: Button, glossary_key: String) -> void:
	btn.pressed.connect(Glossary.show_term.bind(glossary_key))


func _exit_tree() -> void:
	_safe_disconnect(GameState.quarter_advanced, _refresh)
	_safe_disconnect(GameState.game_over, _on_game_over)
	_safe_disconnect(GameState.event_triggered, _on_event)


func _refresh(_q: int) -> void:
	if GameState.company == null:
		return
	quarter_label.text = "Year %d, Q%d" % [GameState.current_year, GameState.current_quarter]
	company_label.text = "%s — %s" % [GameState.company.company_name, GameState.company.type_name()]
	cash_label.text = "$%s" % format_money(GameState.company.cash)
	users_label.text = "%s users" % format_number(GameState.product.users)
	employees_label.text = "%d / %d" % [GameState.employees.size(), GameState.company.office_capacity()]
	revenue_label.text = "$%s" % format_money(GameState.financials.revenue)
	burn_label.text = "$%s" % format_money(GameState.financials.burn_rate)

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
	_free_children(event_log_container)
	_pending_events.clear()
	GameState.advance_quarter()

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
	advance_btn.disabled = true
	advance_btn.text = "Game Over"
	var display_reason: String = GAME_OVER_MESSAGES.get(reason, reason.replace("_", " ").capitalize())
	quarter_label.text = display_reason


func _on_people() -> void:
	SceneLoader.goto_scene("res://src/ui/people/employee_list.tscn")


func _on_product() -> void:
	SceneLoader.goto_scene("res://src/ui/product/product_overview.tscn")


func _on_finance() -> void:
	SceneLoader.goto_scene("res://src/ui/finance/finance_overview.tscn")


func _on_market() -> void:
	SceneLoader.goto_scene("res://src/ui/market/market_leaderboard.tscn")


func _on_menu() -> void:
	if not GameState.current_slot.is_empty():
		GameState.save_game(GameState.current_slot)
	SceneLoader.goto_scene("res://src/ui/main_menu/main_menu.tscn")


static func format_money(amount: float) -> String:
	if absf(amount) >= 1_000_000:
		return "%.1fM" % (amount / 1_000_000)
	elif absf(amount) >= 1_000:
		return "%.0fK" % (amount / 1_000)
	return "%.0f" % amount


static func format_number(n: int) -> String:
	if n >= 1_000_000:
		return "%.1fM" % (n / 1_000_000.0)
	elif n >= 1_000:
		return "%.1fK" % (n / 1_000.0)
	return str(n)


func _safe_disconnect(sig: Signal, callable: Callable) -> void:
	if sig.is_connected(callable):
		sig.disconnect(callable)


static func _free_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
