extends Control
## Shown when the player loses. Displays failure reason, stats, and options.

@onready var reason_label: Label = %ReasonLabel
@onready var stats_label: Label = %StatsLabel
@onready var angel_panel: PanelContainer = %AngelPanel
@onready var angel_title: Label = %AngelTitle
@onready var angel_flavor: Label = %AngelFlavor
@onready var angel_offer: Label = %AngelOffer
@onready var accept_angel_btn: Button = %AcceptAngelButton
@onready var decline_angel_btn: Button = %DeclineAngelButton
@onready var restart_btn: Button = %RestartButton
@onready var menu_btn: Button = %MenuButton

const GAME_OVER_MESSAGES := {
	"bankruptcy": "You Ran Out of Money",
	"dead_product": "Nobody's Using Your Product",
	"founder_burnout": "Founder Burnout",
	"board_takeover": "The Board Replaced You",
}

const ANGELS := [
	{
		"name": "Peer Gregor",
		"firm": "Gregor Ventures",
		"title_text": "An Angel Appears...",
		"equity_mult": 1.0,
		"amount_mult": 1.0,
		"quotes": [
			"I don't invest in people. I invest in ideas. Your idea is... adequate.",
			"Your company is failing. That makes this a buying opportunity.",
			"I once mass-shorted Icelandic bonds. I can certainly save your little startup.",
			"Most founders fail because they care about being liked. I don't have that problem. Neither should you.",
		],
	},
	{
		"name": "Ross Hahneman",
		"firm": "Tres Commas Capital",
		"title_text": "A McLaren Pulls Up...",
		"equity_mult": 1.3,
		"amount_mult": 1.5,
		"quotes": [
			"This guy fucks. Wait, wrong meeting. Anyway — you need money? I HAVE money. Three commas.",
			"I put radio on the internet. You think I can't save a little startup? Please.",
			"Know what's cooler than a billion dollars? Owning a piece of YOUR company. Actually no, a billion dollars is cooler. But I'll do both.",
			"My doors go like THIS. ↑ Not like this →. That's the kind of energy I'm bringing to your cap table.",
		],
	},
]

var _chosen_angel: Dictionary


func _ready() -> void:
	accept_angel_btn.pressed.connect(_on_accept_angel)
	decline_angel_btn.pressed.connect(_on_decline_angel)
	restart_btn.pressed.connect(_on_restart)
	menu_btn.pressed.connect(_on_menu)
	Analytics.track_screen("game_over")

	var reason: String = GameState.get_meta("game_over_reason", "bankruptcy") if GameState.has_meta("game_over_reason") else "bankruptcy"
	var display_reason: String = GAME_OVER_MESSAGES.get(reason, reason.replace("_", " ").capitalize())
	reason_label.text = display_reason

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

	stats_label.text = "%s survived %s\n\nFinal cash: $%s\nPeak users: %s\nTeam size: %d\nFeatures shipped: %d" % [
		GameState.company.company_name if GameState.company else "Your Company",
		time_text,
		_format_money(GameState.company.cash if GameState.company else 0.0),
		_format_number(_peak_users()),
		GameState.employees.size(),
		GameState.product.feature_count() if GameState.product else 0,
	]

	if GameState.angel_bailout_used:
		angel_panel.visible = false
	else:
		_chosen_angel = ANGELS.pick_random()
		angel_panel.visible = true
		angel_title.text = _chosen_angel["title_text"]
		var quotes: Array = _chosen_angel["quotes"]
		var quote: String = quotes.pick_random()
		angel_flavor.text = "\"%s\"\n— %s, %s" % [quote, _chosen_angel["name"], _chosen_angel["firm"]]
		var offer := _calculate_angel_offer()
		angel_offer.text = "Offers $%sK for %d%% equity" % [
			str(snapped(offer["amount"] / 1000.0, 0.1)),
			roundi(offer["equity"]),
		]


func _calculate_angel_offer() -> Dictionary:
	var quarters_survived: int = GameState.total_quarters_elapsed()
	var base_amount := 50_000.0
	if quarters_survived >= 8:
		base_amount = 150_000.0
	elif quarters_survived >= 4:
		base_amount = 100_000.0

	var equity_cost := 35.0
	if quarters_survived >= 8:
		equity_cost = 25.0
	elif quarters_survived >= 4:
		equity_cost = 30.0

	base_amount *= _chosen_angel.get("amount_mult", 1.0)
	equity_cost *= _chosen_angel.get("equity_mult", 1.0)

	return {"amount": base_amount, "equity": equity_cost}


func _on_accept_angel() -> void:
	var offer := _calculate_angel_offer()
	var angel_name: String = _chosen_angel.get("name", "unknown")
	Analytics.track_angel_decision(true, angel_name, offer["amount"])
	GameState.angel_bailout_used = true
	GameState.company.cash += offer["amount"]
	GameState.company.equity_owned -= offer["equity"]
	GameState.company.equity_owned = maxf(5.0, GameState.company.equity_owned)
	GameState.is_game_active = true

	GameState.append_event_log({
		"quarter": GameState.current_quarter,
		"year": GameState.current_year,
		"event_id": "angel_bailout",
		"title": "%s invested $%sK for %d%% equity" % [
			angel_name,
			str(snapped(offer["amount"] / 1000.0, 0.1)),
			roundi(offer["equity"]),
		],
	})
	GameState.auto_save()
	SceneLoader.goto_scene("res://src/ui/dashboard/quarter_dashboard.tscn")


func _on_decline_angel() -> void:
	var angel_name: String = _chosen_angel.get("name", "unknown")
	Analytics.track_angel_decision(false, angel_name, 0.0)
	angel_panel.visible = false


func _on_restart() -> void:
	SceneLoader.goto_scene("res://src/ui/saves/save_slots.tscn")


func _on_menu() -> void:
	SceneLoader.goto_scene("res://src/ui/main_menu/main_menu.tscn")


func _peak_users() -> int:
	var peak := 0
	for snap: Dictionary in GameState.history:
		var u: int = snap.get("users", 0)
		if u > peak:
			peak = u
	if GameState.product and GameState.product.users > peak:
		peak = GameState.product.users
	return peak


static func _format_money(amount: float) -> String:
	if absf(amount) >= 1_000_000:
		return "%.1fM" % (amount / 1_000_000)
	elif absf(amount) >= 1_000:
		return "%.0fK" % (amount / 1_000)
	return "%.0f" % amount


static func _format_number(n: int) -> String:
	if n >= 1_000_000:
		return "%.1fM" % (n / 1_000_000.0)
	elif n >= 1_000:
		return "%.1fK" % (n / 1_000.0)
	return str(n)
