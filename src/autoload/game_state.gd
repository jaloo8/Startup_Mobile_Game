extends Node
## Holds all game state. Access via GameState.

signal quarter_advanced(quarter_number: int)
signal game_over(reason: String)
signal save_error(message: String)
@warning_ignore("unused_signal")
signal game_won(win_type: String)
@warning_ignore("unused_signal")
signal event_triggered(event: EventData)
@warning_ignore("unused_signal")
signal employee_quit(employee: EmployeeData)
@warning_ignore("unused_signal")
signal feature_shipped(feature_name: String, quality: int)

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
var current_slot: String = ""
var angel_bailout_used: bool = false
var profit_streak: int = 0
var founder_energy: int = 100
var board_patience: int = 4
var _milestones_hit: Array[String] = []

const SAVE_DIR := "user://saves/"
const SLOT_NAMES := ["slot_1", "slot_2", "slot_3", "slot_4", "slot_5"]


static func _safe_array(value) -> Array:
	return value if value is Array else []
const MAX_SLOTS := 5
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
	var err := DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	if err != OK and err != ERR_ALREADY_EXISTS:
		push_error("GameState: failed to create save directory (%d)" % err)
	_save_mutex = Mutex.new()


func _exit_tree() -> void:
	if _save_thread and _save_thread.is_started():
		_save_thread.wait_to_finish()
	_save_thread = null


func new_game(config: Dictionary) -> void:
	company = CompanyData.new()
	company.company_name = config.get("name", "My Startup")
	company.type = config.get("type", CompanyData.CompanyType.SAAS)

	var bg_key: int = config.get("founder_background", CompanyData.FounderBackground.ENGINEER)
	company.founder_background = bg_key as CompanyData.FounderBackground
	var arch: Dictionary = CompanyData.FOUNDER_ARCHETYPES.get(bg_key, {})
	company.founder_stats = arch.get("stats", {"technical": 5, "finance": 5, "people": 5, "business": 5}).duplicate()

	product = ProductData.new()
	financials = FinancialsData.new()
	market = MarketData.new()
	employees.clear()
	history.clear()
	event_log.clear()
	fired_one_time_events.clear()
	pending_events.clear()
	_milestones_hit.clear()
	angel_bailout_used = false
	profit_streak = 0
	founder_energy = 100
	board_patience = 4

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

	var features_before: int = product.feature_count()
	SimulationEngine.process_quarter(self)

	# Fire celebration signal if a new feature shipped this quarter
	if product.feature_count() > features_before:
		var newest: Dictionary = product.features.back()
		feature_shipped.emit(newest.get("name", "Feature"), newest.get("quality", 0))

	_take_snapshot()
	current_quarter += 1
	if current_quarter > 4:
		current_quarter = 1
		current_year += 1

	quarter_advanced.emit(current_quarter)
	_check_milestone_bonuses()
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
	if financials.revenue > financials.burn_rate:
		profit_streak += 1
	else:
		profit_streak = 0

	var arr: float = financials.revenue * 4.0
	if arr >= 100_000_000 and product.users >= 100_000:
		is_game_active = false
		game_won.emit("ipo")
		return
	if company.valuation >= 1_000_000_000:
		is_game_active = false
		game_won.emit("unicorn")
		return
	if profit_streak >= 4 and total_quarters_elapsed() >= 12:
		is_game_active = false
		game_won.emit("sustainable")
		return

	if founder_energy <= 0:
		is_game_active = false
		game_over.emit("founder_burnout")
		return

	if not financials.funding_rounds.is_empty() and board_patience <= 0:
		is_game_active = false
		game_over.emit("board_takeover")
		return

	if company.cash <= 0 and financials.revenue < financials.burn_rate:
		is_game_active = false
		game_over.emit("bankruptcy")
	elif product.users <= 0 and total_quarters_elapsed() > 12:
		is_game_active = false
		game_over.emit("dead_product")


