class_name AnimHelper
## Reusable animation utilities for consistent, Disney-quality UI motion.
##
## Design principles (Disney 12 Principles applied to UI):
##   • Squash & stretch — scale pulses give life to number changes
##   • Anticipation    — brief scale-down before a pop-out
##   • Follow-through  — overshoot + settle on spring animations (TRANS_BACK)
##   • Ease in & out   — no linear motion; everything has personality
##   • Staging         — stagger list items so the eye follows naturally
##
## All durations tuned for 60fps on iPhone SE. Under 300 ms feels instant;
## over 600 ms feels sluggish. Sweet spot: 180–260 ms with spring easing.
##
## Usage:
##   AnimHelper.pop_in(node)
##   AnimHelper.slide_in(node, Vector2(0, 40))
##   AnimHelper.roll_number(label, from_val, to_val, prefix, suffix)


# ---------------------------------------------------------------------------
# Entrance animations
# ---------------------------------------------------------------------------

## Spring pop-in from scale 0 — cards, badges, modals.
static func pop_in(node: Control, delay: float = 0.0, duration: float = 0.26) -> Tween:
	node.scale = Vector2(0.0, 0.0)
	node.pivot_offset = node.size * 0.5
	node.modulate.a = 0.0
	var tw := node.create_tween().set_parallel(true)
	tw.tween_property(node, "scale", Vector2.ONE, duration) \
		.set_delay(delay) \
		.set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_BACK)
	tw.tween_property(node, "modulate:a", 1.0, duration * 0.6) \
		.set_delay(delay) \
		.set_ease(Tween.EASE_OUT)
	return tw


## Slide-in from an offset — list rows, panels sliding up from bottom.
static func slide_in(node: Control, offset: Vector2,
		delay: float = 0.0, duration: float = 0.22) -> Tween:
	var original_pos := node.position
	node.position = original_pos + offset
	node.modulate.a = 0.0
	var tw := node.create_tween().set_parallel(true)
	tw.tween_property(node, "position", original_pos, duration) \
		.set_delay(delay) \
		.set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_QUINT)
	tw.tween_property(node, "modulate:a", 1.0, duration * 0.7) \
		.set_delay(delay) \
		.set_ease(Tween.EASE_OUT)
	return tw


## Fade in only — subtle, used for secondary content appearing.
static func fade_in(node: CanvasItem, delay: float = 0.0,
		duration: float = 0.18) -> Tween:
	node.modulate.a = 0.0
	var tw := node.create_tween()
	tw.tween_property(node, "modulate:a", 1.0, duration) \
		.set_delay(delay) \
		.set_ease(Tween.EASE_OUT)
	return tw


## Staggered list entrance — call once, animates all children with offset delay.
static func stagger_list(container: Control, item_delay: float = 0.055,
		start_delay: float = 0.0, slide_y: float = 28.0) -> void:
	var children := container.get_children()
	for i in children.size():
		var child := children[i]
		if child is Control:
			slide_in(child, Vector2(0, slide_y), start_delay + i * item_delay)


# ---------------------------------------------------------------------------
# Exit animations
# ---------------------------------------------------------------------------

## Shrink and fade out — opposite of pop_in.
static func pop_out(node: Control, duration: float = 0.18,
		then: Callable = Callable()) -> Tween:
	node.pivot_offset = node.size * 0.5
	var tw := node.create_tween().set_parallel(true)
	tw.tween_property(node, "scale", Vector2(0.0, 0.0), duration) \
		.set_ease(Tween.EASE_IN) \
		.set_trans(Tween.TRANS_BACK)
	tw.tween_property(node, "modulate:a", 0.0, duration * 0.7) \
		.set_ease(Tween.EASE_IN)
	if then.is_valid():
		tw.chain().tween_callback(then)
	return tw


## Slide out to an offset.
static func slide_out(node: Control, offset: Vector2, duration: float = 0.20,
		then: Callable = Callable()) -> Tween:
	var tw := node.create_tween().set_parallel(true)
	tw.tween_property(node, "position", node.position + offset, duration) \
		.set_ease(Tween.EASE_IN) \
		.set_trans(Tween.TRANS_QUINT)
	tw.tween_property(node, "modulate:a", 0.0, duration * 0.6) \
		.set_ease(Tween.EASE_IN)
	if then.is_valid():
		tw.chain().tween_callback(then)
	return tw


## Fade out only.
static func fade_out(node: CanvasItem, duration: float = 0.18,
		then: Callable = Callable()) -> Tween:
	var tw := node.create_tween()
	tw.tween_property(node, "modulate:a", 0.0, duration) \
		.set_ease(Tween.EASE_IN)
	if then.is_valid():
		tw.chain().tween_callback(then)
	return tw


# ---------------------------------------------------------------------------
# Emphasis / feedback
# ---------------------------------------------------------------------------

