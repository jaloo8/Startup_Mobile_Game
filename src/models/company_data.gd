class_name CompanyData
extends Resource

enum CompanyType { SAAS, CONSUMER, MARKETPLACE, DEV_TOOLS }
enum FounderBackground { ENGINEER, FINANCE, RECRUITER, HUSTLER }
enum HostingPlan { MANAGED_CLOUD, HYBRID, IN_HOUSE }

@export var company_name: String = ""
@export var type: CompanyType = CompanyType.SAAS
@export var founded_quarter: int = 1
@export var cash: float = 150_000.0
@export var valuation: float = 0.0
@export var equity_owned: float = 100.0
@export var office_level: int = 0
@export var reputation: int = 50
@export var founder_background: FounderBackground = FounderBackground.ENGINEER
@export var founder_stats: Dictionary = {"technical": 5, "finance": 5, "people": 5, "business": 5}
@export var niche_id: String = ""
@export var niche_name: String = ""
@export var niche_desc: String = ""
@export var niche_growth_mult: float = 1.0
@export var niche_churn_mult: float = 1.0
@export var niche_revenue_mult: float = 1.0
@export var hosting_plan: HostingPlan = HostingPlan.MANAGED_CLOUD
@export var hosting_reliability: float = 99.5
@export var hosting_demand_web: float = 0.0
@export var hosting_demand_cache: float = 0.0
@export var hosting_demand_data: float = 0.0
@export var hosting_capacity_web: float = 0.0
@export var hosting_capacity_cache: float = 0.0
@export var hosting_capacity_data: float = 0.0
@export var hosting_util_web: float = 0.0
@export var hosting_util_cache: float = 0.0
@export var hosting_util_data: float = 0.0
@export var hosting_overage_cost: float = 0.0
@export var hosting_incidents_last_quarter: int = 0
@export var hosting_upgrade_web_level: int = 0
@export var hosting_upgrade_cache_level: int = 0
@export var hosting_upgrade_data_level: int = 0
@export var hosting_optimization_level: int = 0
@export var hosting_workload_profile: String = "General Cloud"
@export var hosting_data_center_pressure: float = 0.0

const OFFICE_CAPACITY := {0: 4, 1: 10, 2: 25, 3: 60}
const OFFICE_NAMES := {0: "Garage", 1: "Small Office", 2: "Mid-Size Office", 3: "HQ"}
const HOSTING_LANE_UPGRADE_MAX := 6
const HOSTING_OPTIMIZATION_MAX := 4

const TYPE_NAMES := {
	CompanyType.SAAS: "SaaS B2B",
	CompanyType.CONSUMER: "Consumer App",
	CompanyType.MARKETPLACE: "Marketplace",
	CompanyType.DEV_TOOLS: "Dev Tools",
}
const HOSTING_PLAN_NAMES := {
	HostingPlan.MANAGED_CLOUD: "Managed Cloud",
	HostingPlan.HYBRID: "Hybrid",
	HostingPlan.IN_HOUSE: "In-house",
}

const NICHES_PATH := "res://src/data/niches.json"
const DEFAULT_NICHE_MODIFIERS := {
	"growth_mult": 1.0,
	"churn_mult": 1.0,
	"revenue_mult": 1.0,
}

static var _niche_catalog: Dictionary = {}

const FOUNDER_ARCHETYPES := {
	FounderBackground.ENGINEER: {
		"name": "Engineer",
		"desc": "Technical founder — ships fast, writes code, knows the product inside out.",
		"stats": {"technical": 8, "finance": 3, "people": 4, "business": 3},
	},
	FounderBackground.FINANCE: {
		"name": "Finance",
		"desc": "Numbers person — stretches every dollar, impresses investors, reads spreadsheets for fun.",
		"stats": {"technical": 3, "finance": 8, "people": 3, "business": 5},
	},
	FounderBackground.RECRUITER: {
		"name": "Recruiter",
		"desc": "People person — builds great teams, keeps morale high, always networking.",
		"stats": {"technical": 2, "finance": 3, "people": 8, "business": 5},
	},
	FounderBackground.HUSTLER: {
		"name": "Hustler",
		"desc": "Business mind — closes deals, grows the brand, talks their way into any room.",
		"stats": {"technical": 3, "finance": 4, "people": 4, "business": 8},
	},
}

const FOUNDER_BACKGROUND_NAMES := {
	FounderBackground.ENGINEER: "Engineer",
	FounderBackground.FINANCE: "Finance",
	FounderBackground.RECRUITER: "Recruiter",
	FounderBackground.HUSTLER: "Hustler",
}


static func _safe_array(value) -> Array:
	return value if value is Array else []


static func _safe_dict(value) -> Dictionary:
	return value if value is Dictionary else {}


static func _type_key(company_type: int) -> String:
	match company_type:
		CompanyType.SAAS:
			return "saas"
		CompanyType.CONSUMER:
			return "consumer"
		CompanyType.MARKETPLACE:
			return "marketplace"
		CompanyType.DEV_TOOLS:
			return "dev_tools"
		_:
			return "consumer"


static func load_niche_catalog(path: String = NICHES_PATH) -> void:
	if not _niche_catalog.is_empty():
		return
	if not FileAccess.file_exists(path):
		push_warning("CompanyData: niches file missing: %s" % path)
		_niche_catalog = {}
		return
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_warning("CompanyData: could not open niches file: %s" % path)
		_niche_catalog = {}
		return
	var text := f.get_as_text()
	f = null
	var json := JSON.new()
	if json.parse(text) != OK or not (json.data is Dictionary):
		push_warning("CompanyData: invalid niches JSON: %s" % path)
		_niche_catalog = {}
		return
	_niche_catalog = json.data


