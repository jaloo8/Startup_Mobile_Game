class_name EventEngine
extends RefCounted
## Loads events from JSON, checks triggers, and picks quarter events.

static var _all_events: Array[EventData] = []
static var _cooldowns: Dictionary = {}  # event_id -> quarters_remaining

const STAGE_ANY := "any"
const NICHE_EVENT_CATEGORY_MULTS := {
	"streaming_service": {"market": 1.35, "product": 1.15, "money": 0.92},
	"fitness_companion": {"people": 1.18, "product": 1.12, "culture": 1.08},
	"local_discovery": {"market": 1.28, "culture": 1.10, "product": 1.05},
	"vertical_crm": {"money": 1.18, "product": 1.10, "market": 1.05},
	"workflow_automation": {"product": 1.20, "people": 1.08},
	"compliance_ops": {"money": 1.24, "market": 1.15, "culture": 1.10},
	"home_services": {"market": 1.25, "people": 1.10, "money": 1.05},
	"resale_goods": {"market": 1.24, "product": 1.10, "culture": 1.08},
	"food_delivery_hub": {"market": 1.30, "product": 1.12, "money": 1.06},
	"api_observability": {"product": 1.24, "culture": 1.10, "money": 1.04},
	"ci_automation": {"product": 1.20, "people": 1.10},
	"cloud_cost_tools": {"money": 1.28, "product": 1.18, "market": 1.06},
}
const STAGE_CATEGORY_MULTS := {
	"early": {"people": 1.15, "product": 1.10, "culture": 1.08, "market": 0.84, "money": 0.88},
	"growth": {"people": 1.02, "product": 1.04, "culture": 1.00, "market": 1.04, "money": 1.02},
	"late": {"people": 0.90, "product": 0.96, "culture": 0.92, "market": 1.14, "money": 1.10},
}
const DIFFICULTY_CATEGORY_MULTS := {
	"sandbox": {"people": 1.05, "product": 1.05, "culture": 1.06, "market": 0.86, "money": 0.84},
	"normal": {},
	"hardcore": {"people": 0.98, "product": 1.02, "culture": 0.95, "market": 1.09, "money": 1.10},
}
const CATEGORY_ALIASES := {
	"finance": "money",
}
const SAME_CATEGORY_PICK_DAMPING := 0.72


static func reset_cooldowns() -> void:
	_cooldowns.clear()


static func load_events(path: String) -> void:
	_all_events.clear()
	_cooldowns.clear()

	if not FileAccess.file_exists(path):
		push_warning("EventEngine: file not found: %s" % path)
		return

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("EventEngine: failed to open %s" % path)
		return

	var text := file.get_as_text()
	file = null

	var json := JSON.new()
	if json.parse(text) != OK:
		push_error("EventEngine: JSON parse error at line %d: %s" % [json.get_error_line(), json.get_error_message()])
		return

	if not json.data is Array:
		push_error("EventEngine: expected top-level JSON array")
		return

	for entry in json.data:
		if not entry is Dictionary:
			continue
		var ev := EventData.new()
		ev.id = str(entry.get("id", ""))
		ev.title = str(entry.get("title", ""))

		ev.description = str(entry.get("description_template", entry.get("description", "")))
		var raw_choices = entry.get("choices", [])
		ev.choices.assign(raw_choices if raw_choices is Array else [])
		ev.trigger_conditions = entry.get("trigger_conditions", {})
		ev.weight = float(entry.get("weight", 1.0))
		ev.one_time = bool(entry.get("one_time", false))

		ev.set_meta("variations", entry.get("variations", []))
		ev.set_meta("category", entry.get("category", ""))
		ev.set_meta("stage", entry.get("stage", "any"))
		ev.set_meta("cooldown", int(entry.get("cooldown_quarters", 0)))
		ev.set_meta("niches", entry.get("niches", []))

		_all_events.append(ev)

	print("EventEngine: loaded %d events" % _all_events.size())