const MILESTONES := {
	"100_users": {"threshold_users": 100, "bonus": 25_000.0, "title": "Milestone: 100 users — investors released a $25K tranche"},
	"1k_users": {"threshold_users": 1000, "bonus": 50_000.0, "title": "Milestone: 1K users — investors released a $50K tranche"},
	"first_revenue": {"threshold_revenue": 1.0, "bonus": 15_000.0, "title": "First revenue! Investors released a $15K bonus"},
	"10k_users": {"threshold_users": 10000, "bonus": 100_000.0, "title": "Milestone: 10K users — investors released a $100K tranche"},
}


func _check_milestone_bonuses() -> void:
	if financials.funding_rounds.is_empty():
		return

	for key: String in MILESTONES:
		if key in _milestones_hit:
			continue
		var m: Dictionary = MILESTONES[key]
		var hit := false
		if m.has("threshold_users") and product.users >= m["threshold_users"]:
			hit = true
		if m.has("threshold_revenue") and financials.revenue >= m["threshold_revenue"]:
			hit = true
		if hit:
			_milestones_hit.append(key)
			company.cash += m["bonus"]
			Analytics.track_milestone_bonus(key, m["bonus"])
			append_event_log({
				"quarter": current_quarter,
				"year": current_year,
				"event_id": "milestone_" + key,
				"title": m["title"],
			})


func append_event_log(entry: Dictionary) -> void:
	event_log.append(entry)
	if event_log.size() > MAX_EVENT_LOG_SIZE:
		event_log = event_log.slice(-MAX_EVENT_LOG_SIZE)


# --- Save / Load ---

func auto_save() -> void:
	if current_slot.is_empty():
		return
	save_game_async(current_slot)


func save_game_async(slot_name: String) -> void:
	_save_mutex.lock()
	var data := _serialize()
	_save_mutex.unlock()

	if _save_thread and _save_thread.is_started():
		_save_thread.wait_to_finish()

	_save_thread = Thread.new()
	_save_thread.start(_threaded_save.bind(slot_name, data))


func _threaded_save(slot_name: String, data: Dictionary) -> void:
	if slot_name not in SLOT_NAMES:
		push_error("GameState: invalid slot name: %s" % slot_name)
		return
	_atomic_write(SAVE_DIR + slot_name + ".json", data)


func save_game(slot_name: String) -> bool:
	if slot_name not in SLOT_NAMES:
		push_error("GameState: invalid slot name: %s" % slot_name)
		return false
	var data := _serialize()
	if data.is_empty():
		save_error.emit("Could not save — game state not initialized")
		return false
	var ok := _atomic_write(SAVE_DIR + slot_name + ".json", data)
	if not ok:
		save_error.emit("Save failed — please check your device storage")
	return ok


static func _atomic_write(path: String, data: Dictionary) -> bool:
	var payload_text := JSON.stringify(data, "\t")
	var checksum := payload_text.sha256_text()
	var wrapper := {"_checksum": checksum, "data": data}
	var json_text := JSON.stringify(wrapper, "\t")

	var tmp_path := path + ".tmp"
	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		push_error("GameState: failed to write temp save: %s" % tmp_path)
		return false
	file.store_string(json_text)
	file = null

	var dir := DirAccess.open(SAVE_DIR)
	if dir == null:
		push_error("GameState: cannot access save directory")
		return false
	var err := dir.rename(tmp_path, path)
	if err != OK:
		push_error("GameState: rename failed (%d) %s -> %s" % [err, tmp_path, path])
		return false
	return true


func load_game(slot_name: String) -> bool:
	if slot_name not in SLOT_NAMES:
		push_error("GameState: invalid slot name: %s" % slot_name)
		return false

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

	var raw: Dictionary = json.data
	var game_data: Dictionary
	if raw.has("_checksum") and raw.has("data"):
		var stored_checksum: String = str(raw.get("_checksum", ""))
		game_data = raw.get("data", {})
		var expected := JSON.stringify(game_data, "\t").sha256_text()
		if stored_checksum != expected:
			push_warning("GameState: save checksum mismatch — file may be tampered")
	else:
		game_data = raw

	return _deserialize(game_data)


