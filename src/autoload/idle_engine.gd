extends Node
## IdleEngine — hybrid idle mechanics for Venture.
##
## The quarterly turn structure stays intact. Between sessions (and between turns)
## a passive income trickle runs at 15% of the player's current quarterly revenue
## rate per real-world hour, capped at 8 hours of accumulation.
##
## When the player returns, a "While You Were Away" summary is shown before they
## advance the next quarter. Accumulated passive income is deposited at that point.
##
## In-session: a live ticker on the dashboard shows passive income accumulating
## in real time (cosmetic — deposited only when player acts or returns).


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

## Fraction of quarterly revenue earned per real-world hour while away.
const OFFLINE_RATE_PER_HOUR  := 0.15
## Maximum hours of offline accumulation (avoids huge windfalls after long absences).
const OFFLINE_CAP_HOURS      := 8.0
## Tick interval for the in-session accumulation display (seconds).
const TICK_INTERVAL_SEC      := 3.0
## Key in the settings JSON for the last-active timestamp.
const SAVE_KEY               := "idle_last_active_ts"
const PENDING_INCOME_KEY     := "idle_pending_income"


# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

## Emitted when the player returns and offline income is ready to show.
## payload: { "seconds": float, "income": float }
signal offline_income_ready(payload: Dictionary)

## Emitted every TICK_INTERVAL_SEC in-session with the accumulated amount so far.
signal passive_tick(amount: float)


# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

## Passive income accumulated this session but not yet deposited.
var pending_income: float = 0.0

## Unix timestamp when the player last paused/quit.
var _last_active_ts: int = 0

## Running accumulator for the in-session ticker display.
var _session_accumulator: float = 0.0
var _tick_timer: float = 0.0

## True once the "while you were away" flow has been triggered this session.
var _offline_processed: bool = false


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	_load_timestamps()
	_process_offline_income()
	# Hook into app focus changes so we stamp correctly on background.
	get_tree().root.focus_entered.connect(_on_focus_entered)
	get_tree().root.focus_exited.connect(_on_focus_exited)


func _process(delta: float) -> void:
	if not GameState.is_game_active:
		return
	if GameState.company == null or GameState.financials == null:
		return

	# Accumulate passive income in real-time for the on-screen ticker.
	var rate_per_sec := _passive_rate_per_sec()
	_session_accumulator += rate_per_sec * delta
	pending_income += rate_per_sec * delta

	_tick_timer += delta
	if _tick_timer >= TICK_INTERVAL_SEC:
		_tick_timer = 0.0
		passive_tick.emit(_session_accumulator)


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Deposits all accumulated passive income into cash and resets accumulators.
## Call this when the player advances a quarter OR dismisses the offline summary.
func deposit_pending_income() -> void:
	if pending_income <= 0.0:
		return
	var amount := snappedf(pending_income, 1.0)
	GameState.company.cash += amount
	GameState.append_event_log({
		"quarter": GameState.current_quarter,
		"year":    GameState.current_year,
		"event_id":"passive_income",
		"title":   "Passive income: +%s" % SceneLoader.format_money(amount),
	})
	pending_income = 0.0
	_session_accumulator = 0.0


## Returns the current in-session passive accumulation (display only).
func session_trickle() -> float:
	return _session_accumulator


## Returns true if there is offline income waiting to be shown to the player.
func has_offline_income() -> bool:
	return not _offline_processed and pending_income > 1.0


## Returns a summary dict for the "While You Were Away" panel.
func offline_summary() -> Dictionary:
	return {
		"seconds":   _offline_elapsed_seconds(),
		"income":    snappedf(pending_income, 1.0),
		"chips":     _offline_chip_bonus(),
	}


## Mark offline flow as complete (call after player dismisses the summary).
func mark_offline_processed() -> void:
	_offline_processed = true


## Stamp the current time (call on scene changes, saves, pauses).
func stamp_active() -> void:
	_last_active_ts = Time.get_unix_time_from_system()
	_save_timestamps()


# ---------------------------------------------------------------------------
# Private — offline calculation
# ---------------------------------------------------------------------------

func _passive_rate_per_sec() -> float:
	if GameState.financials == null:
		return 0.0
	var quarterly_rev := maxf(0.0, GameState.financials.revenue)
	# Quarterly = 3 months ≈ 91.25 days ≈ 7,884,000 seconds
	return (quarterly_rev * OFFLINE_RATE_PER_HOUR) / 3_600.0


func _offline_elapsed_seconds() -> float:
	if _last_active_ts <= 0:
		return 0.0
	var now := Time.get_unix_time_from_system()
	return maxf(0.0, float(now - _last_active_ts))


func _process_offline_income() -> void:
	var elapsed_sec := _offline_elapsed_seconds()
	if elapsed_sec < 60.0:
		# Less than a minute — not worth showing a summary.
		_offline_processed = true
		return

	var elapsed_hours := minf(elapsed_sec / 3_600.0, OFFLINE_CAP_HOURS)
	if GameState.financials == null:
		_offline_processed = true
		return

	var quarterly_rev := maxf(0.0, GameState.financials.revenue)
	var offline_income := quarterly_rev * OFFLINE_RATE_PER_HOUR * elapsed_hours
	offline_income = snappedf(offline_income, 1.0)

	if offline_income > 1.0:
		pending_income += offline_income
		# Signal will be picked up by the dashboard to show the summary panel.
		call_deferred("_emit_offline_ready")


func _emit_offline_ready() -> void:
	offline_income_ready.emit({
		"seconds": _offline_elapsed_seconds(),
		"income":  snappedf(pending_income, 1.0),
		"chips":   _offline_chip_bonus(),
	})


## Small VC Chip bonus for returning (1 chip per 2 hours away, max 4).
func _offline_chip_bonus() -> int:
	var hours := minf(_offline_elapsed_seconds() / 3_600.0, OFFLINE_CAP_HOURS)
	return clampi(int(hours / 2.0), 0, 4)


# ---------------------------------------------------------------------------
# Private — persistence
# ---------------------------------------------------------------------------

func _load_timestamps() -> void:
	var settings := _load_settings_dict()
	_last_active_ts = int(settings.get(SAVE_KEY, 0))
	pending_income  = float(settings.get(PENDING_INCOME_KEY, 0.0))


func _save_timestamps() -> void:
	var settings := _load_settings_dict()
	settings[SAVE_KEY]          = _last_active_ts
	settings[PENDING_INCOME_KEY] = pending_income
	_write_settings_dict(settings)


func _load_settings_dict() -> Dictionary:
	var path := "user://idle_state.json"
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		return parsed
	return {}


func _write_settings_dict(data: Dictionary) -> void:
	var path := "user://idle_state.json"
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(data, "\t"))


# ---------------------------------------------------------------------------
# Focus events — stamp timestamps on backgrounding
# ---------------------------------------------------------------------------

func _on_focus_exited() -> void:
	stamp_active()


func _on_focus_entered() -> void:
	# Re-process offline income if we were backgrounded long enough.
	if not _offline_processed:
		_process_offline_income()