static func roll_quarter_events(state: Node) -> Array[EventData]:
	if _all_events.is_empty():
		return []

	_tick_cooldowns()

	var context := _build_context(state)
	context["company_stage"] = _company_stage(context)
	var eligible: Array[EventData] = []

	for ev in _all_events:
		if ev.one_time and ev.id in state.fired_one_time_events:
			continue
		if _cooldowns.has(ev.id) and _cooldowns[ev.id] > 0:
			continue
		if not _matches_stage(ev, context):
			continue
		if ev.is_eligible(context):
			eligible.append(ev)

	if eligible.is_empty():
		return []

	var bounds: Vector2i = _event_count_bounds(context)
	var min_events: int = bounds.x
	var max_events: int = bounds.y
	var pressure_mult := 1.0
	if state.has_method("difficulty_mult"):
		pressure_mult = clampf(float(state.difficulty_mult("event_pressure_mult")), 0.7, 1.5)
	if state.has_method("world_event_mult"):
		pressure_mult *= clampf(float(state.world_event_mult("event_pressure_mult", 1.0)), 0.7, 1.4)
	var stage_key := str(context.get("company_stage", "growth")).to_lower()
	if pressure_mult < 0.95:
		max_events = maxi(min_events, max_events - 1)
	elif pressure_mult > 1.12:
		max_events = mini(4, max_events + 1)
	if pressure_mult > 1.30 and stage_key != "early":
		min_events = mini(max_events, min_events + 1)

	var pick_max := mini(max_events, eligible.size())
	var pick_min := mini(min_events, pick_max)
	var count := randi_range(pick_min, pick_max)
	var picked: Array[EventData] = []
	var remaining := eligible.duplicate()
	var picked_category_counts := {}

	for _i in count:
		if remaining.is_empty():
			break
		var chosen := _weighted_pick(remaining, context, picked_category_counts)
		if chosen == null:
			break
		picked.append(chosen)
		remaining.erase(chosen)
		var cat := _event_category(chosen)
		picked_category_counts[cat] = int(picked_category_counts.get(cat, 0)) + 1

		if chosen.one_time:
			state.fired_one_time_events.append(chosen.id)

		var cd: int = chosen.get_meta("cooldown", 0) if chosen.has_meta("cooldown") else 0
		if cd > 0:
			_cooldowns[chosen.id] = _effective_cooldown(chosen, cd, context, pressure_mult)

	return picked


static func resolve_event_text(event: EventData, state: Node) -> String:
	var base_template: String = event.description
	var variations: Array = event.get_meta("variations", []) if event.has_meta("variations") else []
	var chosen_template := TemplateEngine.pick_variation(base_template, variations)
	var ctx := TemplateEngine.build_context(state)
	return TemplateEngine.apply(chosen_template, ctx)


static func resolve_outcome_text(choice: Dictionary, state: Node) -> String:
	var base: String = choice.get("outcome_template", choice.get("outcome_text", ""))
	var variations: Array = choice.get("outcome_variations", [])
	var chosen := TemplateEngine.pick_variation(base, variations)
	var ctx := TemplateEngine.build_context(state)
	return TemplateEngine.apply(chosen, ctx)


static func _tick_cooldowns() -> void:
	var expired: Array[String] = []
	for event_id in _cooldowns:
		_cooldowns[event_id] -= 1
		if _cooldowns[event_id] <= 0:
			expired.append(event_id)
	for eid in expired:
		_cooldowns.erase(eid)


static func _weighted_pick(pool: Array[EventData], context: Dictionary, picked_category_counts: Dictionary) -> EventData:
	var candidates: Array[EventData] = []
	var cumulative: Array[float] = []
	var total := 0.0
	for ev in pool:
		var damp_mult := _within_roll_category_dampener(ev, picked_category_counts)
		var weight: float = _effective_event_weight(ev, context) * damp_mult
		if weight <= 0.0:
			continue
		total += weight
		candidates.append(ev)
		cumulative.append(total)
	if candidates.is_empty() or total <= 0.0:
		return null
	var roll := randf() * total
	for i in range(candidates.size()):
		if roll <= cumulative[i]:
			return candidates[i]
	return candidates.back()


static func _matches_stage(ev: EventData, context: Dictionary) -> bool:
	var stage: String = str(ev.get_meta("stage", STAGE_ANY)).strip_edges().to_lower()
	if stage.is_empty() or stage == STAGE_ANY:
		return true
	return stage == str(context.get("company_stage", _company_stage(context)))


static func _company_stage(context: Dictionary) -> String:
	var total_q: int = int(context.get("total_quarters", 0))
	var users: int = int(context.get("users", 0))
	var valuation: float = float(context.get("valuation", 0.0))
	if total_q >= 20 or users >= 80_000 or valuation >= 50_000_000.0:
		return "late"
	if total_q >= 6 or users >= 2_000 or valuation >= 2_000_000.0:
		return "growth"
	return "early"


