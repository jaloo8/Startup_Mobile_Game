class_name EventPopup
extends PanelContainer
## Popup for event choices.

signal event_resolved(event: EventData, choice_index: int)

const KNOWN_EFFECT_KEYS := {
	"cash": true,
	"morale_all": true,
	"stress_all": true,
	"tech_debt": true,
	"bugs": true,
	"reputation": true,
	"users": true,
	"stability": true,
	"game_win": true,
	"salary_increase_pct": true,
	"equity_grant_pct": true,
	"lose_best_engineer": true,
	"fundraising_opportunity": true,
}

@onready var title_label: Label = $Margin/VBox/TitleLabel
@onready var description_label: Label = $Margin/VBox/DescLabel
@onready var choices_container: VBoxContainer = $Margin/VBox/ChoicesContainer
@onready var outcome_label: Label = $Margin/VBox/OutcomeLabel
@onready var continue_btn: Button = $Margin/VBox/ContinueButton

var _current_event: EventData
var _current_choice_index: int = -1
var _tween: Tween


func _ready() -> void:
	visible = false
	continue_btn.visible = false
	continue_btn.pressed.connect(_on_continue)
	UITouchHelper.harden_tree(self)


func _exit_tree() -> void:
	if _tween and _tween.is_running():
		_tween.kill()
	_tween = null
	_current_event = null


func show_event(event: EventData) -> void:
	_current_event = event
	_current_choice_index = -1

	title_label.text = event.title
	description_label.text = EventEngine.resolve_event_text(event, GameState)

	outcome_label.visible = false
	outcome_label.text = ""
	continue_btn.visible = false

	SceneLoader.free_children(choices_container)
	if event.choices.is_empty():
		continue_btn.visible = true
	else:
		for i in event.choices.size():
			var choice: Dictionary = event.choices[i]
			var btn := Button.new()
			btn.text = choice.get("label", "...")
			btn.custom_minimum_size = Vector2(0, 46)
			btn.pressed.connect(_on_choice.bind(i))
			choices_container.add_child(btn)
	UITouchHelper.harden_tree(self)

	modulate.a = 0.0
	visible = true
	if _tween and _tween.is_running():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, 0.2)


func _on_choice(index: int) -> void:
	_current_choice_index = index
	var choice: Dictionary = _current_event.choices[index]

	for child in choices_container.get_children():
		if child is Button:
			child.disabled = true

	outcome_label.text = EventEngine.resolve_outcome_text(choice, GameState)
	outcome_label.visible = true
	continue_btn.visible = true

	_apply_effects(choice.get("effects", {}))


func _apply_effects(effects: Dictionary) -> void:
	_warn_unknown_effect_keys(effects)
	if GameState.company == null or GameState.product == null:
		push_warning("EventPopup: company or product is null; skipping effects")
		return

	if effects.has("cash"):
		GameState.company.cash += float(effects["cash"])
	if effects.has("morale_all"):
		var delta: int = int(effects["morale_all"])
		for emp in GameState.employees:
			emp.morale = clampi(emp.morale + delta, 0, 100)
	if effects.has("stress_all"):
		var delta: int = int(effects["stress_all"])
		for emp in GameState.employees:
			emp.stress = clampi(emp.stress + delta, 0, 100)
	if effects.has("tech_debt"):
		GameState.product.tech_debt = clampi(GameState.product.tech_debt + int(effects["tech_debt"]), 0, 100)
	if effects.has("bugs"):
		GameState.product.bugs = maxi(0, GameState.product.bugs + int(effects["bugs"]))
	if effects.has("reputation"):
		GameState.company.reputation = clampi(GameState.company.reputation + int(effects["reputation"]), 0, 100)
	if effects.has("users"):
		GameState.product.users = maxi(0, GameState.product.users + int(effects["users"]))
	if effects.has("stability"):
		GameState.product.stability = clampi(GameState.product.stability + int(effects["stability"]), 0, 100)
	if effects.has("salary_increase_pct"):
		_apply_salary_raise(float(effects["salary_increase_pct"]))
	if effects.has("equity_grant_pct"):
		_apply_equity_grant(float(effects["equity_grant_pct"]))
	if effects.has("lose_best_engineer") and bool(effects["lose_best_engineer"]):
		_apply_best_engineer_exit()
	if effects.has("fundraising_opportunity") and bool(effects["fundraising_opportunity"]):
		_apply_fundraising_opportunity()
	if effects.has("game_win"):
		GameState.is_game_active = false
		GameState.game_won.emit(str(effects["game_win"]))


