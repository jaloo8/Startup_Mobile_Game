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
@onready var menu_btn: Button = %MenuButton
@onready var event_log_container: VBoxContainer = %EventLogContainer

const MAX_VISIBLE_EVENTS := 10


func _ready() -> void:
	advance_btn.pressed.connect(_on_advance)
	people_btn.pressed.connect(_on_people)
	product_btn.pressed.connect(_on_product)
	menu_btn.pressed.connect(_on_menu)

	GameState.quarter_advanced.connect(_refresh)
	GameState.game_over.connect(_on_game_over)
	GameState.event_triggered.connect(_on_event)

	_refresh(GameState.current_quarter)


func _exit_tree() -> void:
	_safe_disconnect(GameState.quarter_advanced, _refresh)
	_safe_disconnect(GameState.game_over, _on_game_over)
	_safe_disconnect(GameState.event_triggered, _on_event)


func _refresh(_q: int) -> void:
	if GameState.company == null:
		return
	quarter_label.text = "Year %d, Q%d" % [GameState.current_year, GameState.current_quarter]
	company_label.text = "%s  •  %s" % [GameState.company.company_name, GameState.company.type_name()]
	cash_label.text = "$%s" % format_money(GameState.company.cash)
	users_label.text = "%s" % format_number(GameState.product.users)
	employees_label.text = "%d / %d" % [GameState.employees.size(), GameState.company.office_capacity()]
	revenue_label.text = "$%s" % format_money(GameState.financials.revenue)
	burn_label.text = "$%s" % format_money(GameState.financials.burn_rate)

	var rw: float = GameState.financials.runway_quarters(GameState.company.cash)
	if rw == INF or rw > 40:
		runway_label.text = "Plenty"
	elif rw < 0:
		runway_label.text = "In debt"
	elif rw < 2:
		runway_label.text = "%.1f quarters — critical" % rw
	else:
		runway_label.text = "%.1f quarters" % rw


func _on_event(event: EventData) -> void:
	while event_log_container.get_child_count() >= MAX_VISIBLE_EVENTS:
		var oldest := event_log_container.get_child(0)
		event_log_container.remove_child(oldest)
		oldest.queue_free()

	var title_label := Label.new()
	title_label.text = event.title
	title_label.add_theme_font_size_override("font_size", 15)
	title_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.4))
	event_log_container.add_child(title_label)

	var desc_text: String = EventEngine.resolve_event_text(event, GameState)
	if not desc_text.is_empty():
		var desc_label := Label.new()
		desc_label.text = desc_text
		desc_label.add_theme_font_size_override("font_size", 13)
		desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		event_log_container.add_child(desc_label)


func _on_advance() -> void:
	_free_children(event_log_container)
	GameState.advance_quarter()


const GAME_OVER_TEXT := {
	"bankruptcy": "You ran out of money.",
	"dead_product": "Your product lost all its users.",
	"founder_burnout": "You burned out.",
	"board_takeover": "The board replaced you.",
}

func _on_game_over(reason: String) -> void:
	advance_btn.disabled = true
	advance_btn.text = "Game Over"
	var message: String = GAME_OVER_TEXT.get(reason, "It's over.")
	quarter_label.text = message


func _on_people() -> void:
	SceneLoader.goto_scene("res://src/ui/people/employee_list.tscn")


func _on_product() -> void:
	SceneLoader.goto_scene("res://src/ui/product/product_overview.tscn")


func _on_menu() -> void:
	GameState.save_game("autosave")
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
