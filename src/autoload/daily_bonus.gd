extends Node
## DailyBonus — login streak tracker and daily reward system.
##
## Awards escalating VC Chip bonuses for consecutive daily logins.
## 7-day cycle repeats with a small bonus multiplier each full cycle.
##
## Day 1: 1 chip, Day 2: 1, Day 3: 2, Day 4: 2, Day 5: 3, Day 6: 3, Day 7: 5
## Each completed 7-day cycle adds +1 to every reward in the next cycle (capped).
##
## Usage:
##   DailyBonus.check_daily()            # call on app launch / return from background
##   DailyBonus.get_streak() -> int      # current consecutive days
##   DailyBonus.get_today_reward() -> int
##   DailyBonus.has_claimed_today() -> bool

signal daily_reward_available(day: int, reward: int, streak: int)
signal daily_reward_claimed(day: int, reward: int, streak: int)

const SAVE_PATH := "user://daily_bonus.dat"

## Base chip rewards for each day of the 7-day cycle (1-indexed).
const CYCLE_REWARDS: Array = [0, 1, 1, 2, 2, 3, 3, 5]

## Maximum bonus from completed cycles to prevent inflation.
const MAX_CYCLE_BONUS := 3

## How many hours count as "same day" grace period (e.g. playing at 11 PM then 1 AM).
const STREAK_GRACE_HOURS := 36

var _streak: int = 0
var _completed_cycles: int = 0
var _last_claim_date: String = ""  # ISO date "2026-04-07"
var _last_claim_ts: int = 0  # Unix timestamp of last claim
var _claimed_today: bool = false


func _ready() -> void:
	_load()


## Check if a daily reward is available. Call this on app launch.
func check_daily() -> void:
	var today := _today_str()
	if _last_claim_date == today:
		_claimed_today = true
		return

	_claimed_today = false

	# Determine if streak continues or resets.
	if _last_claim_ts > 0:
		var elapsed_hours := (Time.get_unix_time_from_system() - _last_claim_ts) / 3600.0
		if elapsed_hours > STREAK_GRACE_HOURS:
			# Streak broken — too many hours since last claim.
			_streak = 0
			_completed_cycles = 0

	daily_reward_available.emit(_cycle_day(), get_today_reward(), _streak)


## Claim today's reward. Returns the chip amount awarded, or 0 if already claimed.
func claim() -> int:
	if _claimed_today:
		return 0

	_streak += 1
	_claimed_today = true
	_last_claim_date = _today_str()
	_last_claim_ts = int(Time.get_unix_time_from_system())

	var day := _cycle_day()
	var reward := _reward_for_day(day)

	# Check for cycle completion.
	if day == 7:
		_completed_cycles = mini(_completed_cycles + 1, MAX_CYCLE_BONUS)

	# Award chips.
	if CurrencyManager.has_method("earn"):
		CurrencyManager.earn(reward, "daily_bonus_day_%d" % day)

	# Celebration.
	SfxPlayer.play("milestone")
	AnimHelper.haptic(&"medium")
	ToastManager.show("Day %d Bonus: +%d VC Chips" % [day, reward], "📅", ThemeManager.C_GOLD)

	daily_reward_claimed.emit(day, reward, _streak)
	_save()
	return reward


# ---------------------------------------------------------------------------
# Public getters
# ---------------------------------------------------------------------------

func get_streak() -> int:
	return _streak


func get_today_reward() -> int:
	return _reward_for_day(_cycle_day())


func has_claimed_today() -> bool:
	return _claimed_today


func get_cycle_day() -> int:
	return _cycle_day()


func get_next_cycle_rewards() -> Array[int]:
	var rewards: Array[int] = []
	for i in range(1, 8):
		rewards.append(_reward_for_day(i))
	return rewards


# ---------------------------------------------------------------------------
# Internal
# ---------------------------------------------------------------------------

func _cycle_day() -> int:
	# Which day of the 7-day cycle are we on? 1-7.
	if _claimed_today:
		return ((_streak - 1) % 7) + 1
	return (_streak % 7) + 1


func _reward_for_day(day: int) -> int:
	var base: int = CYCLE_REWARDS[clampi(day, 1, 7)]
	return base + mini(_completed_cycles, MAX_CYCLE_BONUS)


func _today_str() -> String:
	var d: Dictionary = Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [d.get("year", 2026), d.get("month", 1), d.get("day", 1)]


# ---------------------------------------------------------------------------
# Persistence
# ---------------------------------------------------------------------------

func _save() -> void:
	var data: Dictionary = {
		"streak": _streak,
		"completed_cycles": _completed_cycles,
		"last_claim_date": _last_claim_date,
		"last_claim_ts": _last_claim_ts,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()


func _load() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		file.close()
		return
	file.close()
	var data: Variant = json.data
	if not data is Dictionary:
		return
	_streak = int(data.get("streak", 0))
	_completed_cycles = int(data.get("completed_cycles", 0))
	_last_claim_date = str(data.get("last_claim_date", ""))
	_last_claim_ts = int(data.get("last_claim_ts", 0))
	_claimed_today = _last_claim_date == _today_str()
