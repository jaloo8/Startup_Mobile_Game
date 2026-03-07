class_name CompanyData
extends Resource

enum CompanyType { SAAS, CONSUMER, MARKETPLACE, DEV_TOOLS }

@export var company_name: String = ""
@export var type: CompanyType = CompanyType.SAAS
@export var founded_quarter: int = 1
@export var cash: float = 150_000.0
@export var valuation: float = 0.0
@export var equity_owned: float = 100.0
@export var office_level: int = 0
@export var reputation: int = 50

const OFFICE_CAPACITY := {0: 4, 1: 10, 2: 25, 3: 60}
const OFFICE_NAMES := {0: "Garage", 1: "Small Office", 2: "Mid-Size Office", 3: "HQ"}

const TYPE_NAMES := {
	CompanyType.SAAS: "SaaS B2B",
	CompanyType.CONSUMER: "Consumer App",
	CompanyType.MARKETPLACE: "Marketplace",
	CompanyType.DEV_TOOLS: "Dev Tools",
}


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
