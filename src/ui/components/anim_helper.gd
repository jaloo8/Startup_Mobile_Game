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