static func _effective_event_weight(ev: EventData, context: Dictionary) -> float:
	var weight: float = maxf(ev.weight, 0.01)
	var category: String = _event_category(ev)
	var stage_key := str(context.get("company_stage", _company_stage(context))).to_lower()
	var stage_mults: Dictionary = STAGE_CATEGORY_MULTS.get(stage_key, {})
	if stage_mults.has(category):
		weight *= float(stage_mults.get(category, 1.0))
	var diff_key := str(context.get("difficulty", "normal")).strip_edges().to_lower()
	var diff_mults: Dictionary = DIFFICULTY_CATEGORY_MULTS.get(diff_key, {})
	if diff_mults.has(category):
		weight *= float(diff_mults.get(category, 1.0))

	var niche_id: String = str(context.get("niche_id", "")).strip_edges()
	if not niche_id.is_empty():
		var cat_mults: Dictionary = NICHE_EVENT_CATEGORY_MULTS.get(niche_id, {})
		if not cat_mults.is_empty():
			weight *= float(cat_mults.get(category, 1.0))

		var raw_niches: Array = ev.get_meta("niches", []) if ev.has_meta("niches") else []
		if not raw_niches.is_empty():
			var niche_match := false
			for raw in raw_niches:
				if str(raw).strip_edges() == niche_id:
					niche_match = true
					break
			weight *= 1.35 if niche_match else 0.35

	var stage: String = str(ev.get_meta("stage", STAGE_ANY)).strip_edges().to_lower()
	if stage == str(context.get("company_stage", _company_stage(context))):
		weight *= 1.12
	return maxf(weight, 0.01)


static func _build_context(state: Node) -> Dictionary:
	return {
		"quarter": state.current_quarter,
		"year": state.current_year,
		"total_quarters": state.total_quarters_elapsed(),
		"employee_count": state.employees.size(),
		"cash": state.company.cash,
		"users": state.product.users,
		"has_raised_funding": not state.financials.funding_rounds.is_empty(),
		"tech_debt": state.product.tech_debt,
		"reputation": state.company.reputation,
		"bugs": state.product.bugs,
		"stability": state.product.stability,
		"company_type": state.company.type,
		"niche_id": state.company.niche_id,
		"valuation": state.company.valuation,
		"features_shipped": state.product.feature_count(),
		"revenue": state.financials.revenue,
		"world_event_id": state.active_world_event_id if int(state.active_world_event_quarters_left) > 0 else "",
		"world_event_title": state.active_world_event_title if int(state.active_world_event_quarters_left) > 0 else "",
		"difficulty": state.difficulty if state != null else "normal",
	}


static func _normalized_category(raw: String) -> String:
	var key := raw.strip_edges().to_lower()
	if CATEGORY_ALIASES.has(key):
		return str(CATEGORY_ALIASES.get(key, key))
	return key


static func _event_category(ev: EventData) -> String:
	return _normalized_category(str(ev.get_meta("category", "")).to_lower())


static func _within_roll_category_dampener(ev: EventData, picked_category_counts: Dictionary) -> float:
	if picked_category_counts.is_empty():
		return 1.0
	var category := _event_category(ev)
	var already_picked: int = int(picked_category_counts.get(category, 0))
	if already_picked <= 0:
		return 1.0
	return maxf(0.35, float(pow(SAME_CATEGORY_PICK_DAMPING, already_picked)))


static func _event_count_bounds(context: Dictionary) -> Vector2i:
	var stage := str(context.get("company_stage", _company_stage(context))).to_lower()
	var valuation: float = float(context.get("valuation", 0.0))
	var team_size: int = int(context.get("employee_count", 0))
	var total_q: int = int(context.get("total_quarters", 0))
	var min_events := 1
	var max_events := 1
	match stage:
		"late":
			min_events = 1
			max_events = 3
		"growth":
			min_events = 1
			max_events = 2
		_:
			min_events = 1
			max_events = 1

	if stage == "early" and total_q >= 6 and team_size >= 6 and valuation >= 3_000_000.0:
		max_events = 2
	elif stage == "growth" and team_size >= 14 and valuation >= 35_000_000.0:
		max_events = 3

	return Vector2i(min_events, max_events)


static func _effective_cooldown(event: EventData, base_cd: int, context: Dictionary, pressure_mult: float) -> int:
	if base_cd <= 0:
		return 0
	var adjusted := base_cd
	var stage := str(context.get("company_stage", _company_stage(context))).to_lower()
	match stage:
		"early":
			adjusted += 1
		"late":
			adjusted -= 1
		_:
			pass

	var difficulty_key := str(context.get("difficulty", "normal")).strip_edges().to_lower()
	if difficulty_key == "sandbox":
		adjusted += 1
	elif difficulty_key == "hardcore":
		if stage == "late" and pressure_mult >= 1.10:
			adjusted -= 1

	# Keep late hardcore macro pressure strong without repeating market/money
	# story beats too aggressively quarter-over-quarter.
	if difficulty_key == "hardcore" and stage == "late":
		var category := _event_category(event)
		if category == "market" or category == "money":
			adjusted += 1

	if pressure_mult <= 0.90:
		adjusted += 1
	elif pressure_mult >= 1.25:
		adjusted -= 1

	var min_cd := 2 if stage == "early" else 1
	return clampi(adjusted, min_cd, 12)
