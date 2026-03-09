class_name HeadlineEngine
extends RefCounted
## Picks and fills contextual news headlines each quarter.

static var _templates: Array[Dictionary] = []

const NEWS_SOURCES := [
	"Bloomburg Tech",
	"TekCrunch",
	"The Verj",
	"CNBS",
	"The Informant",
	"Wired Up",
	"ReVox",
	"Wall Street Journo",
	"Bits & Bytes Daily",
	"Fast Startup",
	"Ars Teknika",
	"The Silicon Herald",
]


static func load_headlines(path: String) -> void:
	_templates.clear()
	if not FileAccess.file_exists(path):
		push_warning("HeadlineEngine: file not found: %s" % path)
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var text := file.get_as_text()
	file = null
	var json := JSON.new()
	if json.parse(text) != OK:
		push_error("HeadlineEngine: JSON parse error")
		return
	if json.data is Array:
		for entry in json.data:
			if entry is Dictionary:
				_templates.append(entry)


static func generate_headlines(state: Node, count: int = 2) -> Array[String]:
	if _templates.is_empty():
		return []
	if state.company == null or state.product == null or state.market == null:
		return []

	var ctx := _build_context(state)
	var eligible: Array[Dictionary] = []

	for t in _templates:
		if _matches_filters(t, ctx):
			eligible.append(t)

	if eligible.is_empty():
		return []

	eligible.shuffle()
	var result: Array[String] = []
	var used_sources: Array[String] = []
	for i in mini(count, eligible.size()):
		var tmpl: String = eligible[i].get("template", "")
		var variations: Array = eligible[i].get("variations", [])
		if not variations.is_empty() and randf() > 0.5:
			tmpl = variations.pick_random()
		var line := _fill_template(tmpl, ctx)
		var source: String = eligible[i].get("source", "")
		if source.is_empty():
			source = _pick_unique_source(used_sources)
		used_sources.append(source)
		result.append("%s — %s" % [line, source])

	return result


static func _pick_unique_source(used: Array[String]) -> String:
	var available: Array[String] = []
	for s in NEWS_SOURCES:
		if s not in used:
			available.append(s)
	if available.is_empty():
		return NEWS_SOURCES.pick_random()
	return available.pick_random()


static func _matches_filters(t: Dictionary, ctx: Dictionary) -> bool:
	if t.has("economy") and t["economy"] != ctx.get("economy_label", ""):
		return false
	if t.has("min_users") and ctx.get("users", 0) < int(t["min_users"]):
		return false
	if t.has("min_quarter") and ctx.get("total_quarters", 0) < int(t["min_quarter"]):
		return false
	return true


static func _build_context(state: Node) -> Dictionary:
	var competitor_name := "a rival startup"
	if not state.market.competitors.is_empty():
		var c: Dictionary = state.market.competitors.pick_random()
		competitor_name = c.get("name", "a rival startup")

	var economy_label: String
	match state.market.economy_state:
		MarketData.EconomyState.BULL: economy_label = "bull"
		MarketData.EconomyState.BEAR: economy_label = "bear"
		_: economy_label = "neutral"

	var type_label: String = CompanyData.TYPE_NAMES.get(state.company.type, "tech")

	return {
		"competitor": competitor_name,
		"economy_label": economy_label,
		"type_label": type_label,
		"company_name": state.company.company_name,
		"users": state.product.users,
		"total_quarters": state.total_quarters_elapsed(),
		"year": state.current_year,
		"quarter": state.current_quarter,
	}


static func _fill_template(tmpl: String, ctx: Dictionary) -> String:
	var result := tmpl
	for key in ctx:
		result = result.replace("{%s}" % key, str(ctx[key]))
	return TemplateEngine._strip_unresolved(result)