## Quick scale pulse — "you earned something", click feedback on cards.
static func pulse(node: Control, scale_to: float = 1.08,
		duration: float = 0.14) -> Tween:
	var original_scale := node.scale
	node.pivot_offset = node.size * 0.5
	var tw := node.create_tween()
	tw.tween_property(node, "scale", Vector2.ONE * scale_to, duration * 0.45) \
		.set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "scale", original_scale, duration * 0.55) \
		.set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_BACK)
	return tw


## Flash a color then return to original — used for stat changes.
static func flash_color(node: CanvasItem, flash_color: Color,
		duration: float = 0.32) -> Tween:
	var orig := node.modulate
	var tw := node.create_tween()
	tw.tween_property(node, "modulate", flash_color, duration * 0.25) \
		.set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "modulate", orig, duration * 0.75) \
		.set_ease(Tween.EASE_IN_OUT)
	return tw


## Shake node horizontally — error feedback, low cash warning.
static func shake(node: Control, intensity: float = 6.0,
		duration: float = 0.30) -> Tween:
	var origin := node.position
	var tw := node.create_tween()
	var steps := 6
	for i in steps:
		var dir := 1.0 if i % 2 == 0 else -1.0
		var dampen := 1.0 - (float(i) / float(steps))
		tw.tween_property(node, "position",
			origin + Vector2(intensity * dir * dampen, 0),
			duration / float(steps)).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(node, "position", origin, duration / float(steps * 2))
	return tw


# ---------------------------------------------------------------------------
# Number roll — animated counter (e.g. cash ticking up)
# ---------------------------------------------------------------------------

## Smoothly rolls a Label from from_val to to_val over duration seconds.
## format_fn is optional: takes float, returns String. Defaults to %.0f.
static func roll_number(label: Label, from_val: float, to_val: float,
		duration: float = 0.55, format_fn: Callable = Callable()) -> Tween:
	var tw := label.create_tween()
	tw.tween_method(
		func(v: float) -> void:
			if not is_instance_valid(label):
				return
			if format_fn.is_valid():
				label.text = format_fn.call(v)
			else:
				label.text = "%.0f" % v,
		from_val, to_val, duration
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	return tw


## Roll a money label using SceneLoader.format_money — the most common case.
static func roll_money(label: Label, from_val: float, to_val: float,
		duration: float = 0.55, prefix: String = "$") -> Tween:
	return roll_number(label, from_val, to_val, duration,
		func(v: float) -> String: return prefix + SceneLoader.format_money(v))


# ---------------------------------------------------------------------------
# Screen transition helpers
# ---------------------------------------------------------------------------

## Full-screen wipe overlay — call before changing scenes.
## Creates a ColorRect child of the given CanvasLayer root, fades in, calls
## on_peak, then fades out and removes itself.
static func screen_wipe(root: CanvasLayer, on_peak: Callable,
		color: Color = Color(0.02, 0.04, 0.08, 1.0),
		duration: float = 0.28) -> void:
	var rect := ColorRect.new()
	rect.color = color
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.modulate.a = 0.0
	rect.z_index = 100
	root.add_child(rect)

	var tw := rect.create_tween()
	tw.tween_property(rect, "modulate:a", 1.0, duration * 0.4) \
		.set_ease(Tween.EASE_OUT)
	tw.tween_callback(on_peak)
	tw.tween_property(rect, "modulate:a", 0.0, duration * 0.6) \
		.set_ease(Tween.EASE_IN) \
		.set_delay(0.06)
	tw.tween_callback(rect.queue_free)


# ---------------------------------------------------------------------------
# Button press feedback — squash/stretch on tap
# ---------------------------------------------------------------------------

## Press-down effect: brief squash. Call from button_down signal.
static func button_press(node: Control) -> Tween:
	node.pivot_offset = node.size * 0.5
	var tw := node.create_tween()
	tw.tween_property(node, "scale", Vector2(0.95, 0.95), 0.06) \
		.set_ease(Tween.EASE_OUT)
	return tw


## Release effect: stretch back with spring overshoot. Call from button_up signal.
static func button_release(node: Control) -> Tween:
	node.pivot_offset = node.size * 0.5
	var tw := node.create_tween()
	tw.tween_property(node, "scale", Vector2(1.03, 1.03), 0.08) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(node, "scale", Vector2.ONE, 0.10) \
		.set_ease(Tween.EASE_OUT)
	return tw


## Full press cycle: squash → release → settle. Convenience for pressed signal.
static func button_bounce(node: Control) -> Tween:
	node.pivot_offset = node.size * 0.5
	var tw := node.create_tween()
	tw.tween_property(node, "scale", Vector2(0.92, 0.92), 0.05) \
		.set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "scale", Vector2(1.06, 1.06), 0.10) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(node, "scale", Vector2.ONE, 0.08) \
		.set_ease(Tween.EASE_OUT)
	return tw


# ---------------------------------------------------------------------------
# Floating number pop-up — "+$50K" rising and fading
# ---------------------------------------------------------------------------