func has_save(slot_name: String) -> bool:
	return FileAccess.file_exists(SAVE_DIR + slot_name + ".json")


func _serialize() -> Dictionary:
	if company == null or product == null or financials == null or market == null:
		push_error("GameState: cannot serialize — game state not initialized")
		return {}

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
			"founder_background": company.founder_background,
			"founder_stats": company.founder_stats,
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
			"target_feature_id": product.target_feature_id,
			"revenue_mult": product.revenue_mult,
			"user_growth_flat_bonus": product.user_growth_flat_bonus,
			"dau_bonus": product.dau_bonus,
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
		"milestones_hit": _milestones_hit,
		"angel_bailout_used": angel_bailout_used,
		"profit_streak": profit_streak,
		"founder_energy": founder_energy,
		"board_patience": board_patience,
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
	company.founder_background = cd.get("founder_background", 0) as CompanyData.FounderBackground
	company.founder_stats = cd.get("founder_stats", {"technical": 5, "finance": 5, "people": 5, "business": 5})

	product = ProductData.new()
	var pd: Dictionary = data.get("product", {})
	product.features.assign(_safe_array(pd.get("features", [])))
	product.tech_debt = pd.get("tech_debt", 0)
	product.bugs = pd.get("bugs", 0)
	product.stability = pd.get("stability", 80)
	product.ux_score = pd.get("ux_score", 50)
	product.users = pd.get("users", 0)
	product.dau = pd.get("dau", 0)
	product.churn_rate = pd.get("churn_rate", 0.05)
	product.feature_progress = pd.get("feature_progress", 0.0)
	product.target_feature_id = pd.get("target_feature_id", "")
	product.revenue_mult = pd.get("revenue_mult", 1.0)
	product.user_growth_flat_bonus = pd.get("user_growth_flat_bonus", 0)
	product.dau_bonus = pd.get("dau_bonus", 0.0)

	financials = FinancialsData.new()
	var fd: Dictionary = data.get("financials", {})
	financials.revenue = fd.get("revenue", 0.0)
	financials.burn_rate = fd.get("burn_rate", 0.0)
	financials.costs_breakdown = fd.get("costs", {})
	financials.funding_rounds.assign(_safe_array(fd.get("funding_rounds", [])))
	financials.investors.assign(_safe_array(fd.get("investors", [])))

	market = MarketData.new()
	var md: Dictionary = data.get("market", {})
	market.competitors.assign(_safe_array(md.get("competitors", [])))
	market.market_trend = md.get("trend", 0)
	market.economy_state = md.get("economy", 0)

	employees.clear()
	for ed: Dictionary in _safe_array(data.get("employees", [])):
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
	history.assign(_safe_array(data.get("history", [])))
	event_log.assign(_safe_array(data.get("event_log", [])))
	fired_one_time_events.assign(_safe_array(data.get("fired_events", [])))
	_milestones_hit.assign(_safe_array(data.get("milestones_hit", [])))
	angel_bailout_used = data.get("angel_bailout_used", false)
	profit_streak = data.get("profit_streak", 0)
	founder_energy = data.get("founder_energy", 100)
	board_patience = data.get("board_patience", 4)

	_clamp_deserialized_values()
	is_game_active = true
	return true


