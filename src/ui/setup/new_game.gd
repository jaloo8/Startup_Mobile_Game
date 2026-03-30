extends Control

@onready var name_input: LineEdit = %CompanyNameInput
@onready var type_selector: OptionButton = %TypeSelector
@onready var difficulty_selector: OptionButton = %DifficultySelector
@onready var scenario_selector: OptionButton = %ScenarioSelector
@onready var background_selector: OptionButton = %BackgroundSelector
@onready var background_desc: Label = %BackgroundDesc
@onready var stat_preview: Label = %StatPreview
@onready var start_btn: Button = %StartButton
@onready var back_btn: Button = %BackButton
@onready var type_illustration_label: Label = %TypeIllustrationLabel

const TYPE_ILLUSTRATION_LABELS := {
	CompanyData.CompanyType.SAAS: "SaaS — Cloud dashboard illustration",
	CompanyData.CompanyType.CONSUMER: "Consumer — Phone app illustration",
	CompanyData.CompanyType.MARKETPLACE: "Marketplace — Shopping illustration",
	CompanyData.CompanyType.DEV_TOOLS: "Dev Tools — Terminal illustration",
}

# Difficulty plain-English descriptions shown below the selector
const DIFFICULTY_DESCS := {
	0: "Sandbox — Extra starting cash, slower competitors, forgiving market. Great for learning the game with no pressure.",
	1: "Normal — Realistic startup economics. Tight budget, real competition. Recommended for most players.",
	2: "Hardcore — Minimal runway, aggressive competitors, realistic failure rates. For experienced players.",
}

# Dynamically created description labels
var _type_hint_label: Label
var _difficulty_desc_label: Label


func _ready() -> void:
	_populate_type_selector()
	_populate_difficulty_selector()
	_populate_scenario_selector()
	_populate_background_selector()
	start_btn.pressed.connect(_on_start)
	back_btn.pressed.connect(_on_back)
	background_selector.item_selected.connect(_on_background_changed)
	type_selector.item_selected.connect(_on_type_changed)
	difficulty_selector.item_selected.connect(_on_difficulty_changed)

	_build_type_hint_label()
	_build_difficulty_desc_label()

	_on_background_changed(0)
	_on_type_changed(0)
	_on_difficulty_changed(1)  # default is Normal


func _build_type_hint_label() -> void:
	_type_hint_label = Label.new()
	_type_hint_label.add_theme_font_size_override("font_size", 12)
	_type_hint_label.add_theme_color_override("font_color", Color(0.55, 0.8, 0.95))
	_type_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var parent := type_selector.get_parent()
	if parent:
		parent.add_child(_type_hint_label)
		parent.move_child(_type_hint_label, type_selector.get_index() + 1)


func _build_difficulty_desc_label() -> void:
	_difficulty_desc_label = Label.new()
	_difficulty_desc_label.add_theme_font_size_override("font_size", 12)
	_difficulty_desc_label.add_theme_color_override("font_color", Color(0.65, 0.65, 0.7))
	_difficulty_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var parent := difficulty_selector.get_parent()
	if parent:
		parent.add_child(_difficulty_desc_label)
		parent.move_child(_difficulty_desc_label, difficulty_selector.get_index() + 1)


func _on_type_changed(_idx: int) -> void:
	var type_id: int = type_selector.get_selected_id()
	# PLACEHOLDER: Replace label text with actual illustration per type
	type_illustration_label.text = TYPE_ILLUSTRATION_LABELS.get(type_id, "Company Illustration")

	if _type_hint_label == null:
		return
	match type_id:
		CompanyData.CompanyType.CONSUMER:
			_type_hint_label.text = "★ Recommended for new players — familiar products like streaming, social apps, or fitness tools. Easy to understand, fun to grow."
			_type_hint_label.add_theme_color_override("font_color", Color(0.95, 0.8, 0.25))
		CompanyData.CompanyType.SAAS:
			_type_hint_label.text = "Business software sold by subscription (e.g. project management, CRM). Slower growth but sticky customers and steady revenue."
			_type_hint_label.add_theme_color_override("font_color", Color(0.55, 0.8, 0.95))
		CompanyData.CompanyType.MARKETPLACE:
			_type_hint_label.text = "Connect buyers and sellers (e.g. food delivery, rentals). Tricky chicken-and-egg problem early on — harder start, big reward."
			_type_hint_label.add_theme_color_override("font_color", Color(0.55, 0.8, 0.95))
		CompanyData.CompanyType.DEV_TOOLS:
			_type_hint_label.text = "Tools for developers (e.g. APIs, hosting, CI/CD). Niche but highly loyal users. Best for players with some tech background."
			_type_hint_label.add_theme_color_override("font_color", Color(0.55, 0.8, 0.95))
		_:
			_type_hint_label.text = ""


