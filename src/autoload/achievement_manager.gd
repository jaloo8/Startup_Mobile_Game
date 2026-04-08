extends Node
## AchievementManager — persistent cross-run achievement tracking.
##
## Checks achievement conditions each quarter against current game state.
## Unlocked achievements persist in user:// and survive game resets.
##
## Usage:
##   AchievementManager.check_all()               # called automatically on quarter advance
##   AchievementManager.get_unlocked() -> Array    # list of unlocked achievement IDs
##   AchievementManager.get_all() -> Array         # all achievement definitions
##   AchievementManager.is_unlocked(id) -> bool    # check specific achievement

signal achievement_unlocked(achievement: Dictionary)

const SAVE_PATH := "user://achievements.dat"
const DATA_PATH := "res://src/data/achievements.json"

## All achievement definitions loaded from JSON.
var _definitions: Array[Dictionary] = []

## Set of unlocked achievement IDs (persisted).
var _unlocked: Dictionary = {}  # id -> true

## Set of company types the player has won with (persisted).
var _won_company_types: Dictionary = {}  # type_name -> true

## Tracks the current run's win type for condition checking.
var _current_win_type: String = ""


func _ready() -> void:
	_load_definitions()
	_load_progress()
	# Connect to game signals for automatic checking.
	if GameState.has_signal("quarter_advanced"):
		GameState.quarter_advanced.connect(_on_quarter_advanced)
	if GameState.has_signal("game_won"):
		GameState.game_won.connect(_on_game_won)
	if GameState.has_signal("game_over"):
		GameState.game_over.connect(_on_game_lost)


func _load_definitions() -> void:
	_definitions.clear()
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		push_warning("AchievementManager: cannot open %s" % DATA_PATH)
		return
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		push_error("AchievementManager: JSON parse error: %s" % json.get_error_message())
		return
	var data: Variant = json.data
	if data is Dictionary and data.has("achievements"):
		for item in data["achievements"]:
			if item is Dictionary and item.has("id"):
				_definitions.append(item)


func _load_progress() -> void:
	_unlocked.clear()
	_won_company_types.clear()
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return  # No progress yet — clean slate.
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		push_warning("AchievementManager: corrupted progress file, starting fresh")
		return
	var data: Variant = json.data
	if not data is Dictionary:
		return
	for uid in data.get("unlocked", []):
		_unlocked[str(uid)] = true
	for ct in data.get("won_company_types", []):
		_won_company_types[str(ct)] = true


