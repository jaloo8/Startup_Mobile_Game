extends Node
## Runtime bridge so UITouchHelper APIs remain globally available even when
## class-name cache metadata is stale on a given machine/editor build.

const TouchHelperScript = preload("res://src/ui/ui_touch_helper.gd")


func harden_tree(
	root: Node,
	min_touch_size: float = TouchHelperScript.DEFAULT_MIN_TOUCH_SIZE,
	min_button_gap: int = TouchHelperScript.DEFAULT_MIN_BUTTON_GAP
) -> void:
	TouchHelperScript.harden_tree(root, min_touch_size, min_button_gap)
