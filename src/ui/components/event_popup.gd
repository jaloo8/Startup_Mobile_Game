class_name EventPopup
extends PanelContainer
## Popup for event choices.

signal event_resolved(event: EventData, choice_index: int)

const KNOWN_EFFECT_KEYS: Dictionary = {
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
var _skip_btn: Button


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
	if event == null:
		push_error("EventPopup: received null event")
		return
	_current_event = event
	_current_choice_index = -1

	title_label.text = event.title
	description_label.text = EventEngine.resolve_event_text(event, GameState)

	outcome_label.visible = false
	outcome_label.text = ""
	continue_btn.visible = false

	SceneLoader.free_children(choices_container)
	_skip_btn = null
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
		_add_skip_button()
		AnimHelper.stagger_list(choices_container, 0.06, 0.16, 18.0)
	UITouchHelper.harden_tree(self)

	SfxPlayer.play("event_popup")
	visible = true
	if _tween and _tween.is_running():
		_tween.kill()
	# Spring pop-in with scale overshoot — much more impactful than a plain fade.
	scale = Vector2(0.85, 0.85)
	pivot_offset = size * 0.5
	modulate.a = 0.0
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(self, "scale", Vector2.ONE, 0.26) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_tween.tween_property(self, "modulate:a", 1.0, 0.18) \
		.set_ease(Tween.EASE_OUT)


func _add_skip_button() -> void:
	var cost: int = CurrencyManager.COST_REROLL_EVENT
	if not CurrencyManager.can_afford(cost):
		return
	_skip_btn = Button.new()
	_skip_btn.text = "Skip Event (%d chips)" % cost
	_skip_btn.custom_minimum_size = Vector2(0, 40)
	_skip_btn.add_theme_font_size_override("font_size", ThemeManager.FONT_SM)
	_skip_btn.add_theme_color_override("font_color", ThemeManager.C_CHIP)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.12, 0.20, 0.5)
	style.set_corner_radius_all(ThemeManager.CORNER_MD)
	style.set_content_margin_all(6.0)
	_skip_btn.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = style.bg_color.lightened(0.08)
	_skip_btn.add_theme_stylebox_override("hover", hover)
	_skip_btn.add_theme_stylebox_override("pressed", style)
	_skip_btn.pressed.connect(_on_skip_event)
	choices_container.add_child(_skip_btn)


func _on_skip_event() -> void:
	if not CurrencyManager.spend_reroll_event():
		return
	# Disable all choice buttons (including skip) to prevent double-tap.
	for child in choices_container.get_children():
		if child is Button:
			child.disabled = true
	_current_choice_index = -1
	outcome_label.text = "You spent chips to dodge this one. Back to work."
	outcome_label.visible = true
	continue_btn.visible = true
	AnimHelper.float_text(self, "-%d chips" % CurrencyManager.COST_REROLL_EVENT,
		ThemeManager.C_CHIP, Vector2(size.x * 0.5, 0))
	SfxPlayer.play("chip_spend")
	AnimHelper.haptic(&"light")


func _on_choice(index: int) -> void:
	if _current_event == null or index < 0 or index >= _current_event.choices.size():
		push_error("EventPopup: invalid choice index %d" % index)
		return
	_current_choice_index = index
	var choice: Dictionary = _current_event.choices[index]

	for child in choices_container.get_children():
		if child is Button:
			child.disabled = true

	outcome_label.text = EventEngine.resolve_outcome_text(choice, GameState)
	outcome_label.visible = true
	continue_btn.visible = true

	var effects: Dictionary = choice.get("effects", {})
	_apply_effects(effects)
	_play_effect_juice(effects)


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


func _play_effect_juice(effects: Dictionary) -> void:
	if effects.is_empty():
		return
	# Cash effects — floating number + sound.
	if effects.has("cash"):
		var cash_val := float(effects["cash"])
		AnimHelper.float_money(self, cash_val, Vector2(size.x * 0.5, 0))
		if cash_val > 0:
			SfxPlayer.play("cash_gain")
		else:
			SfxPlayer.play("cash_loss")
	# Reputation boost.
	if effects.has("reputation") and int(effects["reputation"]) > 0:
		AnimHelper.float_text(self, "+%d rep" % int(effects["reputation"]),
			ThemeManager.C_PURPLE, Vector2(size.x * 0.5, 20))
	# User gain.
	if effects.has("users") and int(effects["users"]) > 0:
		AnimHelper.float_text(self, "+%s users" % SceneLoader.format_number(int(effects["users"])),
			ThemeManager.C_TEAL, Vector2(size.x * 0.5, 40))
	# Negative events — shake.
	var is_negative := false
	if effects.has("cash") and float(effects["cash"]) < -10_000:
		is_negative = true
	if effects.has("lose_best_engineer") and bool(effects.get("lose_best_engineer", false)):
		is_negative = true
	if is_negative:
		AnimHelper.screen_shake(get_tree(), 0.25, 0.25)
		AnimHelper.haptic(&"medium")
	else:
		AnimHelper.haptic(&"light")


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
	var technical_specialties: Dictionary = {
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
	pivot_offset = size * 0.5
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(self, "scale", Vector2(0.90, 0.90), 0.14) \
		.set_ease(Tween.EASE_IN)
	_tween.tween_property(self, "modulate:a", 0.0, 0.14) \
		.set_ease(Tween.EASE_IN)
	_tween.chain().tween_callback(_finish_resolve)


func _finish_resolve() -> void:
	visible = false
	scale = Vector2.ONE
	event_resolved.emit(_current_event, _current_choice_index)
