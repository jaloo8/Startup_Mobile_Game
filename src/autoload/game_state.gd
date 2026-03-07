extends Node
## Autoload singleton — single source of truth for all run state.
## Access anywhere via GameState (registered in project.godot).

signal quarter_advanced(quarter_number: int)
signal game_over(reason: String)
@warning_ignore("unused_signal")
signal event_triggered(event: EventData)
@warning_ignore("unused_signal")
signal employee_quit(employee: EmployeeData)

var company: CompanyData
var employees: Array[EmployeeData] = []
var product: ProductData
var financials: FinancialsData
var market: MarketData

var current_quarter: int = 1
var current_year: int = 1
var difficulty: String = "normal"
var starting_scenario: String = "garage"

var history: Array[Dictionary] = []
var event_log: Array[Dictionary] = []
var fired_one_time_events: Array[String] = []
var pending_events: Array[EventData] = []

var is_game_active: bool = false

const SAVE_DIR := "user://saves/"
const MAX_HISTORY_SIZE := 200
const MAX_EVENT_LOG_SIZE := 500
const DIFFICULTY_MULTS := {
	"sandbox": {"cash_mult": 2.0, "churn_mult": 0.5, "competitor_mult": 0.5},
	"normal": {"cash_mult": 1.0, "churn_mult": 1.0, "competitor_mult": 1.0},
	"hardcore": {"cash_mult": 0.6, "churn_mult": 1.5, "competitor_mult": 1.5},
}

var _save_thread: Thread
var _save_mutex: Mutex


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	_save_mutex = Mutex.new()


func _exit_tree() -> void:
	if _save_thread and _save_thread.is_started():
		_save_thread.wait_to_finish()
	_save_thread = null


func new_game(config: Dictionary) -> void:
	company = CompanyData.new()
	company.company_name = config.get("name", "My Startup")
	company.type = config.get("type", CompanyData.CompanyType.SAAS)

	product = ProductData.new()
	financials = FinancialsData.new()
	market = MarketData.new()
	employees.clear()
	history.clear()
	event_log.clear()
	fired_one_time_events.clear()
	pending_events.clear()

	difficulty = config.get("difficulty", "normal")
	starting_scenario = config.get("scenario", "garage")
	_apply_starting_scenario()

	current_quarter = 1
	current_year = 1
	is_game_active = true


func _apply_starting_scenario() -> void:
	var cash_mult: float = DIFFICULTY_MULTS.get(difficulty, {}).get("cash_mult", 1.0)
	match starting_scenario:
		"garage":
			company.cash = 20_000.0 * cash_mult
			company.office_level = 0
		"accelerator":
			company.cash = 125_000.0 * cash_mult
			company.office_level = 0
		"spinoff":
			company.cash = 500_000.0 * cash_mult
			company.office_level = 1
		"vc_backed":
			company.cash = 2_000_000.0 * cash_mult
			company.office_level = 1
			financials = FinancialsData.new()
			financials.funding_rounds.append({
				"round": "Seed",
				"amount": 2_000_000.0 * cash_mult,
				"valuation": 8_000_000.0,
				"quarter": 0,
			})
			company.equity_owned = 75.0


func difficulty_mult(key: String) -> float:
	return DIFFICULTY_MULTS.get(difficulty, {}).get(key, 1.0)


func advance_quarter() -> void:
	if not is_game_active:
		return
	if company == null or product == null or financials == null:
		push_error("GameState: cannot advance — game not initialized")
		return

	SimulationEngine.process_quarter(self)

	_take_snapshot()
	current_quarter += 1
	if current_quarter > 4:
		current_quarter = 1
		current_year += 1

	quarter_advanced.emit(current_quarter)
	_check_end_conditions()
	auto_save()


func total_quarters_elapsed() -> int:
	return (current_year - 1) * 4 + (current_quarter - 1)


func hire_employee(emp: EmployeeData) -> bool:
	if employees.size() >= company.office_capacity():
		return false
	employees.append(emp)
	return true


func fire_employee(emp: EmployeeData) -> void:
	employees.erase(emp)


func _take_snapshot() -> void:
	history.append({
		"quarter": current_quarter,
		"year": current_year,
		"cash": company.cash,
		"users": product.users,
		"employees": employees.size(),
		"revenue": financials.revenue,
		"burn_rate": financials.burn_rate,
		"tech_debt": product.tech_debt,
	})
	if history.size() > MAX_HISTORY_SIZE:
		history = history.slice(-MAX_HISTORY_SIZE)


func _check_end_conditions() -> void:
	if company.cash <= 0 and financials.revenue < financials.burn_rate:
		is_game_active = false
		game_over.emit("bankruptcy")
	elif product.users <= 0 and total_quarters_elapsed() > 12:
		is_game_active = false
		game_over.emit("dead_product")


func append_event_log(entry: Dictionary) -> void:
	event_log.append(entry)
	if event_log.size() > MAX_EVENT_LOG_SIZE:
		event_log = event_log.slice(-MAX_EVENT_LOG_SIZE)


# --- Save / Load (threaded to avoid mobile stutter) ---

func auto_save() -> void:
	save_game_async("autosave")


func save_game_async(slot_name: String) -> void:
	_save_mutex.lock()
	var data := _serialize()
	_save_mutex.unlock()

	if _save_thread and _save_thread.is_started():
		_save_thread.wait_to_finish()

	_save_thread = Thread.new()
	_save_thread.start(_threaded_save.bind(slot_name, data))


func _threaded_save(slot_name: String, data: Dictionary) -> void:
	var path := SAVE_DIR + slot_name + ".json"
	var json_text := JSON.stringify(data, "\t")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("GameState: failed to write save: %s" % path)
		return
	file.store_string(json_text)
	file = null


