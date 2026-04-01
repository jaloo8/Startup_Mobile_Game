extends Control
## Victory screen — shown when the player wins via any of the 4 win conditions.

@onready var win_title: Label = %WinTitle
@onready var win_subtitle: Label = %WinSubtitle
@onready var stats_label: Label = %StatsLabel
@onready var timeline_container: VBoxContainer = %TimelineContainer
@onready var continue_btn: Button = %ContinueButton
@onready var menu_btn: Button = %MenuButton
@onready var new_game_btn: Button = %NewGameButton

const WIN_DATA := {
	"ipo": {
		"title": "IPO",
		"subtitle": "You took %s public.",
		"flavor": "The bell rings on the trading floor. Your stock symbol flashes across every financial news screen in the world. You did it.",
	},
	"acquisition": {
		"title": "Acquired",
		"subtitle": "%s has been acquired.",
		"flavor": "The deal is done. Your team gets payouts. Some cry, some cheer, some do both. It's bittersweet — but it's a win.",
	},
	"sustainable": {
		"title": "Sustainable Business",
		"subtitle": "%s is profitable and self-sustaining.",
		"flavor": "No more fundraising. No more runway anxiety. You built something that pays for itself. Most founders never get here.",
	},
	"unicorn": {
		"title": "Unicorn",
		"subtitle": "%s is valued at over $1 Billion.",
		"flavor": "The mythical creature is real. $1B valuation. Magazine covers. Conference keynotes. The garage feels like a lifetime ago.",
	},
}


func _ready() -> void:
	continue_btn.pressed.connect(_on_continue)
	menu_btn.pressed.connect(_on_menu)
	new_game_btn.pressed.connect(_on_new_game)
	Analytics.track_screen("victory")

	var win_type: String = GameState.get_meta("win_type", "ipo") if GameState.has_meta("win_type") else "ipo"
	var data: Dictionary = WIN_DATA.get(win_type, WIN_DATA["ipo"])
	var company_name: String = GameState.company.company_name if GameState.company else "Your Company"

	win_title.text = data["title"]
	win_subtitle.text = data["subtitle"] % company_name

	var quarters: int = GameState.total_quarters_elapsed()
	var years: int = quarters / 4
	var remaining_q: int = quarters % 4
	var time_text := ""
	if years > 0:
		time_text = "%d year%s" % [years, "s" if years != 1 else ""]
		if remaining_q > 0:
			time_text += ", %d quarter%s" % [remaining_q, "s" if remaining_q != 1 else ""]
	else:
		time_text = "%d quarter%s" % [remaining_q, "s" if remaining_q != 1 else ""]

	stats_label.text = "%s\n\nTime: %s\nFinal valuation: $%s\nRevenue: $%s per quarter\nUsers: %s\nTeam: %d people\nEquity retained: %d%%\nFeatures shipped: %d" % [
		data["flavor"],
		time_text,
		SceneLoader.format_money(GameState.company.valuation if GameState.company else 0.0),
		SceneLoader.format_money(GameState.financials.revenue if GameState.financials else 0.0),
		SceneLoader.format_number(GameState.product.users if GameState.product else 0),
		GameState.employees.size(),
		roundi(GameState.company.equity_owned) if GameState.company else 0,
		GameState.product.feature_count() if GameState.product else 0,
	]

	_build_timeline()


func _build_timeline() -> void:
	for child in timeline_container.get_children():
		timeline_container.remove_child(child)
		child.queue_free()

	var key_moments: Array[Dictionary] = []
	for entry: Dictionary in GameState.event_log:
		var eid: String = entry.get("event_id", "")
		if eid.begins_with("milestone_") or eid == "angel_bailout" or eid == "acquisition_offer":
			key_moments.append(entry)

	if key_moments.is_empty():
		var lbl := Label.new()
		lbl.text = "A quiet journey — but you made it."
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
		timeline_container.add_child(lbl)
		return

	for moment: Dictionary in key_moments:
		var lbl := Label.new()
		var yr: int = moment.get("year", 1)
		var qt: int = moment.get("quarter", 1)
		lbl.text = "Y%d Q%d — %s" % [yr, qt, moment.get("title", "")]
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.6, 0.75, 0.6))
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		timeline_container.add_child(lbl)


func _on_menu() -> void:
	SceneLoader.goto_scene("res://src/ui/main_menu/main_menu.tscn")


func _on_continue() -> void:
	GameState.continue_after_victory()
	SceneLoader.goto_scene("res://src/ui/dashboard/quarter_dashboard.tscn")


func _on_new_game() -> void:
	SceneLoader.goto_scene("res://src/ui/saves/save_slots.tscn")