func _on_difficulty_changed(idx: int) -> void:
	if _difficulty_desc_label == null:
		return
	_difficulty_desc_label.text = DIFFICULTY_DESCS.get(idx, "")


func _populate_type_selector() -> void:
	type_selector.clear()
	type_selector.add_item("SaaS B2B Tool", CompanyData.CompanyType.SAAS)
	type_selector.add_item("Consumer App  ★", CompanyData.CompanyType.CONSUMER)
	type_selector.add_item("Marketplace / Platform", CompanyData.CompanyType.MARKETPLACE)
	type_selector.add_item("Dev Tools / Infrastructure", CompanyData.CompanyType.DEV_TOOLS)
	# Default to Consumer App for new players
	type_selector.select(1)


func _populate_difficulty_selector() -> void:
	difficulty_selector.clear()
	difficulty_selector.add_item("Sandbox")
	difficulty_selector.add_item("Normal")
	difficulty_selector.add_item("Hardcore")
	difficulty_selector.select(1)


func _populate_scenario_selector() -> void:
	scenario_selector.clear()
	scenario_selector.add_item("Garage Bootstrapper ($20K)")
	scenario_selector.add_item("Accelerator Graduate ($125K)")
	scenario_selector.add_item("Corporate Spinoff ($500K)")
	scenario_selector.add_item("VC-Backed ($2M)")


func _populate_background_selector() -> void:
	background_selector.clear()
	for bg_key: int in CompanyData.FOUNDER_ARCHETYPES:
		var arch: Dictionary = CompanyData.FOUNDER_ARCHETYPES[bg_key]
		background_selector.add_item(arch["name"], bg_key)


func _on_background_changed(_idx: int) -> void:
	var bg_id: int = background_selector.get_selected_id()
	var arch: Dictionary = CompanyData.FOUNDER_ARCHETYPES.get(bg_id, {})
	background_desc.text = arch.get("desc", "")
	var stats: Dictionary = arch.get("stats", {})
	stat_preview.text = "Tech %d  |  Finance %d  |  People %d  |  Business %d" % [
		stats.get("technical", 5),
		stats.get("finance", 5),
		stats.get("people", 5),
		stats.get("business", 5),
	]


func _on_start() -> void:
	var scenarios := ["garage", "accelerator", "spinoff", "vc_backed"]
	var difficulties := ["sandbox", "normal", "hardcore"]

	var diff_idx := clampi(difficulty_selector.selected, 0, difficulties.size() - 1)
	var scen_idx := clampi(scenario_selector.selected, 0, scenarios.size() - 1)

	var bg_id: int = background_selector.get_selected_id()

	var config := {
		"name": name_input.text.strip_edges() if not name_input.text.strip_edges().is_empty() else "My Startup",
		"type": type_selector.get_selected_id(),
		"difficulty": difficulties[diff_idx],
		"scenario": scenarios[scen_idx],
		"founder_background": bg_id,
	}

	GameState.new_game(config)
	EventEngine.load_events("res://src/data/events.json")
	ProductData.load_feature_catalog("res://src/data/features.json")
	HeadlineEngine.load_headlines("res://src/data/headlines.json")
	GameState.market.competitors = CompetitorAI.generate_starting_competitors(6, GameState.company.type)
	GameState.save_game(GameState.current_slot)

	Analytics.track_new_game(
		CompanyData.TYPE_NAMES.get(config["type"], "unknown"),
		config["difficulty"],
		config["scenario"],
	)
	SceneLoader.goto_scene("res://src/ui/dashboard/quarter_dashboard.tscn")


func _on_back() -> void:
	SceneLoader.goto_scene("res://src/ui/saves/save_slots.tscn")