func save_game(slot_name: String) -> bool:
	var data := _serialize()
	var path := SAVE_DIR + slot_name + ".json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("GameState: failed to open save file: %s" % path)
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file = null
	return true


func load_game(slot_name: String) -> bool:
	var path := SAVE_DIR + slot_name + ".json"
	if not FileAccess.file_exists(path):
		push_warning("GameState: save file not found: %s" % path)
		return false

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("GameState: failed to open save file: %s" % path)
		return false

	var text := file.get_as_text()
	file = null

	var json := JSON.new()
	if json.parse(text) != OK:
		push_error("GameState: failed to parse save file")
		return false

	if not json.data is Dictionary:
		push_error("GameState: save file is not a dictionary")
		return false

	return _deserialize(json.data)


func has_save(slot_name: String) -> bool:
	return FileAccess.file_exists(SAVE_DIR + slot_name + ".json")


func _serialize() -> Dictionary:
	var emp_list: Array[Dictionary] = []
	for emp in employees:
		emp_list.append({
			"name": emp.employee_name,
			"specialty": emp.specialty,
			"seniority": emp.seniority,
			"skill": emp.skill,
			"speed": emp.speed,
			"growth_potential": emp.growth_potential,
			"salary": emp.salary_per_quarter,
			"morale": emp.morale,
			"stress": emp.stress,
			"culture_fit": emp.culture_fit,
			"tenure": emp.tenure_quarters,
			"assignment": emp.assignment,
		})

	return {
		"version": 1,
		"company": {
			"name": company.company_name,
			"type": company.type,
			"cash": company.cash,
			"valuation": company.valuation,
			"equity": company.equity_owned,
			"office_level": company.office_level,
			"reputation": company.reputation,
		},
		"product": {
			"features": product.features,
			"tech_debt": product.tech_debt,
			"bugs": product.bugs,
			"stability": product.stability,
			"ux_score": product.ux_score,
			"users": product.users,
			"dau": product.dau,
			"churn_rate": product.churn_rate,
			"feature_progress": product.feature_progress,
		},
		"financials": {
			"revenue": financials.revenue,
			"burn_rate": financials.burn_rate,
			"costs": financials.costs_breakdown,
			"funding_rounds": financials.funding_rounds,
			"investors": financials.investors,
		},
		"market": {
			"competitors": market.competitors,
			"trend": market.market_trend,
			"economy": market.economy_state,
		},
		"employees": emp_list,
		"quarter": current_quarter,
		"year": current_year,
		"difficulty": difficulty,
		"scenario": starting_scenario,
		"history": history,
		"event_log": event_log,
		"fired_events": fired_one_time_events,
	}


func _deserialize(data: Dictionary) -> bool:
	if data.get("version", 0) != 1:
		push_error("GameState: unsupported save version")
		return false

	company = CompanyData.new()
	var cd: Dictionary = data.get("company", {})
	company.company_name = cd.get("name", "")
	company.type = cd.get("type", 0)
	company.cash = cd.get("cash", 0.0)
	company.valuation = cd.get("valuation", 0.0)
	company.equity_owned = cd.get("equity", 100.0)
	company.office_level = cd.get("office_level", 0)
	company.reputation = cd.get("reputation", 50)

	product = ProductData.new()
	var pd: Dictionary = data.get("product", {})
	product.features = pd.get("features", [])
	product.tech_debt = pd.get("tech_debt", 0)
	product.bugs = pd.get("bugs", 0)
	product.stability = pd.get("stability", 80)
	product.ux_score = pd.get("ux_score", 50)
	product.users = pd.get("users", 0)
	product.dau = pd.get("dau", 0)
	product.churn_rate = pd.get("churn_rate", 0.05)
	product.feature_progress = pd.get("feature_progress", 0.0)

	financials = FinancialsData.new()
	var fd: Dictionary = data.get("financials", {})
	financials.revenue = fd.get("revenue", 0.0)
	financials.burn_rate = fd.get("burn_rate", 0.0)
	financials.costs_breakdown = fd.get("costs", {})
	financials.funding_rounds = fd.get("funding_rounds", [])
	financials.investors = fd.get("investors", [])

	market = MarketData.new()
	var md: Dictionary = data.get("market", {})
	market.competitors = md.get("competitors", [])
	market.market_trend = md.get("trend", 0)
	market.economy_state = md.get("economy", 0)

	employees.clear()
	for ed: Dictionary in data.get("employees", []):
		var emp := EmployeeData.new()
		emp.employee_name = ed.get("name", "")
		emp.specialty = ed.get("specialty", 0)
		emp.seniority = ed.get("seniority", 0)
		emp.skill = ed.get("skill", 50)
		emp.speed = ed.get("speed", 50)
		emp.growth_potential = ed.get("growth_potential", 1)
		emp.salary_per_quarter = ed.get("salary", 20_000.0)
		emp.morale = ed.get("morale", 75)
		emp.stress = ed.get("stress", 0)
		emp.culture_fit = ed.get("culture_fit", 50)
		emp.tenure_quarters = ed.get("tenure", 0)
		emp.assignment = ed.get("assignment", EmployeeData.Assignment.UNASSIGNED)
		employees.append(emp)

	current_quarter = data.get("quarter", 1)
	current_year = data.get("year", 1)
	difficulty = data.get("difficulty", "normal")
	starting_scenario = data.get("scenario", "garage")
	history = data.get("history", [])
	event_log = data.get("event_log", [])
	fired_one_time_events = data.get("fired_events", [])

	is_game_active = true
	return true
