class_name EventEngine
extends RefCounted
## Loads events from JSON, checks triggers, and rolls for quarter events.

static var _all_events: Array[EventData] = []


static func load_events(path: String) -> void:
	_all_events.clear()
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
		ev.description = str(entry.get("description", ""))
		ev.choices = entry.get("choices", [])
		ev.trigger_conditions = entry.get("trigger_conditions", {})
		ev.weight = float(entry.get("weight", 1.0))
		ev.one_time = bool(entry.get("one_time", false))
		_all_events.append(ev)

	print("EventEngine: loaded %d events" % _all_events.size())


static func roll_quarter_events(state: Node) -> Array[EventData]:
	if _all_events.is_empty():
		return []

	var context := _build_context(state)
	var eligible: Array[EventData] = []
	var total_weight := 0.0

	for ev in _all_events:
		if ev.one_time and ev.id in state.fired_one_time_events:
			continue
		if ev.is_eligible(context):
			eligible.append(ev)
			total_weight += ev.weight

	if eligible.is_empty() or total_weight <= 0.0:
		return []

	var count := randi_range(1, mini(3, eligible.size()))
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

	return picked


static func _weighted_pick(pool: Array[EventData]) -> EventData:
	var total := 0.0
	for ev in pool:
		total += maxf(ev.weight, 0.01)
	if total <= 0.0:
		return null

	var roll := randf() * total
	var cumulative := 0.0
	for ev in pool:
		cumulative += maxf(ev.weight, 0.01)
		if roll <= cumulative:
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
	}