func _save_progress() -> void:
	var unlocked_list: Array = []
	for key in _unlocked:
		unlocked_list.append(key)
	var won_types_list: Array = []
	for key in _won_company_types:
		won_types_list.append(key)
	var data: Dictionary = {
		"unlocked": unlocked_list,
		"won_company_types": won_types_list,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

func get_all() -> Array[Dictionary]:
	return _definitions


func get_unlocked() -> Array[String]:
	var result: Array[String] = []
	for key in _unlocked:
		result.append(str(key))
	return result


func is_unlocked(id: String) -> bool:
	return _unlocked.has(id)


func get_unlock_count() -> int:
	return _unlocked.size()


func get_total_count() -> int:
	return _definitions.size()


func get_progress_text() -> String:
	return "%d / %d" % [get_unlock_count(), get_total_count()]


## Force-check all achievements against current state.
func check_all() -> void:
	if GameState.company == null:
		return
	var ctx := _build_context()
	for def in _definitions:
		var id: String = def.get("id", "")
		if id.is_empty() or _unlocked.has(id):
			continue
		if _check_condition(def.get("condition", {}), ctx):
			_unlock(def)


## Notify the manager that the player won with a specific type.
func record_win(win_type: String) -> void:
	_current_win_type = win_type
	if GameState.company != null:
		var type_name: String = _company_type_name(GameState.company.type)
		if not type_name.is_empty():
			_won_company_types[type_name] = true
	check_all()
	_current_win_type = ""
	_save_progress()


# ---------------------------------------------------------------------------
# Context building
# ---------------------------------------------------------------------------

func _build_context() -> Dictionary:
	var ctx: Dictionary = {}
	if GameState.company:
		ctx["cash"] = GameState.company.cash
		ctx["valuation"] = GameState.company.valuation
		ctx["reputation"] = GameState.company.reputation
		ctx["marketing_budget"] = GameState.company.marketing_budget
	if GameState.product:
		ctx["users"] = GameState.product.users
		ctx["features_shipped"] = GameState.product.features.size()
		ctx["bugs"] = GameState.product.bugs
		ctx["stability"] = GameState.product.stability
	if GameState.financials:
		ctx["revenue"] = GameState.financials.revenue
		ctx["is_profitable"] = GameState.financials.revenue > GameState.financials.burn_rate
		ctx["funding_rounds"] = GameState.financials.funding_rounds.size()
	ctx["employee_count"] = GameState.employees.size()
	ctx["total_quarters"] = GameState.current_quarter + (GameState.current_year - 1) * 4
	ctx["profit_streak"] = GameState.profit_streak
	ctx["angel_bailout_used"] = GameState.angel_bailout_used
	ctx["has_won"] = _current_win_type != ""
	ctx["win_type"] = _current_win_type
	ctx["unique_win_types"] = _won_company_types.size()

	# Night owl check: playing between midnight and 5am.
	var hour := Time.get_time_dict_from_system().get("hour", 12)
	ctx["is_night_owl"] = hour >= 0 and hour < 5

	return ctx


func _company_type_name(type_enum: int) -> String:
	match type_enum:
		0: return "saas"
		1: return "consumer"
		2: return "marketplace"
		3: return "dev_tools"
	return ""


# ---------------------------------------------------------------------------
# Condition evaluation
# ---------------------------------------------------------------------------

func _check_condition(condition: Dictionary, ctx: Dictionary) -> bool:
	if condition.is_empty():
		return false
	for key: String in condition:
		var target: Variant = condition[key]
		if not _check_single(key, target, ctx):
			return false
	return true


func _check_single(key: String, target: Variant, ctx: Dictionary) -> bool:
	# Parse key format: "field_operator" e.g. "cash_gte", "bugs_eq", "is_profitable"
	if key.ends_with("_gte"):
		var field := key.substr(0, key.length() - 4)
		return float(ctx.get(field, 0)) >= float(target)
	elif key.ends_with("_lte"):
		var field := key.substr(0, key.length() - 4)
		return float(ctx.get(field, 0)) <= float(target)
	elif key.ends_with("_eq"):
		var field := key.substr(0, key.length() - 3)
		var ctx_val: Variant = ctx.get(field, null)
		if ctx_val == null:
			return false
		return str(ctx_val) == str(target)
	else:
		# Boolean or direct match.
		var ctx_val: Variant = ctx.get(key, null)
		if ctx_val == null:
			return false
		if target is bool:
			return bool(ctx_val) == target
		return str(ctx_val) == str(target)


# ---------------------------------------------------------------------------
# Unlock ceremony
# ---------------------------------------------------------------------------

func _unlock(def: Dictionary) -> void:
	var id: String = def.get("id", "")
	if id.is_empty() or _unlocked.has(id):
		return
	_unlocked[id] = true
	_save_progress()

	var title: String = def.get("title", "Achievement")
	var icon: String = def.get("icon", "🏆")
	var chips: int = int(def.get("reward_chips", 0))

	# --- Achievement unlock celebration ---
	SfxPlayer.play("achievement")
	AnimHelper.haptic(&"heavy")
	ToastManager.show_achievement(title, icon)

	# Screen flash + confetti on the active scene for visual punch.
	var tree := Engine.get_main_loop() as SceneTree
	if tree and is_instance_valid(tree.current_scene):
		var scene: Node = tree.current_scene
		if scene is Control:
			AnimHelper.screen_flash(scene as Control, Color(1.0, 0.84, 0.0, 0.20), 0.35)
			var viewport_size := scene.get_viewport_rect().size
			AnimHelper.confetti_burst(scene as Control,
				Vector2(viewport_size.x * 0.5, 80.0),
				[Color(1.0, 0.84, 0.0), Color(0.80, 0.45, 0.95), Color(0.30, 0.85, 0.45)],
				20, 200.0, 1.5)

	# Award chips.
	if chips > 0 and CurrencyManager.has_method("earn"):
		CurrencyManager.earn(chips, "achievement_%s" % id)

	# Emit signal for any listeners.
	achievement_unlocked.emit(def)

	if OS.is_debug_build():
		push_warning("Achievement unlocked: %s (%s)" % [title, id])


# ---------------------------------------------------------------------------
# Signal handlers
# ---------------------------------------------------------------------------

func _on_quarter_advanced(_q: int) -> void:
	check_all()


func _on_game_won(win_type: String) -> void:
	record_win(win_type)


func _on_game_lost(_reason: String) -> void:
	check_all()
	_save_progress()