func _warn_unknown_effect_keys(effects: Dictionary) -> void:
	var unknown: Array[String] = []
	for raw_key in effects.keys():
		var key := str(raw_key).strip_edges()
		if key.is_empty():
			continue
		if not KNOWN_EFFECT_KEYS.has(key):
			unknown.append(key)
	if not unknown.is_empty():
		push_warning("EventPopup: unknown effect keys in event choice: %s" % str(unknown))


func _apply_salary_raise(percent: float) -> void:
	var target := _best_engineer_candidate()
	if target == null:
		return
	var raise_mult := clampf(1.0 + (percent * 0.01), 1.0, 2.5)
	target.salary_per_quarter = maxf(100.0, target.salary_per_quarter * raise_mult)
	target.morale = clampi(target.morale + 6, 0, 100)


func _apply_equity_grant(percent: float) -> void:
	var grant := clampf(percent, 0.0, 25.0)
	if grant <= 0.0:
		return
	GameState.company.equity_owned = maxf(0.0, GameState.company.equity_owned - grant)


func _apply_best_engineer_exit() -> void:
	var target := _best_engineer_candidate()
	if target == null:
		return
	var leaver_name := target.employee_name
	GameState.fire_employee(target)
	GameState.employee_quit.emit(target)
	GameState.append_event_log({
		"quarter": GameState.current_quarter,
		"year": GameState.current_year,
		"event_id": "employee_quit",
		"title": "%s quit after an external offer cycle" % leaver_name,
	})


func _apply_fundraising_opportunity() -> void:
	GameState.company.reputation = clampi(GameState.company.reputation + 4, 0, 100)
	GameState.append_event_log({
		"quarter": GameState.current_quarter,
		"year": GameState.current_year,
		"event_id": "fundraising_warm_intro",
		"title": "Built a warm VC intro pipeline for upcoming fundraising",
	})


func _best_engineer_candidate() -> EmployeeData:
	if GameState.employees.is_empty():
		return null
	var technical_specialties := {
		EmployeeData.Specialty.FRONTEND: true,
		EmployeeData.Specialty.BACKEND: true,
		EmployeeData.Specialty.MOBILE: true,
		EmployeeData.Specialty.DATA_ML: true,
		EmployeeData.Specialty.DEVOPS: true,
	}
	var best: EmployeeData = null
	var best_score := -1e18
	var best_any: EmployeeData = null
	var best_any_score := -1e18
	for emp: EmployeeData in GameState.employees:
		if emp == null:
			continue
		var score := _retention_score(emp)
		if score > best_any_score:
			best_any_score = score
			best_any = emp
		if technical_specialties.has(emp.specialty) and score > best_score:
			best_score = score
			best = emp
	return best if best != null else best_any


func _retention_score(emp: EmployeeData) -> float:
	var score := float(emp.skill) * 1.0
	score += float(emp.speed) * 0.35
	score += float(emp.seniority) * 4.0
	if emp.assignment == EmployeeData.Assignment.FEATURES:
		score += 8.0
	elif emp.assignment == EmployeeData.Assignment.BUGS:
		score += 5.0
	elif emp.assignment == EmployeeData.Assignment.TECH_DEBT:
		score += 4.0
	return score


func _on_continue() -> void:
	if _tween and _tween.is_running():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 0.0, 0.15)
	_tween.tween_callback(_finish_resolve)


func _finish_resolve() -> void:
	visible = false
	event_resolved.emit(_current_event, _current_choice_index)
