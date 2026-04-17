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
@onready var founder_portrait: TextureRect = get_node_or_null("%FounderPortrait")

const TYPE_ILLUSTRATION_PATHS: Dictionary = {
	CompanyData.CompanyType.SAAS:        "res://assets/illustrations/company_type_saas.png",
	CompanyData.CompanyType.CONSUMER:    "res://assets/illustrations/company_type_consumer.png",
	CompanyData.CompanyType.MARKETPLACE: "res://assets/illustrations/company_type_marketplace.png",
	CompanyData.CompanyType.DEV_TOOLS:   "res://assets/illustrations/company_type_devtools.png",
}

const FOUNDER_PORTRAIT_PATHS: Dictionary = {
	CompanyData.FounderBackground.ENGINEER:  "res://assets/illustrations/founders/founder_engineer.png",
	CompanyData.FounderBackground.FINANCE:   "res://assets/illustrations/founders/founder_finance.png",
	CompanyData.FounderBackground.RECRUITER: "res://assets/illustrations/founders/founder_recruiter.png",
	CompanyData.FounderBackground.HUSTLER:   "res://assets/illustrations/founders/founder_hustler.png",
}

# Difficulty plain-English descriptions shown below the selector
const DIFFICULTY_DESCS: Dictionary = {
	0: "Sandbox — Extra starting cash, slower competitors, forgiving market. Great for learning the game with no pressure.",
	1: "Normal — Realistic startup economics. Tight budget, real competition. Recommended for most players.",
	2: "Hardcore — Minimal runway, aggressive competitors, realistic failure rates. For experienced players.",
}
const START_SCENARIOS: Array = [
	{
		"id": "garage",
		"label": "Garage Bootstrapper ($20K)",
		"desc": "Classic zero-to-one path. Tiny team, every decision matters.",
	},
	{
		"id": "accelerator",
		"label": "Accelerator Graduate ($125K)",
		"desc": "Small cushion and momentum, still very hands-on and scrappy.",
	},
	{
		"id": "spinoff",
		"label": "Corporate Spinoff ($500K)",
		"desc": "Faster start with a bit more structure and room to experiment.",
	},
	{
		"id": "vc_backed",
		"label": "VC-Backed ($2M)",
		"desc": "Strong runway, investor pressure, and higher growth expectations.",
	},
	{
		"id": "growth_operator",
		"label": "Growth Operator ($8M, mid-size team)",
		"desc": "Jump into an active scale-up with a functional org and existing users.",
	},
	{
		"id": "scale_chief",
		"label": "Scale Chief ($30M, large team)",
		"desc": "Start as a large company where role mesh and org discipline matter immediately.",
	},
]

# Dynamically created description labels
var _type_hint_label: Label
var _difficulty_desc_label: Label
var _scenario_desc_label: Label
var _premium_hint_label: Label  # "Unlock Premium" prompt below difficulty


func _ready() -> void:
	CompanyData.load_niche_catalog()
	name_input.max_length = 28
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
	scenario_selector.item_selected.connect(_on_scenario_changed)

	# Force OptionButton text to be visible — the root theme's font_color
	# doesn't always propagate to OptionButton in all Godot 4 builds.
	_force_option_button_colors()

	if OS.is_debug_build():
		print("[NewGame] _ready() — TypeSelector: items=%d selected=%d text='%s'" % [
			type_selector.item_count, type_selector.selected,
			type_selector.get_item_text(type_selector.selected) if type_selector.selected >= 0 else "NONE"])
		print("[NewGame]   DifficultySelector: items=%d selected=%d" % [
			difficulty_selector.item_count, difficulty_selector.selected])
		print("[NewGame]   ScenarioSelector: items=%d selected=%d" % [
			scenario_selector.item_count, scenario_selector.selected])
		print("[NewGame]   BackgroundSelector: items=%d selected=%d" % [
			background_selector.item_count, background_selector.selected])
		print("[NewGame]   TypeSelector modulate=%s visible=%s" % [
			type_selector.modulate, type_selector.visible])
		print("[NewGame]   TypeSelector self_modulate=%s" % type_selector.self_modulate)
		# Check if the root theme has OptionButton font_color set
		var root_theme: Theme = get_tree().root.theme if get_tree().root else null
		if root_theme:
			print("[NewGame]   Root theme has OptionButton font_color: %s" % root_theme.has_color("font_color", "OptionButton"))
			if root_theme.has_color("font_color", "OptionButton"):
				print("[NewGame]   Root theme OptionButton font_color = %s" % root_theme.get_color("font_color", "OptionButton"))
		else:
			print("[NewGame]   WARNING: No root theme found!")

	_build_type_hint_label()
	_build_difficulty_desc_label()
	_build_scenario_desc_label()

	_on_background_changed(0)
	_on_type_changed(1)         # Consumer App is the default (index 1)
	_on_niche_changed(0)
	_on_difficulty_changed(1)   # Normal is the default
	_on_scenario_changed(0)
	UITouchHelper.harden_tree(self)
	# TEMP DISABLED — diagnosing invisible OptionButton text.
	# var _form_container := type_selector.get_parent()
	# if _form_container:
	#	AnimHelper.stagger_list(_form_container, 0.04, 0.0, 18.0)


