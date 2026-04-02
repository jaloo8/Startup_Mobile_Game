class_name UITouchHelper
extends RefCounted
## Centralized touch-target/accessibility hardening for mobile-first UI.
##
## This is intentionally data-driven and lightweight so future polish passes can
## swap in richer authored interactions without touching every screen script.

const DEFAULT_MIN_TOUCH_SIZE := 46.0
const DEFAULT_MIN_BUTTON_GAP := 8
const VISUAL_HOOK_META_KEY := "ui_visual_hook"


static func harden_tree(root: Node, min_touch_size: float = DEFAULT_MIN_TOUCH_SIZE, min_button_gap: int = DEFAULT_MIN_BUTTON_GAP) -> void:
	if root == null:
		return
	_harden_recursive(root, maxf(40.0, min_touch_size), maxi(4, min_button_gap))


static func _harden_recursive(node: Node, min_touch_size: float, min_button_gap: int) -> void:
	if node is BaseButton:
		_harden_button(node as BaseButton, min_touch_size)
	elif node is BoxContainer:
		_harden_box_spacing(node as BoxContainer, min_button_gap)
	elif node is GridContainer:
		_harden_grid_spacing(node as GridContainer, min_button_gap)

	for child in node.get_children():
		_harden_recursive(child, min_touch_size, min_button_gap)


static func _harden_button(btn: BaseButton, min_touch_size: float) -> void:
	if btn == null:
		return
	if btn.has_meta("touch_target_skip") and bool(btn.get_meta("touch_target_skip")):
		return

	var min_size := btn.custom_minimum_size
	if min_size.y < min_touch_size:
		min_size.y = min_touch_size

	# Keep icon-only and short-label buttons thumb-friendly in both axes.
	var button_text := str(btn.get("text"))
	if button_text.strip_edges().length() <= 2 and min_size.x < min_touch_size:
		min_size.x = min_touch_size
	btn.custom_minimum_size = min_size
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	# Placeholder hook for a future visual polish pass (press scale/ripple/haptics).
	# Sonnet/Opus can key off this metadata and implement richer per-screen effects.
	if not btn.has_meta(VISUAL_HOOK_META_KEY):
		btn.set_meta(VISUAL_HOOK_META_KEY, "press_feedback_v1")


static func _harden_box_spacing(box: BoxContainer, min_button_gap: int) -> void:
	var button_children := 0
	for child in box.get_children():
		if child is BaseButton and child.visible:
			button_children += 1
	if button_children < 2:
		return
	var current_sep := box.get_theme_constant("separation")
	if current_sep < min_button_gap:
		box.add_theme_constant_override("separation", min_button_gap)


static func _harden_grid_spacing(grid: GridContainer, min_button_gap: int) -> void:
	var has_buttons := false
	for child in grid.get_children():
		if child is BaseButton and child.visible:
			has_buttons = true
			break
	if not has_buttons:
		return
	if grid.get_theme_constant("h_separation") < min_button_gap:
		grid.add_theme_constant_override("h_separation", min_button_gap)
	if grid.get_theme_constant("v_separation") < min_button_gap:
		grid.add_theme_constant_override("v_separation", min_button_gap)
