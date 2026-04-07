extends Node
## Global lightweight SFX player using AudioStreamGenerator synthesis.
## No audio files required — falls back to generated tones when assets are missing.
## Add asset paths to each SFX dict to override with real sounds when available.

const SFX_DEFS := {
	"hire":         {"freq": 660.0,  "freq2": 880.0,  "dur": 0.10, "amp": 0.10, "decay": 14.0},
	"feature_ship": {"freq": 520.0,  "freq2": 780.0,  "dur": 0.18, "amp": 0.12, "decay": 8.0 },
	"button_tap":   {"freq": 480.0,  "freq2": 0.0,    "dur": 0.06, "amp": 0.07, "decay": 22.0},
	"quarter_done": {"freq": 690.0,  "freq2": 0.0,    "dur": 0.12, "amp": 0.10, "decay": 12.0},
	"event_popup":  {"freq": 380.0,  "freq2": 520.0,  "dur": 0.10, "amp": 0.08, "decay": 18.0},
	"fire":         {"freq": 200.0,  "freq2": 0.0,    "dur": 0.12, "amp": 0.09, "decay": 10.0},
	"retire":       {"freq": 320.0,  "freq2": 440.0,  "dur": 0.15, "amp": 0.08, "decay": 9.0 },
}

var _player: AudioStreamPlayer


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.bus = "Master"
	add_child(_player)


## Play a named SFX. Silently no-ops if the key is unknown.
func play(sfx_key: String) -> void:
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
