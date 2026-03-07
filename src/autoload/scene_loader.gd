extends Node
## Autoload singleton for scene management on mobile.
## Preloads core scenes, caches them, and handles transitions
## without blocking the main thread.

signal scene_changed(scene_path: String)

var _cache: Dictionary = {}  # path -> PackedScene
var _loading_path: String = ""
var _current_scene: Node = null

const PRELOAD_SCENES := [
	"res://src/ui/main_menu/main_menu.tscn",
	"res://src/ui/setup/new_game.tscn",
	"res://src/ui/dashboard/quarter_dashboard.tscn",
	"res://src/ui/people/employee_list.tscn",
	"res://src/ui/product/product_overview.tscn",
]


func _ready() -> void:
	_preload_all.call_deferred()


func _preload_all() -> void:
	for path in PRELOAD_SCENES:
		if not _cache.has(path):
			var scene := ResourceLoader.load(path, "PackedScene") as PackedScene
			if scene:
				_cache[path] = scene


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
		push_error("SceneLoader: failed to load %s" % path)
		return

	var tree := get_tree()
	if tree.current_scene:
		tree.current_scene.queue_free()

	var new_scene := packed.instantiate()
	tree.root.add_child(new_scene)
	tree.current_scene = new_scene
	scene_changed.emit(path)
