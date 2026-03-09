class_name CompanyData
extends Resource

enum CompanyType { SAAS, CONSUMER, MARKETPLACE, DEV_TOOLS }
enum FounderBackground { ENGINEER, FINANCE, RECRUITER, HUSTLER }

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

const OFFICE_CAPACITY := {0: 4, 1: 10, 2: 25, 3: 60}
const OFFICE_NAMES := {0: "Garage", 1: "Small Office", 2: "Mid-Size Office", 3: "HQ"}

const TYPE_NAMES := {
	CompanyType.SAAS: "SaaS B2B",
	CompanyType.CONSUMER: "Consumer App",
	CompanyType.MARKETPLACE: "Marketplace",
	CompanyType.DEV_TOOLS: "Dev Tools",
}

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


func founder_stat(key: String) -> int:
	return int(founder_stats.get(key, 5))


func office_capacity() -> int:
	return OFFICE_CAPACITY.get(office_level, 4)


func office_name() -> String:
	return OFFICE_NAMES.get(office_level, "Unknown")


func type_name() -> String:
	return TYPE_NAMES.get(type, "Unknown")


func clamp_all() -> void:
	reputation = clampi(reputation, 0, 100)
	equity_owned = clampf(equity_owned, 0.0, 100.0)
	office_level = clampi(office_level, 0, 3)
	cash = maxf(cash, -1_000_000.0)  # allow some debt, but cap it
