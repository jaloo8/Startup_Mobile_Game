extends RefCounted
## Data-driven macro events that persist for multiple quarters.

const WORLD_EVENTS_PATH := "res://src/data/world_events.json"
const STAGE_ANY := "any"
const TYPE_TO_KEY := {
	CompanyData.CompanyType.SAAS: "saas",
	CompanyData.CompanyType.CONSUMER: "consumer",
	CompanyData.CompanyType.MARKETPLACE: "marketplace",
	CompanyData.CompanyType.DEV_TOOLS: "dev_tools",
}
const ALLOWED_EFFECT_KEYS := {
	"growth_mult": true,
	"churn_mult": true,
	"revenue_mult": true,
	"cost_mult": true,
	"fundraise_amount_mult": true,
	"event_pressure_mult": true,
	"competitor_mult": true,
}

static var _templates: Array[Dictionary] = []


static func load_events(path: String = WORLD_EVENTS_PATH) -> void:
	_templates.clear()
	if not FileAccess.file_exists(path):
		push_warning("WorldEventEngine: file not found: %s" % path)
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("WorldEventEngine: failed to open %s" % path)
		return
	var text := file.get_as_text()
	file = null

	var json := JSON.new()
	if json.parse(text) != OK:
		push_error("WorldEventEngine: JSON parse error at line %d: %s" % [json.get_error_line(), json.get_error_message()])
		return
	if not json.data is Array:
		push_error("WorldEventEngine: expected top-level JSON array")
		return

	for raw in json.data:
		if not raw is Dictionary:
			continue
		var row: Dictionary = raw
		var event_id := str(row.get("id", "")).strip_edges()
		var title := str(row.get("title", "")).strip_edges()
		if event_id.is_empty() or title.is_empty():
			continue
		_templates.append(row.duplicate(true))

	if OS.is_debug_build():
		print("WorldEventEngine: loaded %d world events" % _templates.size())


static func resolve_quarter(state: Node) -> void:
	if state == null or state.company == null or state.product == null or state.market == null:
		return
	if _templates.is_empty():
		load_events()

	_tick_active_event(state)
	if state.active_world_event_quarters_left > 0:
		return
	if _templates.is_empty():
		return

	var context := _build_context(state)
	var roll_chance: float = _roll_chance(state, context)
	if randf() > roll_chance:
		return

	var eligible: Array[Dictionary] = []
	for row in _templates:
		if _matches_filters(row, context):
			eligible.append(row)
	if eligible.is_empty():
		return

	var chosen: Dictionary = _weighted_pick(eligible, context)
	if chosen.is_empty():
		return
	_activate_event(state, chosen)


static func _tick_active_event(state: Node) -> void:
	var q_left: int = int(state.active_world_event_quarters_left)
	if q_left <= 0:
		return

	q_left -= 1
	state.active_world_event_quarters_left = q_left
	if q_left > 0:
		return

	var ended_title := str(state.active_world_event_title).strip_edges()
	if state.has_method("clear_world_event_state"):
		state.clear_world_event_state()
	else:
		state.active_world_event_id = ""
		state.active_world_event_title = ""
		state.active_world_event_description = ""
		state.active_world_event_quarters_left = 0
		state.active_world_event_effects = {}

	if ended_title.is_empty():
		return
	state.append_event_log({
		"quarter": state.current_quarter,
		"year": state.current_year,
		"event_id": "world_event_ended",
		"title": "World pulse easing: %s" % ended_title,
	})


static func _roll_chance(state: Node, context: Dictionary) -> float:
	var stage: String = str(context.get("stage", "growth"))
	var chance: float = 0.16
	match stage:
		"early":
			chance = 0.11
		"late":
			chance = 0.20
		_:
			chance = 0.16

	var pressure_mult := 1.0
	if state.has_method("difficulty_mult"):
		pressure_mult = clampf(float(state.difficulty_mult("event_pressure_mult")), 0.75, 1.35)
	chance *= pressure_mult

	var economy_label := str(context.get("economy_label", "neutral"))
	if economy_label == "bear":
		chance += 0.04
	elif economy_label == "bull":
		chance -= 0.02

	if int(context.get("total_quarters", 0)) < 3:
		chance *= 0.65
	return clampf(chance, 0.05, 0.45)


static func _build_context(state: Node) -> Dictionary:
	var economy_label := "neutral"
	match state.market.economy_state:
		MarketData.EconomyState.BULL:
			economy_label = "bull"
		MarketData.EconomyState.BEAR:
			economy_label = "bear"
		_:
			economy_label = "neutral"

	return {
		"quarter": state.current_quarter,
		"year": state.current_year,
		"total_quarters": state.total_quarters_elapsed() if state.has_method("total_quarters_elapsed") else 0,
		"users": state.product.users,
		"valuation": state.company.valuation,
		"team_size": state.employees.size(),
		"economy_label": economy_label,
		"company_type_key": TYPE_TO_KEY.get(state.company.type, "consumer"),
		"niche_id": str(state.company.niche_id).strip_edges(),
		"stage": _company_stage(state),
	}


