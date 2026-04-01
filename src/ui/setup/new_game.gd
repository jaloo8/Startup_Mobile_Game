extends Control

@onready var name_input: LineEdit = %CompanyNameInput
@onready var type_selector: OptionButton = %TypeSelector
@onready var niche_selector: OptionButton = %NicheSelector
@onready var niche_desc: Label = %NicheDesc
@onready var difficulty_selector: OptionButton = %DifficultySelector
@onready var scenario_selector: OptionButton = %ScenarioSelector
@onready var background_selector: OptionButton = %BackgroundSelector
@onready var background_desc: Label = %BackgroundDesc
@onready var stat_preview: Label = %StatPreview
@onready var start_btn: Button = %StartButton
@onready var back_btn: Button = %BackButton
@onready var type_illustration: TextureRect = %TypeIllustration

const TYPE_ILLUSTRATION_PATHS := {
	CompanyData.CompanyType.SAAS:        "res://assets/illustrations/company_type_saas.png",
	CompanyData.CompanyType.CONSUMER:    "res://assets/illustrations/company_type_consumer.png",
	CompanyData.CompanyType.MARKETPLACE: "res://assets/illustrations/company_type_marketplace.png",
	CompanyData.CompanyType.DEV_TOOLS:   "res://assets/illustrations/company_type_devtools.png",
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
	CompanyData.load_niche_catalog()
	_populate_type_selector()
	_populate_difficulty_selector()
	_populate_scenario_selector()
	_populate_background_selector()
	start_btn.pressed.connect(_on_start)
	back_btn.pressed.connect(_on_back)
	background_selector.item_selected.connect(_on_background_changed)
	type_selector.item_selected.connect(_on_type_changed)
	niche_selector.item_selected.connect(_on_niche_changed)
	difficulty_selector.item_selected.connect(_on_difficulty_changed)

	_build_type_hint_label()
	_build_difficulty_desc_label()

	_on_background_changed(0)
	_on_type_changed(1)         # Consumer App is the default (index 1)
	_on_niche_changed(0)
	_on_difficulty_changed(1)   # Normal is the default


func _load_type_illustration(type_id: int) -> void:
	if type_illustration == null:
		return
	var path: String = TYPE_ILLUSTRATION_PATHS.get(type_id, "")
	if path.is_empty() or not ResourceLoader.exists(path):
		type_illustration.texture = null
		return
	# Load asynchronously so the UI doesn't hitch on slower devices
	var tex := load(path) as Texture2D
	type_illustration.texture = tex
	# Fade in for a polished feel
	type_illustration.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(type_illustration, "modulate:a", 1.0, 0.25)


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
	_load_type_illustration(type_id)
	_populate_niche_selector(type_id)

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


func _populate_niche_selector(type_id: int) -> void:
	if niche_selector == null:
		return
	var previous_id := niche_selector.get_selected_id()
	niche_selector.clear()
	var rows := CompanyData.niches_for_type(type_id)
	if rows.is_empty():
		niche_selector.add_item("General", 0)
		niche_desc.text = "Default niche with balanced modifiers."
		return

	var fallback_idx := 0
	var preferred_idx := -1
	for i in rows.size():
		var row: Dictionary = rows[i]
		var label := str(row.get("name", "Unknown Niche"))
		var row_id := str(row.get("id", ""))
		if bool(row.get("recommended", false)):
			label += "  ★"
			fallback_idx = i
		niche_selector.add_item(label, i)
		niche_selector.set_item_metadata(i, row_id)
		if previous_id == i:
			preferred_idx = i

	if preferred_idx >= 0:
		niche_selector.select(preferred_idx)
	else:
		niche_selector.select(fallback_idx)
	_on_niche_changed(niche_selector.selected)


func _on_niche_changed(_idx: int) -> void:
	var type_id := type_selector.get_selected_id()
	var rows := CompanyData.niches_for_type(type_id)
	if rows.is_empty():
		niche_desc.text = "Default niche with balanced modifiers."
		return
	var safe_idx := clampi(niche_selector.selected, 0, rows.size() - 1)
	var row: Dictionary = rows[safe_idx]
	var mods: Dictionary = row.get("modifiers", {})
	var growth_pct := roundi((float(mods.get("growth_mult", 1.0)) - 1.0) * 100.0)
	var churn_pct := roundi((float(mods.get("churn_mult", 1.0)) - 1.0) * 100.0)
	var revenue_pct := roundi((float(mods.get("revenue_mult", 1.0)) - 1.0) * 100.0)
	niche_desc.text = "%s\nGrowth %+d%% · Churn %+d%% · Revenue %+d%%" % [
		str(row.get("description", "")),
		growth_pct,
		churn_pct,
		revenue_pct,
	]


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
	start_btn.disabled = true
	var gs := get_node_or_null("/root/GameState")
	if gs == null:
		push_error("NewGame: GameState autoload missing; cannot start company")
		start_btn.disabled = false
		return

	var scenarios := ["garage", "accelerator", "spinoff", "vc_backed"]
	var difficulties := ["sandbox", "normal", "hardcore"]

	var diff_idx := clampi(difficulty_selector.selected, 0, difficulties.size() - 1)
	var scen_idx := clampi(scenario_selector.selected, 0, scenarios.size() - 1)

	var bg_id: int = background_selector.get_selected_id()
	var niche_id := ""
	if niche_selector != null and niche_selector.item_count > 0 and niche_selector.selected >= 0:
		var meta = niche_selector.get_item_metadata(niche_selector.selected)
		if meta != null:
			niche_id = str(meta)

	var config := {
		"name": name_input.text.strip_edges() if not name_input.text.strip_edges().is_empty() else "My Startup",
		"type": type_selector.get_selected_id(),
		"niche_id": niche_id,
		"difficulty": difficulties[diff_idx],
		"scenario": scenarios[scen_idx],
		"founder_background": bg_id,
	}

	if GameState.current_slot.is_empty():
		GameState.current_slot = "slot_1"

	GameState.new_game(config)
	EventEngine.load_events("res://src/data/events.json")
	ProductData.load_feature_catalog("res://src/data/features.json")
	HeadlineEngine.load_headlines("res://src/data/headlines.json")
	GameState.market.competitors = CompetitorAI.generate_starting_competitors(6, GameState.company.type)
	GameState.save_game(GameState.current_slot)

	var analytics := get_node_or_null("/root/Analytics")
	if analytics != null and analytics.has_method("track_new_game"):
		analytics.call(
			"track_new_game",
			CompanyData.TYPE_NAMES.get(config["type"], "unknown"),
			config["difficulty"],
			config["scenario"],
		)
	var err := get_tree().change_scene_to_file("res://src/ui/dashboard/quarter_dashboard.tscn")
	if err != OK:
		push_error("NewGame: failed to open dashboard scene (err=%d)" % err)
		start_btn.disabled = false


func _on_back() -> void:
	# Temporary gameplay-first flow: return to main menu instead of save slots.
	SceneLoader.goto_scene("res://src/ui/main_menu/main_menu.tscn")
