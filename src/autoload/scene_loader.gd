extends Node
## Loads and caches scenes for fast transitions.

signal scene_changed(scene_path: String)

var _cache: Dictionary = {}  # path -> PackedScene

const PRELOAD_SCENES := [
	"res://src/ui/main_menu/main_menu.tscn",
	"res://src/ui/setup/new_game.tscn",
	"res://src/ui/dashboard/quarter_dashboard.tscn",
	"res://src/ui/people/employee_list.tscn",
	"res://src/ui/product/product_overview.tscn",
	"res://src/ui/finance/finance_overview.tscn",
	"res://src/ui/market/market_leaderboard.tscn",
	"res://src/ui/saves/save_slots.tscn",
	"res://src/ui/game_over/game_over_screen.tscn",
	"res://src/ui/settings/settings_screen.tscn",
	"res://src/ui/victory/victory_screen.tscn",
]


func _ready() -> void:
	_preload_all.call_deferred()


func _preload_all() -> void:
	for path in PRELOAD_SCENES:
		if not _cache.has(path):
			var scene := ResourceLoader.load(path, "PackedScene") as PackedScene
			if scene:
				_cache[path] = scene
			else:
				push_warning("SceneLoader: could not preload '%s' — check path and dependencies" % path)


func goto_scene(path: String) -> void:
	_switch_scene.call_deferred(path)


func _switch_scene(path: String) -> void:
	var packed: PackedScene
	if _cache.has(path):
		packed = _cache[path]
	else:
		packed = ResourceLoader.load(path, "PackedScene") as PackedScene
		if packed:
			_cache[path] = packed

	if packed == null:
		push_error("SceneLoader: failed to load '%s' — scene file missing or corrupt" % path)
		return

	# Instantiate before touching the tree; if this throws, the current scene survives.
	var new_scene := packed.instantiate()
	if new_scene == null:
		push_error("SceneLoader: instantiate() returned null for '%s'" % path)
		return

	var tree := get_tree()
	if tree.current_scene:
		tree.current_scene.queue_free()

	tree.root.add_child(new_scene)
	tree.current_scene = new_scene
	scene_changed.emit(path)


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