static func niches_for_type(company_type: int) -> Array[Dictionary]:
	if _niche_catalog.is_empty():
		load_niche_catalog()
	var key := _type_key(company_type)
	var out: Array[Dictionary] = []
	for row in _safe_array(_niche_catalog.get(key, [])):
		if row is Dictionary:
			out.append(row)
	return out


static func niche_by_id(company_type: int, requested_id: String) -> Dictionary:
	var rows := niches_for_type(company_type)
	if rows.is_empty():
		return {}
	var req := requested_id.strip_edges()
	if req.is_empty():
		return rows[0]
	for row in rows:
		if str(row.get("id", "")) == req:
			return row
	return rows[0]


func founder_stat(key: String) -> int:
	return int(founder_stats.get(key, 5))


func office_capacity() -> int:
	return OFFICE_CAPACITY.get(office_level, 4)


func office_name() -> String:
	return OFFICE_NAMES.get(office_level, "Unknown")


func type_name() -> String:
	return TYPE_NAMES.get(type, "Unknown")


func type_name_with_niche() -> String:
	if niche_name.strip_edges().is_empty():
		return type_name()
	return "%s (%s)" % [type_name(), niche_name]


func hosting_plan_name() -> String:
	return HOSTING_PLAN_NAMES.get(hosting_plan, "Managed Cloud")


func apply_niche(requested_id: String) -> void:
	var chosen := niche_by_id(type, requested_id)
	if chosen.is_empty():
		niche_id = ""
		niche_name = ""
		niche_desc = ""
		niche_growth_mult = 1.0
		niche_churn_mult = 1.0
		niche_revenue_mult = 1.0
		return

	niche_id = str(chosen.get("id", "")).strip_edges()
	niche_name = str(chosen.get("name", "")).strip_edges()
	niche_desc = str(chosen.get("description", "")).strip_edges()
	var mods := _safe_dict(chosen.get("modifiers", {}))
	niche_growth_mult = float(mods.get("growth_mult", DEFAULT_NICHE_MODIFIERS["growth_mult"]))
	niche_churn_mult = float(mods.get("churn_mult", DEFAULT_NICHE_MODIFIERS["churn_mult"]))
	niche_revenue_mult = float(mods.get("revenue_mult", DEFAULT_NICHE_MODIFIERS["revenue_mult"]))


func clamp_all() -> void:
	reputation = clampi(reputation, 0, 100)
	equity_owned = clampf(equity_owned, 0.0, 100.0)
	office_level = clampi(office_level, 0, 3)
	cash = maxf(cash, -1_000_000.0)  # allow some debt, but cap it
	niche_id = niche_id.strip_edges()
	niche_name = niche_name.strip_edges()
	niche_desc = niche_desc.strip_edges()
	niche_growth_mult = clampf(niche_growth_mult, 0.5, 2.0)
	niche_churn_mult = clampf(niche_churn_mult, 0.5, 2.0)
	niche_revenue_mult = clampf(niche_revenue_mult, 0.5, 2.0)
	hosting_plan = clampi(hosting_plan, 0, 2) as HostingPlan
	hosting_reliability = clampf(hosting_reliability, 60.0, 99.99)
	hosting_demand_web = clampf(hosting_demand_web, 0.0, 1e12)
	hosting_demand_cache = clampf(hosting_demand_cache, 0.0, 1e12)
	hosting_demand_data = clampf(hosting_demand_data, 0.0, 1e12)
	hosting_capacity_web = clampf(hosting_capacity_web, 0.0, 1e12)
	hosting_capacity_cache = clampf(hosting_capacity_cache, 0.0, 1e12)
	hosting_capacity_data = clampf(hosting_capacity_data, 0.0, 1e12)
	hosting_util_web = clampf(hosting_util_web, 0.0, 5.0)
	hosting_util_cache = clampf(hosting_util_cache, 0.0, 5.0)
	hosting_util_data = clampf(hosting_util_data, 0.0, 5.0)
	hosting_overage_cost = clampf(hosting_overage_cost, 0.0, 1e12)
	hosting_incidents_last_quarter = clampi(hosting_incidents_last_quarter, 0, 99)
	hosting_upgrade_web_level = clampi(hosting_upgrade_web_level, 0, HOSTING_LANE_UPGRADE_MAX)
	hosting_upgrade_cache_level = clampi(hosting_upgrade_cache_level, 0, HOSTING_LANE_UPGRADE_MAX)
	hosting_upgrade_data_level = clampi(hosting_upgrade_data_level, 0, HOSTING_LANE_UPGRADE_MAX)
	hosting_optimization_level = clampi(hosting_optimization_level, 0, HOSTING_OPTIMIZATION_MAX)
	hosting_workload_profile = hosting_workload_profile.strip_edges()
	if hosting_workload_profile.is_empty():
		hosting_workload_profile = "General Cloud"
	hosting_data_center_pressure = clampf(hosting_data_center_pressure, 0.0, 3.0)
	for stat_key in ["technical", "finance", "people", "business"]:
		founder_stats[stat_key] = clampi(int(founder_stats.get(stat_key, 5)), 1, 10)