## Spawn a floating label that drifts upward and fades out.
## Attaches to parent_node's tree position.
static func float_text(parent: Control, text: String, color: Color,
		offset: Vector2 = Vector2.ZERO, duration: float = 1.2) -> void:
	if not is_instance_valid(parent):
		return
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = offset + Vector2(-40, -20)
	label.z_index = 50
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)

	var tw := label.create_tween().set_parallel(true)
	tw.tween_property(label, "position:y", label.position.y - 60.0, duration) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	tw.tween_property(label, "modulate:a", 0.0, duration * 0.4) \
		.set_delay(duration * 0.6).set_ease(Tween.EASE_IN)
	# Scale up briefly then settle.
	tw.tween_property(label, "scale", Vector2(1.15, 1.15), duration * 0.15) \
		.set_ease(Tween.EASE_OUT)
	tw.tween_property(label, "scale", Vector2.ONE, duration * 0.2) \
		.set_delay(duration * 0.15).set_ease(Tween.EASE_OUT)
	tw.chain().tween_callback(label.queue_free)


## Float a money change: green for gains, red for losses.
static func float_money(parent: Control, amount: float,
		offset: Vector2 = Vector2.ZERO) -> void:
	if absf(amount) < 1.0:
		return
	var text: String
	var color: Color
	if amount >= 0:
		text = "+$%s" % SceneLoader.format_money(amount)
		color = ThemeManager.C_GREEN
	else:
		text = "-$%s" % SceneLoader.format_money(absf(amount))
		color = ThemeManager.C_RED
	float_text(parent, text, color, offset)


## Float a user count change.
static func float_users(parent: Control, count: int,
		offset: Vector2 = Vector2.ZERO) -> void:
	if count == 0:
		return
	var text: String
	var color: Color
	if count > 0:
		text = "+%s users" % SceneLoader.format_number(count)
		color = ThemeManager.C_TEAL
	else:
		text = "%s users" % SceneLoader.format_number(count)
		color = ThemeManager.C_RED
	float_text(parent, text, color, offset)


# ---------------------------------------------------------------------------
# Screen shake — trauma-based for impact on major events
# ---------------------------------------------------------------------------

## Shake the entire screen by offsetting the root viewport.
## Intensity 1.0 = strong (funding round), 0.5 = medium, 0.2 = subtle.
static func screen_shake(tree: SceneTree, intensity: float = 0.5,
		duration: float = 0.35) -> void:
	var root := tree.root
	if root == null:
		return
	var original_offset := root.canvas_transform.origin
	var steps := 8
	var step_time := duration / float(steps)

	var tw := tree.create_tween()
	for i in steps:
		var dampen := 1.0 - (float(i) / float(steps))
		var offset := Vector2(
			randf_range(-1.0, 1.0) * intensity * 12.0 * dampen,
			randf_range(-1.0, 1.0) * intensity * 8.0 * dampen,
		)
		tw.tween_callback(func() -> void:
			root.canvas_transform.origin = original_offset + offset
		)
		tw.tween_interval(step_time)
	tw.tween_callback(func() -> void:
		root.canvas_transform.origin = original_offset
	)


# ---------------------------------------------------------------------------
# Haptic feedback — mobile vibration
# ---------------------------------------------------------------------------

## Fire a haptic vibration. Light=30ms, medium=80ms, heavy=150ms.
## Respects the global haptic preference in SfxPlayer. Silently no-ops on desktop.
static func haptic(strength: StringName = &"light") -> void:
	var sfx: Node = Engine.get_singleton("SfxPlayer") if Engine.has_singleton("SfxPlayer") else null
	if sfx == null:
		sfx = (Engine.get_main_loop() as SceneTree).root.get_node_or_null("SfxPlayer") if Engine.get_main_loop() is SceneTree else null
	if sfx != null and not bool(sfx.get("haptic_enabled")):
		return
	var ms: int
	match strength:
		&"light":  ms = 30
		&"medium": ms = 80
		&"heavy":  ms = 150
		_:         ms = 30
	Input.vibrate_handheld(ms)


# ---------------------------------------------------------------------------
# Backdrop overlay for modals
# ---------------------------------------------------------------------------

## Backdrop overlay for modals — semi-transparent dark fill.
static func show_backdrop(root: Control, alpha: float = 0.60) -> ColorRect:
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.0, 0.0, 0.0, 0.0)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.z_index = 10
	root.add_child(backdrop)
	var tw := backdrop.create_tween()
	tw.tween_property(backdrop, "color", Color(0.0, 0.0, 0.0, alpha), 0.20) \
		.set_ease(Tween.EASE_OUT)
	return backdrop


static func hide_backdrop(backdrop: ColorRect, then: Callable = Callable()) -> void:
	if not is_instance_valid(backdrop):
		return
	var tw := backdrop.create_tween()
	tw.tween_property(backdrop, "color", Color(0.0, 0.0, 0.0, 0.0), 0.16) \
		.set_ease(Tween.EASE_IN)
	tw.tween_callback(backdrop.queue_free)
	if then.is_valid():
		tw.tween_callback(then)