func _force_option_button_colors() -> void:
	# Explicit overrides ensure OptionButton text is always visible against the
	# dark background. Works around a Godot 4 theme propagation issue where
	# root-level theme font_color may not reach OptionButton internals.
	var text_color := ThemeManager.C_TEXT
	for btn: OptionButton in [type_selector, niche_selector, difficulty_selector,
			scenario_selector, background_selector]:
		if btn == null:
			continue
		btn.add_theme_color_override("font_color", text_color)
		btn.add_theme_color_override("font_hover_color", Color.WHITE)
		btn.add_theme_color_override("font_pressed_color", ThemeManager.C_BLUE)
		btn.add_theme_color_override("font_focus_color", text_color)


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


func _build_scenario_desc_label() -> void:
	_scenario_desc_label = Label.new()
	_scenario_desc_label.add_theme_font_size_override("font_size", 12)
	_scenario_desc_label.add_theme_color_override("font_color", Color(0.58, 0.78, 0.93))
	_scenario_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var parent := scenario_selector.get_parent()
	if parent:
		parent.add_child(_scenario_desc_label)
		parent.move_child(_scenario_desc_label, scenario_selector.get_index() + 1)


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
	if not _type_hint_label.text.is_empty():
		AnimHelper.fade_in(_type_hint_label, 0.0, 0.15)


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

	var selected_id: int = difficulty_selector.get_item_id(idx)

	# Free users tapped a locked difficulty — bounce them back to Sandbox
	# and show a friendly, emotion-driven upgrade prompt.
	if not _is_premium_safe() and selected_id > 0:
		difficulty_selector.select(0)  # Snap back to Sandbox
		_difficulty_desc_label.text = DIFFICULTY_DESCS.get(0, "")
		_show_premium_difficulty_prompt(selected_id)
		return

	# Hide premium hint when a valid selection is made
	if _premium_hint_label != null:
		_premium_hint_label.visible = false

	_difficulty_desc_label.text = DIFFICULTY_DESCS.get(selected_id, "")
	if not _difficulty_desc_label.text.is_empty():
		AnimHelper.fade_in(_difficulty_desc_label, 0.0, 0.15)


func _on_scenario_changed(_idx: int) -> void:
	if _scenario_desc_label == null:
		return
	if scenario_selector == null or scenario_selector.selected < 0:
		_scenario_desc_label.text = ""
		return
	var safe_idx: int = clampi(scenario_selector.selected, 0, START_SCENARIOS.size() - 1)
	_scenario_desc_label.text = str(START_SCENARIOS[safe_idx].get("desc", ""))
	if not _scenario_desc_label.text.is_empty():
		AnimHelper.fade_in(_scenario_desc_label, 0.0, 0.15)


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
	var is_premium: bool = _is_premium_safe()
	difficulty_selector.add_item("Sandbox", 0)
	if is_premium:
		difficulty_selector.add_item("Normal", 1)
		difficulty_selector.add_item("Hardcore", 2)
		difficulty_selector.select(1)  # Default to Normal for premium
	else:
		# Free users: show locked difficulties with lock icon so they can
		# see what they're missing (aspiration) without being able to select.
		difficulty_selector.add_item("Normal  🔒", 1)
		difficulty_selector.add_item("Hardcore  🔒", 2)
		difficulty_selector.select(0)  # Auto-select Sandbox — fewer decisions


func _populate_scenario_selector() -> void:
	scenario_selector.clear()
	for row in START_SCENARIOS:
		var label: String = str(row.get("label", "Scenario"))
		var sid: String = str(row.get("id", "garage"))
		scenario_selector.add_item(label)
		var idx: int = scenario_selector.item_count - 1
		scenario_selector.set_item_metadata(idx, sid)
	scenario_selector.select(0)


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
	_update_founder_portrait(bg_id)


func _update_founder_portrait(bg_id: int) -> void:
	if founder_portrait == null:
		return
	var path: String = FOUNDER_PORTRAIT_PATHS.get(bg_id, "")
	if path.is_empty() or not ResourceLoader.exists(path):
		founder_portrait.visible = false
		return
	founder_portrait.texture = load(path) as Texture2D
	founder_portrait.visible = true


