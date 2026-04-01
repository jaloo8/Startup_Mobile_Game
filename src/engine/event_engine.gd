class_name EventEngine
extends RefCounted
## Loads events from JSON, checks triggers, and picks quarter events.

static var _all_events: Array[EventData] = []
static var _cooldowns: Dictionary = {}  # event_id -> quarters_remaining


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

		_all_events.append(ev)

	print("EventEngine: loaded %d events" % _all_events.size())


static func roll_quarter_events(state: Node) -> Array[EventData]:
	if _all_events.is_empty():
		return []

	_tick_cooldowns()

	var context := _build_context(state)
	var eligible: Array[EventData] = []

	for ev in _all_events:
		if ev.one_time and ev.id in state.fired_one_time_events:
			continue
		if _cooldowns.has(ev.id) and _cooldowns[ev.id] > 0:
			continue
		if ev.is_eligible(context):
			eligible.append(ev)

	if eligible.is_empty():
		return []

	# Fewer events early on (calm start), ramp up as the company grows.
	# Valuation tiers: < $500K → max 1, < $2M → max 2, $2M+ → max 3
	var valuation: float = state.company.valuation if state.company != null else 0.0
	var max_events: int
	if valuation < 500_000.0:
		max_events = 1
	elif valuation < 2_000_000.0:
		max_events = 2
	else:
		max_events = 3
	var pressure_mult := 1.0
	if state.has_method("difficulty_mult"):
		pressure_mult = clampf(float(state.difficulty_mult("event_pressure_mult")), 0.7, 1.5)
	# Use floor/ceil instead of round so multipliers always have a visible effect.
	# Example: 2 * 0.85 should stay at 1 in sandbox, while 2 * 1.2 should become 3.
	if pressure_mult < 1.0:
		max_events = maxi(1, floori(max_events * pressure_mult))
	elif pressure_mult > 1.0:
		max_events = mini(4, ceili(max_events * pressure_mult))

	var count := randi_range(1, mini(max_events, eligible.size()))
	var picked: Array[EventData] = []
	var remaining := eligible.duplicate()

	for _i in count:
		if remaining.is_empty():
			break
		var chosen := _weighted_pick(remaining)
		if chosen == null:
			break
		picked.append(chosen)
		remaining.erase(chosen)

		if chosen.one_time:
			state.fired_one_time_events.append(chosen.id)

		var cd: int = chosen.get_meta("cooldown", 0) if chosen.has_meta("cooldown") else 0
		if cd > 0:
			_cooldowns[chosen.id] = cd

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


static func _weighted_pick(pool: Array[EventData]) -> EventData:
	var total := 0.0
	for ev in pool:
		total += maxf(ev.weight, 0.01)
	if total <= 0.0:
		return null
	var roll := randf() * total
	for ev in pool:
		roll -= maxf(ev.weight, 0.01)
		if roll <= 0.0:
			return ev
	return pool.back()


static func _build_context(state: Node) -> Dictionary:
	return {
		"quarter": state.current_quarter,
		"year": state.current_year,
		"employee_count": state.employees.size(),
		"cash": state.company.cash,
		"users": state.product.users,
		"has_raised_funding": not state.financials.funding_rounds.is_empty(),
		"tech_debt": state.product.tech_debt,
		"reputation": state.company.reputation,
		"bugs": state.product.bugs,
		"stability": state.product.stability,
		"company_type": state.company.type,
		"valuation": state.company.valuation,
		"features_shipped": state.product.feature_count(),
		"revenue": state.financials.revenue,
	}