static func _company_stage(state: Node) -> String:
	var total_q: int = state.total_quarters_elapsed() if state.has_method("total_quarters_elapsed") else 0
	var users: int = int(state.product.users)
	var team_size: int = state.employees.size()
	if team_size <= 4 and total_q < 8 and users < 12_000:
		return "early"
	if team_size <= 10 and total_q < 24 and users < 120_000:
		return "growth"
	return "late"


static func _matches_filters(row: Dictionary, context: Dictionary) -> bool:
	var stage := str(row.get("stage", STAGE_ANY)).strip_edges().to_lower()
	if not stage.is_empty() and stage != STAGE_ANY and stage != str(context.get("stage", "growth")):
		return false

	var econ := str(row.get("economy", "")).strip_edges().to_lower()
	if not econ.is_empty() and econ != str(context.get("economy_label", "neutral")):
		return false

	var total_q: int = int(context.get("total_quarters", 0))
	var users: int = int(context.get("users", 0))
	var valuation: float = float(context.get("valuation", 0.0))
	if row.has("min_quarter") and total_q < int(row.get("min_quarter", 0)):
		return false
	if row.has("max_quarter") and total_q > int(row.get("max_quarter", 9999)):
		return false
	if row.has("min_users") and users < int(row.get("min_users", 0)):
		return false
	if row.has("max_users") and users > int(row.get("max_users", 2_000_000_000)):
		return false
	if row.has("min_valuation") and valuation < float(row.get("min_valuation", 0.0)):
		return false
	if row.has("max_valuation") and valuation > float(row.get("max_valuation", 1e18)):
		return false

	var type_filters: Array = row.get("company_types", [])
	if type_filters is Array and not type_filters.is_empty():
		var type_key: String = str(context.get("company_type_key", ""))
		if type_key not in type_filters:
			return false

	var niche_filters: Array = row.get("niches", [])
	if niche_filters is Array and not niche_filters.is_empty():
		var niche_id: String = str(context.get("niche_id", ""))
		if niche_id.is_empty() or niche_id not in niche_filters:
			return false

	return true


static func _weighted_pick(pool: Array[Dictionary], context: Dictionary) -> Dictionary:
	var candidates: Array[Dictionary] = []
	var cumulative: Array[float] = []
	var total := 0.0
	for row in pool:
		var weight: float = _weight(row, context)
		if weight <= 0.0:
			continue
		total += weight
		candidates.append(row)
		cumulative.append(total)
	if candidates.is_empty() or total <= 0.0:
		return {}
	var roll := randf() * total
	for i in range(candidates.size()):
		if roll <= cumulative[i]:
			return candidates[i]
	return candidates.back()


static func _weight(row: Dictionary, context: Dictionary) -> float:
	var weight := maxf(float(row.get("weight", 1.0)), 0.01)
	var stage := str(row.get("stage", STAGE_ANY)).strip_edges().to_lower()
	if stage == str(context.get("stage", "growth")):
		weight *= 1.10

	var econ := str(row.get("economy", "")).strip_edges().to_lower()
	if not econ.is_empty() and econ == str(context.get("economy_label", "neutral")):
		weight *= 1.14

	var type_filters: Array = row.get("company_types", [])
	if type_filters is Array and not type_filters.is_empty():
		var type_key := str(context.get("company_type_key", ""))
		weight *= 1.18 if type_key in type_filters else 0.35

	var niche_filters: Array = row.get("niches", [])
	if niche_filters is Array and not niche_filters.is_empty():
		var niche_id := str(context.get("niche_id", ""))
		weight *= 1.35 if niche_id in niche_filters else 0.45

	return maxf(weight, 0.01)


static func _activate_event(state: Node, row: Dictionary) -> void:
	var effects: Dictionary = _sanitize_effects(row.get("effects", {}))
	var min_q := maxi(1, int(row.get("duration_min", 1)))
	var max_q := maxi(min_q, int(row.get("duration_max", min_q)))
	var duration := randi_range(min_q, max_q)

	state.active_world_event_id = str(row.get("id", "")).strip_edges()
	state.active_world_event_title = str(row.get("title", "World shift")).strip_edges()
	state.active_world_event_description = str(row.get("description", "")).strip_edges()
	state.active_world_event_quarters_left = duration
	state.active_world_event_effects = effects

	var short_desc := state.active_world_event_description
	if short_desc.length() > 100:
		short_desc = short_desc.substr(0, 100).strip_edges() + "..."
	var log_title := "World pulse: %s (%dQ)" % [state.active_world_event_title, duration]
	if not short_desc.is_empty():
		log_title += " — %s" % short_desc
	state.append_event_log({
		"quarter": state.current_quarter,
		"year": state.current_year,
		"event_id": "world_event_" + state.active_world_event_id,
		"title": log_title,
	})


static func _sanitize_effects(raw) -> Dictionary:
	var src: Dictionary = raw if raw is Dictionary else {}
	var out := {}
	for raw_key in src.keys():
		var key := str(raw_key).strip_edges()
		if key.is_empty() or not ALLOWED_EFFECT_KEYS.has(key):
			continue
		var value_raw = src.get(raw_key, 1.0)
		if value_raw is int or value_raw is float:
			out[key] = clampf(float(value_raw), 0.55, 1.70)
	return out
