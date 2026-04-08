extends Node
## Global lightweight SFX player using AudioStreamGenerator synthesis.
## No audio files required — falls back to generated tones when assets are missing.
## Add asset paths to each SFX dict to override with real sounds when available.

const SFX_DEFS: Dictionary = {
	# --- Core actions ---
	"hire":           {"freq": 660.0,  "freq2": 880.0,  "dur": 0.10, "amp": 0.10, "decay": 14.0},
	"fire":           {"freq": 200.0,  "freq2": 0.0,    "dur": 0.12, "amp": 0.09, "decay": 10.0},
	"retire":         {"freq": 320.0,  "freq2": 440.0,  "dur": 0.15, "amp": 0.08, "decay": 9.0 },
	"feature_ship":   {"freq": 520.0,  "freq2": 780.0,  "dur": 0.18, "amp": 0.12, "decay": 8.0 },
	"quarter_done":   {"freq": 690.0,  "freq2": 0.0,    "dur": 0.12, "amp": 0.10, "decay": 12.0},
	"event_popup":    {"freq": 380.0,  "freq2": 520.0,  "dur": 0.10, "amp": 0.08, "decay": 18.0},

	# --- UI feedback ---
	"button_tap":     {"freq": 480.0,  "freq2": 0.0,    "dur": 0.06, "amp": 0.07, "decay": 22.0},
	"click":          {"freq": 450.0,  "freq2": 0.0,    "dur": 0.05, "amp": 0.06, "decay": 22.0},
	"button_back":    {"freq": 360.0,  "freq2": 0.0,    "dur": 0.05, "amp": 0.05, "decay": 25.0},
	"toast":          {"freq": 720.0,  "freq2": 960.0,  "dur": 0.08, "amp": 0.06, "decay": 20.0},
	"tab_switch":     {"freq": 540.0,  "freq2": 0.0,    "dur": 0.05, "amp": 0.05, "decay": 24.0},
	"toggle":         {"freq": 600.0,  "freq2": 800.0,  "dur": 0.06, "amp": 0.06, "decay": 20.0},

	# --- Money & economy ---
	"cash_gain":      {"freq": 880.0,  "freq2": 1100.0, "dur": 0.12, "amp": 0.09, "decay": 12.0},
	"cash_loss":      {"freq": 260.0,  "freq2": 180.0,  "dur": 0.14, "amp": 0.08, "decay": 10.0},
	"fundraise":      {"freq": 440.0,  "freq2": 660.0,  "dur": 0.22, "amp": 0.11, "decay": 6.0 },
	"milestone":      {"freq": 587.0,  "freq2": 880.0,  "dur": 0.20, "amp": 0.10, "decay": 7.0 },

	# --- Achievements & rewards ---
	"achievement":    {"freq": 784.0,  "freq2": 1047.0, "dur": 0.25, "amp": 0.12, "decay": 5.5 },
	"level_up":       {"freq": 523.0,  "freq2": 784.0,  "dur": 0.18, "amp": 0.10, "decay": 7.0 },
	"chip_spend":     {"freq": 640.0,  "freq2": 480.0,  "dur": 0.10, "amp": 0.08, "decay": 16.0},

	# --- Negative events ---
	"warning":        {"freq": 280.0,  "freq2": 350.0,  "dur": 0.15, "amp": 0.10, "decay": 9.0 },
	"error":          {"freq": 180.0,  "freq2": 0.0,    "dur": 0.18, "amp": 0.11, "decay": 8.0 },
	"crash":          {"freq": 150.0,  "freq2": 220.0,  "dur": 0.25, "amp": 0.12, "decay": 6.0 },

	# --- Game flow ---
	"game_over":      {"freq": 220.0,  "freq2": 165.0,  "dur": 0.30, "amp": 0.12, "decay": 5.0 },
	"victory":        {"freq": 659.0,  "freq2": 988.0,  "dur": 0.30, "amp": 0.13, "decay": 4.5 },
	"save":           {"freq": 550.0,  "freq2": 0.0,    "dur": 0.08, "amp": 0.06, "decay": 18.0},
}

const PREFS_PATH := "user://audio_prefs.dat"

var _player: AudioStreamPlayer
var sfx_enabled: bool = true
var haptic_enabled: bool = true


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.bus = "Master"
	add_child(_player)
	_load_prefs()


## Play a named SFX. Silently no-ops if the key is unknown or SFX is muted.
func play(sfx_key: String) -> void:
	if not sfx_enabled:
		return
	if not SFX_DEFS.has(sfx_key):
		return
	var def: Dictionary = SFX_DEFS[sfx_key]
	_synth(
		float(def.get("freq", 440.0)),
		float(def.get("freq2", 0.0)),
		float(def.get("dur", 0.10)),
		float(def.get("amp", 0.08)),
		float(def.get("decay", 12.0))
	)


func _synth(freq: float, freq2: float, duration: float, amp: float, decay: float) -> void:
	if _player == null:
		return
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = 44_100.0
	generator.buffer_length = maxf(0.30, duration + 0.05)
	_player.stream = generator
	_player.volume_db = -6.0
	_player.play()

	var playback := _player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return

	var rate := generator.mix_rate
	var samples := int(rate * duration)
	var safe_dur := maxf(0.001, duration)

	for i in samples:
		var t := float(i) / rate
		var env := amp * exp(-decay * t / safe_dur)
		var tone := sin(TAU * freq * t)
		if freq2 > 0.0:
			# Blend second harmonic for a richer chime.
			tone = lerp(tone, sin(TAU * freq2 * t), 0.35)
		playback.push_frame(Vector2(tone * env, tone * env))


# ---------------------------------------------------------------------------
# Preferences persistence
# ---------------------------------------------------------------------------

func set_sfx_enabled(enabled: bool) -> void:
	sfx_enabled = enabled
	_save_prefs()


func set_haptic_enabled(enabled: bool) -> void:
	haptic_enabled = enabled
	_save_prefs()


func _load_prefs() -> void:
	var file := FileAccess.open(PREFS_PATH, FileAccess.READ)
	if file == null:
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return
	file.close()
	var data: Variant = json.data
	if data is Dictionary:
		sfx_enabled = bool(data.get("sfx_enabled", true))
		haptic_enabled = bool(data.get("haptic_enabled", true))


func _save_prefs() -> void:
	var data: Dictionary = {
		"sfx_enabled": sfx_enabled,
		"haptic_enabled": haptic_enabled,
	}
	var file := FileAccess.open(PREFS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()
