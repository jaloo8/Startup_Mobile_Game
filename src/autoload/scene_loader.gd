extends Node
## Loads and caches scenes for fast transitions.
## All scene changes go through goto_scene() which plays a short crossfade wipe.

signal scene_changed(scene_path: String)

var _cache: Dictionary = {}  # path -> PackedScene

## Persistent overlay layer for scene transition effects.
## Lives on this autoload so it survives scene swaps.
var _transition_layer: CanvasLayer
var _transition_rect: ColorRect
var _transitioning: bool = false
const WIPE_COLOR := Color(0.02, 0.04, 0.08, 1.0)
const WIPE_FADE_OUT := 0.14  # seconds to fade to black
const WIPE_FADE_IN  := 0.20  # seconds to fade from black

const PRELOAD_SCENES: Array = [
	"res://src/ui/main_menu/main_menu.tscn",
	"res://src/ui/setup/new_game.tscn",
	"res://src/ui/dashboard/quarter_dashboard.tscn",
	"res://src/ui/people/employee_list.tscn",
	"res://src/ui/product/product_overview.tscn",
	"res://src/ui/finance/finance_overview.tscn",
	"res://src/ui/logistics/logistics_overview.tscn",
	"res://src/ui/market/market_leaderboard.tscn",
	"res://src/ui/saves/save_slots.tscn",
	"res://src/ui/game_over/game_over_screen.tscn",
	"res://src/ui/settings/settings_screen.tscn",
	"res://src/ui/victory/victory_screen.tscn",
]


func _ready() -> void:
	_build_transition_overlay()
	_apply_touch_hardening.call_deferred(get_tree().current_scene)
	_preload_all.call_deferred()


func _build_transition_overlay() -> void:
	_transition_layer = CanvasLayer.new()
	_transition_layer.layer = 128  # above everything
	add_child(_transition_layer)

	_transition_rect = ColorRect.new()
	_transition_rect.color = WIPE_COLOR
	_transition_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_transition_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transition_rect.modulate.a = 0.0
	_transition_layer.add_child(_transition_rect)


func _preload_all() -> void:
	for path in PRELOAD_SCENES:
		if not _cache.has(path):
			var scene := ResourceLoader.load(path, "PackedScene") as PackedScene
			if scene:
				_cache[path] = scene
			else:
				push_warning("SceneLoader: could not preload '%s' — check path and dependencies" % path)


func goto_scene(path: String) -> void:
	if _transitioning:
		return  # prevent double-tap scene swaps
	_transitioning = true
	_animate_scene_swap.call_deferred(path)


func _animate_scene_swap(path: String) -> void:
	# Phase 1: fade to black.
	var tw := create_tween()
	tw.tween_property(_transition_rect, "modulate:a", 1.0, WIPE_FADE_OUT) \
		.set_ease(Tween.EASE_OUT)
	await tw.finished

	# Phase 2: swap the scene while the screen is black.
	var swap_ok := _do_scene_swap(path)

	# Phase 3: fade from black (even on failure — don't leave the screen black).
	var tw2 := create_tween()
	tw2.tween_property(_transition_rect, "modulate:a", 0.0, WIPE_FADE_IN) \
		.set_ease(Tween.EASE_IN)
	await tw2.finished
	_transitioning = false


func _do_scene_swap(path: String) -> bool:
	var packed: PackedScene
	if _cache.has(path):
		packed = _cache[path]
	else:
		packed = ResourceLoader.load(path, "PackedScene") as PackedScene
		if packed:
			_cache[path] = packed

	if packed == null:
		push_error("SceneLoader: failed to load '%s' — scene file missing or corrupt" % path)
		return false

	# Instantiate before touching the tree; if this throws, the current scene survives.
	var new_scene := packed.instantiate()
	if new_scene == null:
		push_error("SceneLoader: instantiate() returned null for '%s'" % path)
		return false

	var tree := get_tree()
	if tree.current_scene:
		tree.current_scene.queue_free()

	tree.root.add_child(new_scene)
	tree.current_scene = new_scene
	_apply_touch_hardening.call_deferred(new_scene)
	scene_changed.emit(path)
	return true


func _apply_touch_hardening(root: Node) -> void:
	if root == null or not is_instance_valid(root):
		return
	# Mobile accessibility baseline. This also tags nodes with lightweight
	# visual-polish metadata hooks for future animation passes.
	UITouchHelper.harden_tree(root)


static func free_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()


static func format_money(amount: float) -> String:
	if absf(amount) >= 1_000_000:
		return "%.1fM" % (amount / 1_000_000.0)
	elif absf(amount) >= 1_000:
		return "%.0fK" % (amount / 1_000.0)
	return "%.0f" % amount


static func format_number(n: int) -> String:
	if n >= 1_000_000:
		return "%.1fM" % (n / 1_000_000.0)
	elif n >= 1_000:
		return "%.1fK" % (n / 1_000.0)
	return str(n)
