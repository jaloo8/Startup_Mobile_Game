extends Node
## Analytics wrapper — all game code calls this, never the SDK directly.
## Checks consent, formats events, and delegates to GameAnalytics.
## Gracefully no-ops if the native SDK isn't available (dev builds).

const SETTINGS_PATH := "user://settings.json"
const GA_BUILD_VERSION := "0.1.0"

var _ga = null
var _sdk_available := false
var _consent := false
var _is_premium := false
var _settings: Dictionary = {}


func _ready() -> void:
	_load_settings()

	if Engine.has_singleton("GameAnalytics"):
		_ga = Engine.get_singleton("GameAnalytics")
		_sdk_available = true
		_ga.configureBuild(GA_BUILD_VERSION)
		_ga.configureAvailableResourceCurrencies(["cash"])
		_ga.configureAvailableResourceItemTypes(["revenue", "fundraising", "milestone", "salary", "infra", "hiring", "office", "angel"])
		var platform := OS.get_name()
		var game_key: String = _settings.get("ga_game_key", "")
		var secret_key: String = _settings.get("ga_secret_key", "")
		if not game_key.is_empty() and not secret_key.is_empty():
			_ga.init(game_key, secret_key)
		else:
			push_warning("Analytics: GameAnalytics keys not configured — tracking disabled")
			_sdk_available = false
	else:
		push_warning("Analytics: GameAnalytics singleton not found — running without analytics")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and _ga != null:
		_ga.onQuit()


func _load_settings() -> void:
	if FileAccess.file_exists(SETTINGS_PATH):
		var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
		if file:
			var json := JSON.new()
			if json.parse(file.get_as_text()) == OK and json.data is Dictionary:
				_settings = json.data
			file = null

	_is_premium = _settings.get("is_premium", false)

	if not _settings.has("analytics_consent"):
		_consent = not _is_premium
		_settings["analytics_consent"] = _consent
		_settings["first_launch"] = true
		_save_settings()
	else:
		_consent = _settings.get("analytics_consent", false)
		_settings["first_launch"] = false


func _save_settings() -> void:
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(_settings, "\t"))
		file = null


func is_consent_given() -> bool:
	return _consent


func is_first_launch() -> bool:
	return _settings.get("first_launch", false)


func set_consent(enabled: bool) -> void:
	_consent = enabled
	_settings["analytics_consent"] = enabled
	_save_settings()


func set_premium(premium: bool) -> void:
	_is_premium = premium
	_settings["is_premium"] = premium
	_save_settings()


func is_premium() -> bool:
	return _is_premium


# --- Progression Events ---

func track_new_game(company_type: String, difficulty: String, scenario: String) -> void:
	_design("newgame:start", 1.0)
	_design("newgame:type:%s" % company_type)
	_design("newgame:difficulty:%s" % difficulty)
	_design("newgame:scenario:%s" % scenario)
	_progression("Start", "game", "Y1", "Q1")


func track_quarter_advanced(year: int, quarter: int) -> void:
	var q_label := "Q%d" % quarter
	var y_label := "Y%d" % year
	_progression("Complete", "game", y_label, q_label)
	var next_q := quarter + 1
	var next_y := year
	if next_q > 4:
		next_q = 1
		next_y += 1
	_progression("Start", "game", "Y%d" % next_y, "Q%d" % next_q)


func track_game_over(reason: String, year: int, quarter: int) -> void:
	var total_q := (year - 1) * 4 + quarter
	_progression("Fail", "game", "Y%d" % year, "Q%d" % quarter, total_q)
	_design("gameover:reason:%s" % reason)
	_design("gameover:quarter_reached", float(total_q))


# --- Screen Visit Events ---

func track_screen(screen_name: String) -> void:
	_design("screen:%s" % screen_name)


# --- People Events ---

func track_job_posted(cost: float) -> void:
	_design("hiring:job_posted")
	_resource("Sink", "cash", cost, "hiring", "job_posting")


func track_interview() -> void:
	_design("hiring:interview")


func track_hire(role: String, seniority: String) -> void:
	_design("hiring:hire:%s:%s" % [seniority, role])


func track_fire() -> void:
	_design("hiring:let_go")


func track_assignment_change(assignment: String) -> void:
	_design("assignment:%s" % assignment)


# --- Finance Events ---

func track_fundraise_attempt() -> void:
	_design("fundraise:attempt")


func track_fundraise_result(accepted: bool, firm_name: String, amount: float) -> void:
	if accepted:
		_design("fundraise:accepted:%s" % firm_name.to_snake_case(), amount)
		_resource("Source", "cash", amount, "fundraising", firm_name.to_snake_case())
	else:
		_design("fundraise:rejected:%s" % firm_name.to_snake_case())


func track_angel_decision(accepted: bool, angel_name: String, amount: float) -> void:
	if accepted:
		_design("angel:accepted:%s" % angel_name.to_snake_case(), amount)
		_resource("Source", "cash", amount, "angel", angel_name.to_snake_case())
	else:
		_design("angel:declined:%s" % angel_name.to_snake_case())


# --- Event Choice Tracking ---

func track_event_choice(event_id: String, choice_index: int) -> void:
	_design("event_choice:%s:%d" % [event_id, choice_index])


# --- Economy Events ---

func track_revenue(amount: float) -> void:
	if amount > 0:
		_resource("Source", "cash", amount, "revenue", "quarterly")


func track_milestone_bonus(milestone_id: String, amount: float) -> void:
	_design("milestone:%s" % milestone_id)
	_resource("Source", "cash", amount, "milestone", milestone_id)


# --- Error Events ---

func track_error(severity: String, message: String) -> void:
	if not _consent or not _sdk_available:
		return
	_ga.addErrorEvent({"severity": severity, "message": message})


# --- Internal SDK Calls ---

func _design(event_id: String, value: float = NAN) -> void:
	if not _consent or not _sdk_available:
		return
	var params := {"eventId": event_id}
	if not is_nan(value):
		params["value"] = value
	_ga.addDesignEvent(params)


func _progression(status: String, p01: String, p02: String = "", p03: String = "", score: float = NAN) -> void:
	if not _consent or not _sdk_available:
		return
	var params := {"progressionStatus": status, "progression01": p01}
	if not p02.is_empty():
		params["progression02"] = p02
	if not p03.is_empty():
		params["progression03"] = p03
	if not is_nan(score):
		params["score"] = score
	_ga.addProgressionEvent(params)


func _resource(flow_type: String, currency: String, amount: float, item_type: String, item_id: String) -> void:
	if not _consent or not _sdk_available:
		return
	_ga.addResourceEvent({
		"flowType": flow_type,
		"currency": currency,
		"amount": amount,
		"itemType": item_type,
		"itemId": item_id,
	})