func _clamp_deserialized_values() -> void:
	company.type = clampi(company.type, 0, 3)
	company.founder_background = clampi(company.founder_background, 0, 3) as CompanyData.FounderBackground
	company.cash = clampf(company.cash, -1_000_000.0, 1e12)
	company.valuation = clampf(company.valuation, 0.0, 1e13)
	company.equity_owned = clampf(company.equity_owned, 0.0, 100.0)
	company.reputation = clampi(company.reputation, 0, 100)
	company.office_level = clampi(company.office_level, 0, 10)

	product.tech_debt = clampi(product.tech_debt, 0, 100)
	product.bugs = maxi(0, product.bugs)
	product.stability = clampi(product.stability, 0, 100)
	product.ux_score = clampi(product.ux_score, 0, 100)
	product.users = clampi(product.users, 0, 1_000_000_000)
	product.dau = clampi(product.dau, 0, product.users)
	product.churn_rate = clampf(product.churn_rate, 0.0, 1.0)
	product.revenue_mult = clampf(product.revenue_mult, 0.01, 100.0)
	product.dau_bonus = clampf(product.dau_bonus, 0.0, 1.0)

	financials.revenue = maxf(0.0, financials.revenue)
	financials.burn_rate = maxf(0.0, financials.burn_rate)

	founder_energy = clampi(founder_energy, 0, 200)
	board_patience = clampi(board_patience, 0, 20)
	profit_streak = maxi(0, profit_streak)

	market.economy_state = clampi(market.economy_state, 0, 2)

	for emp in employees:
		emp.specialty = clampi(emp.specialty, 0, 8)
		emp.seniority = clampi(emp.seniority, 0, 4)
		emp.assignment = clampi(emp.assignment, 0, 5) as EmployeeData.Assignment
		emp.growth_potential = clampi(emp.growth_potential, 0, 2)
		emp.skill = clampi(emp.skill, 1, 100)
		emp.speed = clampi(emp.speed, 1, 100)
		emp.morale = clampi(emp.morale, 0, 100)
		emp.stress = clampi(emp.stress, 0, 100)
		emp.culture_fit = clampi(emp.culture_fit, 0, 100)
		emp.salary_per_quarter = clampf(emp.salary_per_quarter, 0.0, 1_000_000.0)


# --- Slot Management ---

func list_saves() -> Array[Dictionary]:
	var saves: Array[Dictionary] = []
	for slot in SLOT_NAMES:
		var info := peek_save(slot)
		info["slot"] = slot
		saves.append(info)
	return saves


func peek_save(slot_name: String) -> Dictionary:
	var path := SAVE_DIR + slot_name + ".json"
	if not FileAccess.file_exists(path):
		return {"exists": false}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"exists": false}

	var text := file.get_as_text()
	file = null
	var json := JSON.new()
	if json.parse(text) != OK:
		return {"exists": false}

	var raw: Dictionary = json.data if json.data is Dictionary else {}
	var data: Dictionary = raw.get("data", raw) if raw.has("_checksum") else raw
	var cd: Dictionary = data.get("company", {})
	var pd: Dictionary = data.get("product", {})
	var fd: Dictionary = data.get("financials", {})

	return {
		"exists": true,
		"company_name": cd.get("name", "Unknown"),
		"company_type": cd.get("type", 0),
		"cash": cd.get("cash", 0.0),
		"users": pd.get("users", 0),
		"quarter": data.get("quarter", 1),
		"year": data.get("year", 1),
		"difficulty": data.get("difficulty", "normal"),
		"revenue": fd.get("revenue", 0.0),
		"employees": data.get("employees", []).size(),
	}


func delete_save(slot_name: String) -> void:
	if slot_name not in SLOT_NAMES:
		push_error("GameState: invalid slot name for delete: %s" % slot_name)
		return
	var path := SAVE_DIR + slot_name + ".json"
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	var tmp_path := path + ".tmp"
	if FileAccess.file_exists(tmp_path):
		DirAccess.remove_absolute(tmp_path)
	if current_slot == slot_name:
		current_slot = ""
		_clear_run_state()


func _clear_run_state() -> void:
	company = null
	product = null
	financials = null
	market = null
	employees.clear()
	history.clear()
	event_log.clear()
	fired_one_time_events.clear()
	pending_events.clear()
	_milestones_hit.clear()
	angel_bailout_used = false
	profit_streak = 0
	founder_energy = 100
	board_patience = 4
	current_quarter = 1
	current_year = 1
	is_game_active = false
