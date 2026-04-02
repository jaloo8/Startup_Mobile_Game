extends Node
## Runtime bridge so WorldEventEngine APIs remain globally available even when
## class-name cache metadata is stale on a given machine/editor build.

const WorldEventScript = preload("res://src/engine/world_event_engine.gd")


func load_events(path: String = WorldEventScript.WORLD_EVENTS_PATH) -> void:
	WorldEventScript.load_events(path)


func resolve_quarter(state: Node) -> void:
	WorldEventScript.resolve_quarter(state)
