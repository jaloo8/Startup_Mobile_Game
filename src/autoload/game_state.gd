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
var _achieved_wins: Array[String] = []
var interviewer_busy_quarters: Dictionary = {}  # employee_uid -> quarters remaining

const SAVE_DIR := "user://saves/"
const SLOT_NAMES := ["slot_1", "slot_2", "slot_3", "slot_4", "slot_5"]


static func _safe_array(value) -> Array:
	return value if value is Array else []


static func _safe_dict(value) -> Dictionary:
	return value if value is Dictionary else {}


static func _dict_array(value) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for item in _safe_array(value):
		if item is Dictionary:
			out.append(item)
	return out


static func _string_array(value) -> Array[String]:
	var out: Array[String] = []
	for item in _safe_array(value):
		out.append(str(item))
	return out
const MAX_SLOTS := 5
const MAX_HISTORY_SIZE := 200
const MAX_EVENT_LOG_SIZE := 500
const MAX_EMPLOYEES := 500
const MAX_SAVE_BYTES := 4 * 1024 * 1024
const SAVE_BACKUP_SUFFIX := ".bak"
const SAVE_TMP_SUFFIX := ".tmp"
# Sustainable win is intentionally later-game to preserve early momentum while
# extending run length. Feature build speed stays unchanged.
const SUSTAINABLE_MIN_QUARTERS := 20
const SUSTAINABLE_PROFIT_STREAK := 6
const SUSTAINABLE_DEFAULT_REQUIREMENTS := {
	"users": 12_000,
	"features": 8,
	"revenue_per_q": 250_000.0,
}
const SUSTAINABLE_REQUIREMENTS_BY_TYPE := {
	CompanyData.CompanyType.SAAS: {
		"users": 10_000,
		"features": 8,
		"revenue_per_q": 220_000.0,
	},
	CompanyData.CompanyType.CONSUMER: {
		"users": 16_000,
		"features": 9,
		"revenue_per_q": 240_000.0,
	},
	CompanyData.CompanyType.MARKETPLACE: {
		"users": 14_000,
		"features": 8,
		"revenue_per_q": 260_000.0,
	},
	CompanyData.CompanyType.DEV_TOOLS: {
		"users": 9_000,
		"features": 8,
		"revenue_per_q": 210_000.0,
	},
}
# Centralized difficulty knobs consumed by simulation, fundraising, and events.
# Keep these in one place so balancing passes stay predictable.
const DIFFICULTY_MULTS := {
	"sandbox": {
		"cash_mult": 2.0,
		"churn_mult": 0.5,
		"competitor_mult": 0.5,
		"fundraise_amount_mult": 1.12,
		"fundraise_threshold_shift": -0.05,
		"event_pressure_mult": 0.85,
	},
	"normal": {
		"cash_mult": 1.0,
		"churn_mult": 1.0,
		"competitor_mult": 1.0,
		"fundraise_amount_mult": 1.0,
		"fundraise_threshold_shift": 0.0,
		"event_pressure_mult": 1.0,
	},
	"hardcore": {
		"cash_mult": 0.6,
		"churn_mult": 1.5,
		"competitor_mult": 1.5,
		"fundraise_amount_mult": 0.90,
		"fundraise_threshold_shift": 0.06,
		"event_pressure_mult": 1.20,
	},
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
	_achieved_wins.clear()
	interviewer_busy_quarters.clear()
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


func has_achieved_win(win_type: String) -> bool:
	var key := win_type.strip_edges().to_lower()
	return key in _achieved_wins


func register_achieved_win(win_type: String) -> void:
	var key := win_type.strip_edges().to_lower()
	if key.is_empty():
		return
	if key not in _achieved_wins:
		_achieved_wins.append(key)


func continue_after_victory() -> void:
	# Allows post-victory sandbox play (same save, same company).
	if company == null or product == null or financials == null:
		return
	is_game_active = true
	append_event_log({
		"quarter": current_quarter,
		"year": current_year,
		"event_id": "post_victory_continue",
		"title": "Chose to keep building after victory",
	})


func hire_employee(emp: EmployeeData) -> bool:
	if employees.size() >= company.office_capacity():
		return false
	if emp == null:
		return false
	emp.ensure_uid()
	while _has_employee_uid(emp.employee_uid):
		emp.employee_uid = EmployeeData._generate_uid()
	employees.append(emp)
	return true


func fire_employee(emp: EmployeeData) -> void:
	if emp:
		interviewer_busy_quarters.erase(emp.employee_uid)
	employees.erase(emp)


func lock_interviewer(employee_uid: String, quarters: int = 1) -> void:
	var uid := employee_uid.strip_edges()
	if uid.is_empty():
		return
	var q := clampi(quarters, 1, 4)
	interviewer_busy_quarters[uid] = maxi(interviewer_busy_for(uid), q)


func interviewer_busy_for(employee_uid: String) -> int:
	var uid := employee_uid.strip_edges()
	if uid.is_empty():
		return 0
	return maxi(0, int(interviewer_busy_quarters.get(uid, 0)))


func is_interviewer_busy(employee_uid: String) -> bool:
	return interviewer_busy_for(employee_uid) > 0


func consume_interviewer_busy_quarter(employee_uid: String) -> void:
	var uid := employee_uid.strip_edges()
	if uid.is_empty():
		return
	var left := interviewer_busy_for(uid)
	if left <= 0:
		return
	left -= 1
	if left <= 0:
		interviewer_busy_quarters.erase(uid)
	else:
		interviewer_busy_quarters[uid] = left


func _has_employee_uid(uid: String) -> bool:
	for emp in employees:
		if emp.employee_uid == uid:
			return true
	return false


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

	var elapsed_q: int = total_quarters_elapsed()
	var arr: float = financials.revenue * 4.0
	if arr >= 100_000_000 and product.users >= 100_000 and not has_achieved_win("ipo"):
		_emit_victory("ipo")
		return
	if company.valuation >= 1_000_000_000 and not has_achieved_win("unicorn"):
		_emit_victory("unicorn")
		return
	if _meets_sustainable_victory(elapsed_q) and not has_achieved_win("sustainable"):
		_emit_victory("sustainable")
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
	elif product.users <= 0 and elapsed_q > 12:
		is_game_active = false
		game_over.emit("dead_product")


static func _sustainable_requirements(company_type: int) -> Dictionary:
	var req := SUSTAINABLE_REQUIREMENTS_BY_TYPE.get(company_type, SUSTAINABLE_DEFAULT_REQUIREMENTS)
	return req if req is Dictionary else SUSTAINABLE_DEFAULT_REQUIREMENTS


func _meets_sustainable_victory(elapsed_q: int) -> bool:
	if elapsed_q < SUSTAINABLE_MIN_QUARTERS:
		return false
	if profit_streak < SUSTAINABLE_PROFIT_STREAK:
		return false
	var req := _sustainable_requirements(company.type)
	var min_users := int(req.get("users", SUSTAINABLE_DEFAULT_REQUIREMENTS["users"]))
	var min_features := int(req.get("features", SUSTAINABLE_DEFAULT_REQUIREMENTS["features"]))
	var min_revenue := float(req.get("revenue_per_q", SUSTAINABLE_DEFAULT_REQUIREMENTS["revenue_per_q"]))
	if product.users < min_users:
		return false
	if product.feature_count() < min_features:
		return false
	if financials.revenue < min_revenue:
		return false
	return true


func _emit_victory(win_type: String) -> void:
	if has_achieved_win(win_type):
		return
	register_achieved_win(win_type)
	is_game_active = false
	game_won.emit(win_type)


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
	if slot_name not in SLOT_NAMES:
		push_error("GameState: invalid slot name: %s" % slot_name)
		return

	# Reliability first: always flush the previous write before starting a new one,
	# so we never drop the latest autosave.
	if _save_thread and _save_thread.is_started():
		_save_thread.wait_to_finish()

	_save_mutex.lock()
	var data := _serialize()
	if data.is_empty():
		_save_mutex.unlock()
		push_warning("GameState: async save skipped — game state not initialized")
		return
	_save_mutex.unlock()

	_save_thread = Thread.new()
	_save_thread.start(_threaded_save.bind(slot_name, data))


func _threaded_save(slot_name: String, data: Dictionary) -> void:
	if slot_name not in SLOT_NAMES:
		push_error("GameState: invalid slot name: %s" % slot_name)
		return
	var ok := _atomic_write(_slot_path(slot_name), data)
	if not ok:
		push_warning("GameState: async save failed for slot %s" % slot_name)


func save_game(slot_name: String) -> bool:
	if slot_name not in SLOT_NAMES:
		push_error("GameState: invalid slot name: %s" % slot_name)
		return false
	var data := _serialize()
	if data.is_empty():
		save_error.emit("Could not save — game state not initialized")
		return false
	var ok := _atomic_write(_slot_path(slot_name), data)
	if not ok:
		save_error.emit("Save failed — please check your device storage")
	return ok


static func _slot_path(slot_name: String) -> String:
	return SAVE_DIR + slot_name + ".json"


static func _backup_path(path: String) -> String:
	return path + SAVE_BACKUP_SUFFIX


static func _tmp_path(path: String) -> String:
	return path + SAVE_TMP_SUFFIX


static func _copy_file(src_path: String, dst_path: String) -> bool:
	if not FileAccess.file_exists(src_path):
		return false
	var src := FileAccess.open(src_path, FileAccess.READ)
	if src == null:
		return false
	var size: int = src.get_length()
	if size <= 0 or size > MAX_SAVE_BYTES:
		src = null
		return false
	var bytes := src.get_buffer(size)
	src = null
	var dst := FileAccess.open(dst_path, FileAccess.WRITE)
	if dst == null:
		return false
	dst.store_buffer(bytes)
	dst = null
	return true


static func _atomic_write(path: String, data: Dictionary) -> bool:
	var payload_text := JSON.stringify(data, "\t")
	var checksum := payload_text.sha256_text()
	var wrapper := {
		"_schema": 1,
		"_saved_at_unix": Time.get_unix_time_from_system(),
		"_checksum": checksum,
		"data": data,
	}
	var json_text := JSON.stringify(wrapper, "\t")
	if json_text.length() > MAX_SAVE_BYTES:
		push_error("GameState: save payload too large (%d bytes)" % json_text.length())
		return false

	var tmp_path := _tmp_path(path)
	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		push_error("GameState: failed to write temp save: %s" % tmp_path)
		return false
	file.store_string(json_text)
	file = null

	# Roll the previous save into a .bak snapshot first (best effort).
	if FileAccess.file_exists(path):
		var bak_path := _backup_path(path)
		var bak_tmp := _tmp_path(bak_path)
		if _copy_file(path, bak_tmp):
			if FileAccess.file_exists(bak_path):
				DirAccess.remove_absolute(bak_path)
			var bak_err := DirAccess.rename_absolute(bak_tmp, bak_path)
			if bak_err != OK:
				DirAccess.remove_absolute(bak_tmp)
				push_warning("GameState: could not refresh backup (%d)" % bak_err)
		else:
			push_warning("GameState: could not snapshot previous save to backup")

	# Move temp file into place.
	var err := DirAccess.rename_absolute(tmp_path, path)
	if err == ERR_ALREADY_EXISTS:
		DirAccess.remove_absolute(path)
		err = DirAccess.rename_absolute(tmp_path, path)
	if err != OK:
		push_error("GameState: rename failed (%d) %s -> %s" % [err, tmp_path, path])
		DirAccess.remove_absolute(tmp_path)
		return false
	return true


## Reads and validates a save payload from disk.
## Returns {} for any invalid/corrupt/tampered payload.
static func _read_save_data(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("GameState: failed to open save file: %s" % path)
		return {}
	var byte_len: int = file.get_length()
	if byte_len <= 0 or byte_len > MAX_SAVE_BYTES:
		file = null
		push_warning("GameState: save file rejected by size policy (%d bytes)" % byte_len)
		return {}
	var text := file.get_as_text()
	file = null
	var json := JSON.new()
	if json.parse(text) != OK:
		push_warning("GameState: failed to parse save file: %s" % path)
		return {}
	var raw := _safe_dict(json.data)
	if raw.is_empty() and not (json.data is Dictionary):
		push_warning("GameState: save root is not a dictionary: %s" % path)
		return {}

	if raw.has("_checksum") and raw.has("data"):
		var payload := _safe_dict(raw.get("data", {}))
		if payload.is_empty() and not (raw.get("data") is Dictionary):
			push_warning("GameState: save payload is not a dictionary: %s" % path)
			return {}
		var stored_checksum: String = str(raw.get("_checksum", ""))
		var expected := JSON.stringify(payload, "\t").sha256_text()
		if stored_checksum != expected:
			push_warning("GameState: checksum mismatch: %s" % path)
			return {}
		return payload
	return raw


func load_game(slot_name: String) -> bool:
	if slot_name not in SLOT_NAMES:
		push_error("GameState: invalid slot name: %s" % slot_name)
		return false

	var path := _slot_path(slot_name)
	# Prefer primary save; fall back to backup if needed.
	var game_data := _read_save_data(path)
	var used_backup := false
	if game_data.is_empty():
		var bak_path := _backup_path(path)
		game_data = _read_save_data(bak_path)
		used_backup = not game_data.is_empty()

	if game_data.is_empty():
		save_error.emit("Load failed — save is missing or corrupted")
		push_error("GameState: no valid save data found for slot: %s" % slot_name)
		return false

	if not _deserialize(game_data):
		if not used_backup:
			var fallback := _read_save_data(_backup_path(path))
			if not fallback.is_empty() and _deserialize(fallback):
				push_warning("GameState: recovered slot %s via backup after deserialize failure" % slot_name)
				_atomic_write(path, fallback)
				return true
		save_error.emit("Load failed — save format is invalid")
		return false

	if used_backup:
		push_warning("GameState: recovered slot %s from backup file" % slot_name)
		_atomic_write(path, game_data)
	return true


func has_save(slot_name: String) -> bool:
	if slot_name not in SLOT_NAMES:
		return false
	var path := _slot_path(slot_name)
	return FileAccess.file_exists(path) or FileAccess.file_exists(_backup_path(path))


func _serialize() -> Dictionary:
	if company == null or product == null or financials == null or market == null:
		push_error("GameState: cannot serialize — game state not initialized")
		return {}

	var emp_list: Array[Dictionary] = []
	for emp in employees:
		emp.ensure_uid()
		emp_list.append({
			"name": emp.employee_name,
			"uid": emp.employee_uid,
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
			"founder_stats": company.founder_stats.duplicate(true),
		},
		"product": {
			"features": product.features.duplicate(),
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
			"costs": financials.costs_breakdown.duplicate(true),
			"funding_rounds": financials.funding_rounds.duplicate(true),
			"investors": financials.investors.duplicate(true),
		},
		"market": {
			"competitors": market.competitors.duplicate(true),
			"trend": market.market_trend,
			"economy": market.economy_state,
		},
		"employees": emp_list,
		"quarter": current_quarter,
		"year": current_year,
		"difficulty": difficulty,
		"scenario": starting_scenario,
		"history": history.duplicate(true),
		"event_log": event_log.duplicate(true),
		"fired_events": fired_one_time_events.duplicate(),
		"milestones_hit": _milestones_hit.duplicate(),
		"achieved_wins": _achieved_wins.duplicate(),
		"interviewer_busy_quarters": interviewer_busy_quarters.duplicate(true),
		"angel_bailout_used": angel_bailout_used,
		"profit_streak": profit_streak,
		"founder_energy": founder_energy,
		"board_patience": board_patience,
	}


func _deserialize(data: Dictionary) -> bool:
	var version := int(data.get("version", 0))
	if version != 1:
		push_error("GameState: unsupported save version")
		return false

	company = CompanyData.new()
	var cd: Dictionary = _safe_dict(data.get("company", {}))
	company.company_name = cd.get("name", "")
	company.type = cd.get("type", 0)
	company.cash = cd.get("cash", 0.0)
	company.valuation = cd.get("valuation", 0.0)
	company.equity_owned = cd.get("equity", 100.0)
	company.office_level = cd.get("office_level", 0)
	company.reputation = cd.get("reputation", 50)
	company.founder_background = cd.get("founder_background", 0) as CompanyData.FounderBackground
	company.founder_stats = _safe_dict(cd.get("founder_stats", {"technical": 5, "finance": 5, "people": 5, "business": 5}))
	if company.founder_stats.is_empty():
		company.founder_stats = {"technical": 5, "finance": 5, "people": 5, "business": 5}

	product = ProductData.new()
	var pd: Dictionary = _safe_dict(data.get("product", {}))
	product.features.assign(_safe_array(pd.get("features", [])))
	product.tech_debt = pd.get("tech_debt", 0)
	product.bugs = pd.get("bugs", 0)
	product.stability = pd.get("stability", 80)
	product.ux_score = pd.get("ux_score", 50)
	product.users = pd.get("users", 0)
	product.dau = pd.get("dau", 0)
	product.churn_rate = pd.get("churn_rate", 0.05)
	product.feature_progress = float(pd.get("feature_progress", 0.0))
	product.target_feature_id = pd.get("target_feature_id", "")
	product.revenue_mult = pd.get("revenue_mult", 1.0)
	product.user_growth_flat_bonus = pd.get("user_growth_flat_bonus", 0)
	product.dau_bonus = pd.get("dau_bonus", 0.0)

	financials = FinancialsData.new()
	var fd: Dictionary = _safe_dict(data.get("financials", {}))
	financials.revenue = fd.get("revenue", 0.0)
	financials.burn_rate = fd.get("burn_rate", 0.0)
	financials.costs_breakdown = _safe_dict(fd.get("costs", {}))
	financials.funding_rounds.assign(_safe_array(fd.get("funding_rounds", [])))
	financials.investors.assign(_safe_array(fd.get("investors", [])))

	market = MarketData.new()
	var md: Dictionary = _safe_dict(data.get("market", {}))
	market.competitors.assign(_safe_array(md.get("competitors", [])))
	market.market_trend = md.get("trend", 0)
	market.economy_state = md.get("economy", 0)

	employees.clear()
	for raw_emp in _safe_array(data.get("employees", [])):
		var ed: Dictionary = _safe_dict(raw_emp)
		if ed.is_empty():
			continue
		var emp := EmployeeData.new()
		emp.employee_name = ed.get("name", "")
		emp.employee_uid = str(ed.get("uid", ""))
		emp.ensure_uid()
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
	history.assign(_dict_array(data.get("history", [])))
	event_log.assign(_dict_array(data.get("event_log", [])))
	fired_one_time_events.assign(_string_array(data.get("fired_events", [])))
	_milestones_hit.assign(_string_array(data.get("milestones_hit", [])))
	_achieved_wins.assign(_string_array(data.get("achieved_wins", [])))
	interviewer_busy_quarters = _safe_dict(data.get("interviewer_busy_quarters", {}))
	angel_bailout_used = data.get("angel_bailout_used", false)
	profit_streak = data.get("profit_streak", 0)
	founder_energy = data.get("founder_energy", 100)
	board_patience = data.get("board_patience", 4)

	_clamp_deserialized_values()
	is_game_active = true
	return true


func _clamp_deserialized_values() -> void:
	company.company_name = str(company.company_name).strip_edges()
	if company.company_name.is_empty():
		company.company_name = "My Startup"
	elif company.company_name.length() > 64:
		company.company_name = company.company_name.substr(0, 64)

	company.type = clampi(company.type, 0, 3)
	company.founder_background = clampi(company.founder_background, 0, 3) as CompanyData.FounderBackground
	company.cash = clampf(company.cash, -1_000_000.0, 1e12)
	company.valuation = clampf(company.valuation, 0.0, 1e13)
	company.equity_owned = clampf(company.equity_owned, 0.0, 100.0)
	company.reputation = clampi(company.reputation, 0, 100)
	company.office_level = clampi(company.office_level, 0, 10)
	for stat_key in ["technical", "finance", "people", "business"]:
		company.founder_stats[stat_key] = clampi(int(company.founder_stats.get(stat_key, 5)), 1, 10)

	product.tech_debt = clampi(product.tech_debt, 0, 100)
	product.bugs = maxi(0, product.bugs)
	product.stability = clampi(product.stability, 0, 100)
	product.ux_score = clampi(product.ux_score, 0, 100)
	product.users = clampi(product.users, 0, 1_000_000_000)
	product.dau = clampi(product.dau, 0, product.users)
	product.churn_rate = clampf(product.churn_rate, 0.0, 1.0)
	product.feature_progress = clampf(product.feature_progress, 0.0, 1e9)
	product.revenue_mult = clampf(product.revenue_mult, 0.01, 100.0)
	product.dau_bonus = clampf(product.dau_bonus, 0.0, 1.0)

	financials.revenue = maxf(0.0, financials.revenue)
	financials.burn_rate = maxf(0.0, financials.burn_rate)

	current_quarter = clampi(current_quarter, 1, 4)
	current_year = maxi(1, current_year)
	if not DIFFICULTY_MULTS.has(difficulty):
		difficulty = "normal"

	founder_energy = clampi(founder_energy, 0, 200)
	board_patience = clampi(board_patience, 0, 20)
	profit_streak = maxi(0, profit_streak)

	market.economy_state = clampi(market.economy_state, 0, 2)

	if employees.size() > MAX_EMPLOYEES:
		employees = employees.slice(0, MAX_EMPLOYEES)
	if history.size() > MAX_HISTORY_SIZE:
		history = history.slice(-MAX_HISTORY_SIZE)
	if event_log.size() > MAX_EVENT_LOG_SIZE:
		event_log = event_log.slice(-MAX_EVENT_LOG_SIZE)

	var seen_uids: Dictionary = {}
	for emp in employees:
		emp.employee_name = str(emp.employee_name).strip_edges()
		if emp.employee_name.is_empty():
			emp.employee_name = "Employee"
		elif emp.employee_name.length() > 64:
			emp.employee_name = emp.employee_name.substr(0, 64)
		emp.ensure_uid()
		while seen_uids.has(emp.employee_uid):
			emp.employee_uid = EmployeeData._generate_uid()
		seen_uids[emp.employee_uid] = true
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

	var cleaned_busy: Dictionary = {}
	for uid_raw in interviewer_busy_quarters.keys():
		var uid := str(uid_raw).strip_edges()
		if uid.is_empty() or not seen_uids.has(uid):
			continue
		var q := clampi(int(interviewer_busy_quarters.get(uid_raw, 0)), 0, 4)
		if q > 0:
			cleaned_busy[uid] = q
	interviewer_busy_quarters = cleaned_busy

	var dedup_wins: Dictionary = {}
	var valid_wins := ["ipo", "unicorn", "sustainable", "acquisition"]
	for w in _achieved_wins:
		var key := str(w).strip_edges().to_lower()
		if key in valid_wins:
			dedup_wins[key] = true
	_achieved_wins.assign(_string_array(dedup_wins.keys()))


# --- Slot Management ---

func list_saves() -> Array[Dictionary]:
	var saves: Array[Dictionary] = []
	for slot in SLOT_NAMES:
		var info := peek_save(slot)
		info["slot"] = slot
		saves.append(info)
	return saves


func peek_save(slot_name: String) -> Dictionary:
	if slot_name not in SLOT_NAMES:
		return {"exists": false}

	var path := _slot_path(slot_name)
	var data := _read_save_data(path)
	var from_backup := false
	if data.is_empty():
		data = _read_save_data(_backup_path(path))
		from_backup = not data.is_empty()
	if data.is_empty():
		return {"exists": false}

	var cd: Dictionary = _safe_dict(data.get("company", {}))
	var pd: Dictionary = _safe_dict(data.get("product", {}))
	var fd: Dictionary = _safe_dict(data.get("financials", {}))
	var emp_count := _safe_array(data.get("employees", [])).size()

	return {
		"exists": true,
		"from_backup": from_backup,
		"company_name": cd.get("name", "Unknown"),
		"company_type": cd.get("type", 0),
		"cash": cd.get("cash", 0.0),
		"users": pd.get("users", 0),
		"quarter": data.get("quarter", 1),
		"year": data.get("year", 1),
		"difficulty": data.get("difficulty", "normal"),
		"revenue": fd.get("revenue", 0.0),
		"employees": emp_count,
	}


func delete_save(slot_name: String) -> void:
	if slot_name not in SLOT_NAMES:
		push_error("GameState: invalid slot name for delete: %s" % slot_name)
		return
	var path := _slot_path(slot_name)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	var tmp_path := _tmp_path(path)
	if FileAccess.file_exists(tmp_path):
		DirAccess.remove_absolute(tmp_path)
	var bak_path := _backup_path(path)
	if FileAccess.file_exists(bak_path):
		DirAccess.remove_absolute(bak_path)
	var bak_tmp_path := _tmp_path(bak_path)
	if FileAccess.file_exists(bak_tmp_path):
		DirAccess.remove_absolute(bak_tmp_path)
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
	_achieved_wins.clear()
	interviewer_busy_quarters.clear()
	angel_bailout_used = false
	profit_streak = 0
	founder_energy = 100
	board_patience = 4
	current_quarter = 1
	current_year = 1
	is_game_active = false
