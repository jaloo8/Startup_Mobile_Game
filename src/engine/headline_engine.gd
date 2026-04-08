class_name HeadlineEngine
extends RefCounted
## Picks and fills contextual news headlines each quarter.

static var _templates: Array[Dictionary] = []

const TYPE_TO_KEY: Dictionary = {
	CompanyData.CompanyType.SAAS: "saas",
	CompanyData.CompanyType.CONSUMER: "consumer",
	CompanyData.CompanyType.MARKETPLACE: "marketplace",
	CompanyData.CompanyType.DEV_TOOLS: "dev_tools",
}
const NICHE_HEADLINE_KEYWORDS: Dictionary = {
	"streaming_service": ["stream", "video", "creator", "subscription", "content"],
	"fitness_companion": ["fitness", "wellness", "habit", "health", "subscription"],
	"local_discovery": ["local", "neighborhood", "events", "city", "community"],
	"vertical_crm": ["crm", "pipeline", "sales", "enterprise", "retention"],
	"workflow_automation": ["automation", "workflow", "ops", "productivity", "efficiency"],
	"compliance_ops": ["compliance", "regulation", "audit", "risk", "security"],
	"home_services": ["home", "service", "provider", "booking", "marketplace"],
	"resale_goods": ["resale", "listing", "seller", "peer", "marketplace"],
	"food_delivery_hub": ["delivery", "food", "logistics", "courier", "marketplace"],
	"api_observability": ["api", "observability", "latency", "uptime", "incident"],
	"ci_automation": ["ci", "pipeline", "build", "deploy", "automation"],
	"cloud_cost_tools": ["cloud", "cost", "infrastructure", "spend", "optimization"],
}

const NEWS_SOURCES: Array = [
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

	var result: Array[String] = []
	var used_sources: Array[String] = []
	var pool: Array[Dictionary] = eligible.duplicate()
	for _i in mini(count, pool.size()):
		var selected: Dictionary = _weighted_template_pick(pool, ctx)
		if selected.is_empty():
			break
		pool.erase(selected)
		var tmpl: String = selected.get("template", "")
		var variations: Array = selected.get("variations", [])
		if not variations.is_empty() and randf() > 0.5:
			tmpl = variations.pick_random()
		var line := _fill_template(tmpl, ctx)
		var source: String = selected.get("source", "")
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
	if t.has("min_valuation") and float(ctx.get("valuation", 0.0)) < float(t["min_valuation"]):
		return false
	if t.has("max_valuation") and float(ctx.get("valuation", 0.0)) > float(t["max_valuation"]):
		return false
	if t.has("company_types"):
		var types_raw: Array = t.get("company_types", [])
		if types_raw is Array:
			var type_key: String = str(ctx.get("company_type_key", ""))
			if type_key not in types_raw:
				return false
	if t.has("niches"):
		var niches_raw: Array = t.get("niches", [])
		if niches_raw is Array:
			var niche_id: String = str(ctx.get("niche_id", ""))
			if niche_id.is_empty() or niche_id not in niches_raw:
				return false
	return true


static func _weighted_template_pick(pool: Array[Dictionary], ctx: Dictionary) -> Dictionary:
	var candidates: Array[Dictionary] = []
	var cumulative: Array[float] = []
	var total := 0.0
	for t in pool:
		var weight: float = _template_weight(t, ctx)
		if weight <= 0.0:
			continue
		total += weight
		candidates.append(t)
		cumulative.append(total)
	if candidates.is_empty() or total <= 0.0:
		return {}
	var roll := randf() * total
	for i in range(candidates.size()):
		if roll <= cumulative[i]:
			return candidates[i]
	return candidates.back()


static func _template_weight(template_row: Dictionary, ctx: Dictionary) -> float:
	var weight: float = maxf(float(template_row.get("weight", 1.0)), 0.05)
	var niche_id: String = str(ctx.get("niche_id", "")).strip_edges()
	var text: String = str(template_row.get("template", "")).to_lower()

	if not niche_id.is_empty():
		var niche_filters: Array = template_row.get("niches", [])
		if niche_filters is Array and not niche_filters.is_empty():
			weight *= 1.9 if niche_id in niche_filters else 0.22
		else:
			var keywords: Array = NICHE_HEADLINE_KEYWORDS.get(niche_id, [])
			if not keywords.is_empty():
				var hits: int = 0
				for raw_kw in keywords:
					var kw: String = str(raw_kw).strip_edges().to_lower()
					if kw.is_empty():
						continue
					if text.find(kw) >= 0:
						hits += 1
				if hits > 0:
					weight *= clampf(1.0 + float(hits) * 0.18, 1.0, 1.65)

	var company_types: Array = template_row.get("company_types", [])
	if company_types is Array and not company_types.is_empty():
		var type_key: String = str(ctx.get("company_type_key", ""))
		weight *= 1.12 if type_key in company_types else 0.20

	return maxf(weight, 0.05)


static func _build_context(state: Node) -> Dictionary:
	var economy_label: String
	match state.market.economy_state:
		MarketData.EconomyState.BULL: economy_label = "bull"
		MarketData.EconomyState.BEAR: economy_label = "bear"
		_: economy_label = "neutral"

	var type_key: String = TYPE_TO_KEY.get(state.company.type, "consumer")
	var niche_id: String = str(state.company.niche_id).strip_edges()
	var competitor_name: String = _pick_relevant_competitor_name(state, type_key, niche_id)
	var type_label: String = CompanyData.TYPE_NAMES.get(state.company.type, "tech")

	return {
		"competitor": competitor_name,
		"economy_label": economy_label,
		"company_type_key": type_key,
		"niche_id": niche_id,
		"type_label": type_label,
		"company_name": state.company.company_name,
		"users": state.product.users,
		"total_quarters": state.total_quarters_elapsed(),
		"valuation": state.company.valuation,
		"year": state.current_year,
		"quarter": state.current_quarter,
		"world_event_title": state.active_world_event_title if int(state.active_world_event_quarters_left) > 0 else "steady conditions",
	}


static func _pick_relevant_competitor_name(state: Node, type_key: String, niche_id: String) -> String:
	if state.market.competitors.is_empty():
		return "a rival startup"

	var same_type: Array[Dictionary] = []
	var same_niche: Array[Dictionary] = []
	for raw in state.market.competitors:
		if not (raw is Dictionary):
			continue
		var comp: Dictionary = raw
		if str(comp.get("focus", "")) != type_key:
			continue
		same_type.append(comp)
		if niche_id.is_empty():
			continue
		var raw_niches: Array = comp.get("niches", [])
		if raw_niches is Array and niche_id in raw_niches:
			same_niche.append(comp)

	if not same_niche.is_empty():
		var cn: Dictionary = same_niche.pick_random()
		return str(cn.get("name", "a rival startup"))
	if not same_type.is_empty():
		var ct: Dictionary = same_type.pick_random()
		return str(ct.get("name", "a rival startup"))

	var any_comp_raw: Variant = state.market.competitors.pick_random()
	if any_comp_raw is Dictionary:
		var any_comp: Dictionary = any_comp_raw
		return str(any_comp.get("name", "a rival startup"))
	return "a rival startup"


static func _fill_template(tmpl: String, ctx: Dictionary) -> String:
	var result := tmpl
	for key in ctx:
		result = result.replace("{%s}" % key, str(ctx[key]))
	return TemplateEngine._strip_unresolved(result)