func _on_start() -> void:
	start_btn.disabled = true
	var gs := get_node_or_null("/root/GameState")
	if gs == null:
		push_error("NewGame: GameState autoload missing; cannot start company")
		start_btn.disabled = false
		return

	var difficulties: Array = ["sandbox", "normal", "hardcore"]

	var diff_idx := clampi(difficulty_selector.selected, 0, difficulties.size() - 1)

	# Safety: free users can only play Sandbox regardless of selector state.
	if not _is_premium_safe() and diff_idx > 0:
		diff_idx = 0
	var scen_idx := clampi(scenario_selector.selected, 0, START_SCENARIOS.size() - 1)
	var scenario_id: String = "garage"
	var scenario_meta = scenario_selector.get_item_metadata(scen_idx)
	if scenario_meta != null:
		scenario_id = str(scenario_meta).strip_edges()
	if scenario_id.is_empty():
		scenario_id = str(START_SCENARIOS[scen_idx].get("id", "garage"))

	var bg_id: int = background_selector.get_selected_id()
	var niche_id := ""
	if niche_selector != null and niche_selector.item_count > 0 and niche_selector.selected >= 0:
		var meta = niche_selector.get_item_metadata(niche_selector.selected)
		if meta != null:
			niche_id = str(meta)

	var config: Dictionary = {
		"name": name_input.text.strip_edges() if not name_input.text.strip_edges().is_empty() else "My Startup",
		"type": type_selector.get_selected_id(),
		"niche_id": niche_id,
		"difficulty": difficulties[diff_idx],
		"scenario": scenario_id,
		"founder_background": bg_id,
	}

	if GameState.current_slot.is_empty():
		# New Game should always come from Save Slots so a slot is explicit.
		# If not, return the player to slot selection instead of forcing slot_1.
		push_warning("NewGame: no save slot selected; returning to save slot picker")
		start_btn.disabled = false
		SceneLoader.goto_scene("res://src/ui/saves/save_slots.tscn")
		return

	GameState.new_game(config)
	EventEngine.load_events("res://src/data/events.json")
	WorldEventEngine.load_events("res://src/data/world_events.json")
	ProductData.load_feature_catalog("res://src/data/features.json")
	HeadlineEngine.load_headlines("res://src/data/headlines.json")
	GameState.market.competitors = CompetitorAI.generate_starting_competitors(
		6,
		GameState.company.type,
		GameState.company.niche_id
	)
	GameState.save_game(GameState.current_slot)

	var analytics := get_node_or_null("/root/Analytics")
	if analytics != null and analytics.has_method("track_new_game"):
		analytics.call(
			"track_new_game",
			CompanyData.TYPE_NAMES.get(config["type"], "unknown"),
			config["difficulty"],
			config["scenario"],
		)
	SceneLoader.goto_scene("res://src/ui/dashboard/quarter_dashboard.tscn")


func _on_back() -> void:
	SceneLoader.goto_scene("res://src/ui/saves/save_slots.tscn")


## Returns true if the player has premium access. Safe fallback to false.
func _is_premium_safe() -> bool:
	var mgr := get_node_or_null("/root/AdManager")
	if mgr == null:
		return false
	if not mgr.has_method("is_premium"):
		return false
	return bool(mgr.call("is_premium"))


## Contextual upgrade prompt when a free user taps a locked difficulty.
## Uses emotion-driven copy (research: benefits > feature lists).
func _show_premium_difficulty_prompt(difficulty_id: int) -> void:
	if _premium_hint_label == null:
		_premium_hint_label = Label.new()
		_premium_hint_label.add_theme_font_size_override("font_size", 13)
		_premium_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var parent := difficulty_selector.get_parent()
		if parent and _difficulty_desc_label:
			parent.add_child(_premium_hint_label)
			parent.move_child(_premium_hint_label, _difficulty_desc_label.get_index() + 1)

	# Emotion-driven copy that sells the experience, not the feature.
	var copy: String
	if difficulty_id == 2:
		copy = "Think you can survive the real startup gauntlet? Hardcore mode is brutal — minimal runway, ruthless competitors, and realistic failure rates. Unlock the full game to prove you've got what it takes."
	else:
		copy = "Ready for a real challenge? Normal mode is how startups actually feel — tight budgets, real competition, and every decision matters. Unlock the full game to experience the real thing."

	_premium_hint_label.text = copy
	_premium_hint_label.add_theme_color_override("font_color", Color(0.95, 0.75, 0.2))
	_premium_hint_label.visible = true
	AnimHelper.fade_in(_premium_hint_label, 0.0, 0.2)

	# Build a small unlock button below the prompt
	var existing_btn := _premium_hint_label.get_node_or_null("UnlockBtn")
	if existing_btn == null:
		var btn := Button.new()
		btn.name = "UnlockBtn"
		btn.text = "Unlock Full Game — $2.99"
		btn.custom_minimum_size = Vector2(0, 46)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(_on_premium_unlock_pressed)
		var parent := _premium_hint_label.get_parent()
		if parent:
			parent.add_child(btn)
			parent.move_child(btn, _premium_hint_label.get_index() + 1)


func _on_premium_unlock_pressed() -> void:
	var mgr := get_node_or_null("/root/AdManager")
	if mgr == null or not mgr.has_method("show_paywall"):
		return
	mgr.call("show_paywall",
		# on_unlock: refresh the difficulty selector to show unlocked options
		func():
			_populate_difficulty_selector()
			_on_difficulty_changed(difficulty_selector.selected)
			if _premium_hint_label:
				_premium_hint_label.visible = false
			# Remove the unlock button
			var btn := _premium_hint_label.get_parent().get_node_or_null("UnlockBtn") if _premium_hint_label else null
			if btn:
				btn.queue_free()
			ToastManager.show("Full game unlocked! All difficulties available."),
		# on_cancel: do nothing, player stays on Sandbox
		Callable()
	)
