extends Control

@onready var name_input: LineEdit = %CompanyNameInput
@onready var type_selector: OptionButton = %TypeSelector
@onready var difficulty_selector: OptionButton = %DifficultySelector
@onready var scenario_selector: OptionButton = %ScenarioSelector
@onready var start_btn: Button = %StartButton
@onready var back_btn: Button = %BackButton


func _ready() -> void:
	_populate_type_selector()
	_populate_difficulty_selector()
	_populate_scenario_selector()
	start_btn.pressed.connect(_on_start)
	back_btn.pressed.connect(_on_back)


func _populate_type_selector() -> void:
	type_selector.clear()
	type_selector.add_item("SaaS B2B Tool", CompanyData.CompanyType.SAAS)
	type_selector.add_item("Consumer App", CompanyData.CompanyType.CONSUMER)
	type_selector.add_item("Marketplace / Platform", CompanyData.CompanyType.MARKETPLACE)
	type_selector.add_item("Dev Tools / Infrastructure", CompanyData.CompanyType.DEV_TOOLS)


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


func _on_start() -> void:
	var scenarios := ["garage", "accelerator", "spinoff", "vc_backed"]
	var difficulties := ["sandbox", "normal", "hardcore"]

	var diff_idx := clampi(difficulty_selector.selected, 0, difficulties.size() - 1)
	var scen_idx := clampi(scenario_selector.selected, 0, scenarios.size() - 1)

	var config := {
		"name": name_input.text.strip_edges() if not name_input.text.strip_edges().is_empty() else "My Startup",
		"type": type_selector.get_selected_id(),
		"difficulty": difficulties[diff_idx],
		"scenario": scenarios[scen_idx],
	}

	GameState.new_game(config)
	EventEngine.load_events("res://src/data/events.json")
	GameState.market.competitors = CompetitorAI.generate_starting_competitors(6, GameState.company.type)

	SceneLoader.goto_scene("res://src/ui/dashboard/quarter_dashboard.tscn")


func _on_back() -> void:
	SceneLoader.goto_scene("res://src/ui/main_menu/main_menu.tscn")
