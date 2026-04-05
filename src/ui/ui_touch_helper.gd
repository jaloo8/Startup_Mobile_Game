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
	elif node is ScrollContainer:
		_harden_scroll(node as ScrollContainer)
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


static func _harden_scroll(scroll: ScrollContainer) -> void:
	if scroll == null:
		return
	# Keep keyboard/focus navigation usable on smaller screens.
	scroll.follow_focus = true
	# Small deadzone reduces "tap swallowed as click" when the intent is to drag.
	if scroll.scroll_deadzone > 8 or scroll.scroll_deadzone <= 0:
		scroll.scroll_deadzone = 8
	_ensure_scroll_content_width(scroll)
	if not scroll.has_meta("_touch_scroll_resize_hooked"):
		scroll.set_meta("_touch_scroll_resize_hooked", true)
		scroll.resized.connect(func() -> void:
			if is_instance_valid(scroll):
				_ensure_scroll_content_width(scroll)
		)


static func _ensure_scroll_content_width(scroll: ScrollContainer) -> void:
	var content := _primary_scroll_content(scroll)
	if content == null:
		return
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var min_size := content.custom_minimum_size
	if scroll.size.x > 0.0 and min_size.x < scroll.size.x:
		min_size.x = scroll.size.x
		content.custom_minimum_size = min_size


static func _primary_scroll_content(scroll: ScrollContainer) -> Control:
	for child in scroll.get_children():
		if child is Control:
			return child as Control
	return null


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
