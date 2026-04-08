extends CanvasLayer
## ToastManager — lightweight notification toasts for micro-feedback.
##
## Shows small, non-blocking messages that slide in from the top and auto-dismiss.
## Supports icons (emoji), color accents, and optional tap callbacks.
##
## Usage:
##   ToastManager.show("Employee hired: Sarah Chen", "👤", ThemeManager.C_GREEN)
##   ToastManager.show_achievement("First Dollar", "💰")
##   ToastManager.show_money(50000)   # "+$50K" in green
##   ToastManager.show_loss(-12000)   # "-$12K" in red

const MAX_VISIBLE := 3
const TOAST_DURATION := 2.8  # seconds before auto-dismiss
const SLIDE_IN_TIME := 0.22
const SLIDE_OUT_TIME := 0.18
const TOAST_SPACING := 8.0
const TOAST_HEIGHT := 52.0
const TOAST_MARGIN_TOP := 48.0  # below status bar / notch

var _container: VBoxContainer
var _active_toasts: Array[Control] = []


func _ready() -> void:
	layer = 110  # above game UI, below tutorial overlay (z=100 is tutorial)
	_build_container()


func _build_container() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	margin.add_theme_constant_override("margin_top", int(TOAST_MARGIN_TOP))
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)

	_container = VBoxContainer.new()
	_container.add_theme_constant_override("separation", int(TOAST_SPACING))
	_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(_container)


## Show a toast notification with optional icon and accent color.
func show(message: String, icon: String = "", accent: Color = ThemeManager.C_BLUE) -> void:
	if _active_toasts.size() >= MAX_VISIBLE:
		_dismiss(_active_toasts[0])

	var toast := _build_toast(message, icon, accent)
	_container.add_child(toast)
	_active_toasts.append(toast)
	_animate_in(toast)

	# Auto-dismiss after duration.
	var timer := get_tree().create_timer(TOAST_DURATION)
	timer.timeout.connect(func() -> void:
		if is_instance_valid(toast) and toast.is_inside_tree():
			_dismiss(toast)
	)


## Convenience: show a money gain toast.
func show_money(amount: float) -> void:
	if amount >= 0:
		show("+$%s" % SceneLoader.format_money(amount), "💰", ThemeManager.C_GREEN)
	else:
		show("-$%s" % SceneLoader.format_money(absf(amount)), "💸", ThemeManager.C_RED)


## Convenience: show an achievement unlock toast.
func show_achievement(title: String, icon: String = "🏆") -> void:
	show("Achievement: %s" % title, icon, ThemeManager.C_GOLD)


## Convenience: show a milestone toast.
func show_milestone(title: String, icon: String = "⭐") -> void:
	show(title, icon, ThemeManager.C_PURPLE)


## Convenience: show a warning toast.
func show_warning(message: String) -> void:
	show(message, "⚠️", ThemeManager.C_GOLD)


## Convenience: show an error/danger toast.
func show_danger(message: String) -> void:
	show(message, "🔴", ThemeManager.C_RED)


func _build_toast(message: String, icon: String, accent: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(ThemeManager.C_SURFACE.r, ThemeManager.C_SURFACE.g,
		ThemeManager.C_SURFACE.b, 0.95)
	style.border_color = accent
	style.set_border_width_all(0)
	style.border_width_left = 3
	style.set_corner_radius_all(ThemeManager.CORNER_MD)
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
	style.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size.y = TOAST_HEIGHT
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	panel.add_child(hbox)

	if icon != "":
		var icon_label := Label.new()
		icon_label.text = icon
		icon_label.add_theme_font_size_override("font_size", ThemeManager.FONT_LG)
		icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hbox.add_child(icon_label)

	var msg_label := Label.new()
	msg_label.text = message
	msg_label.add_theme_font_size_override("font_size", ThemeManager.FONT_SM)
	msg_label.add_theme_color_override("font_color", ThemeManager.C_TEXT)
	msg_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	msg_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg_label.max_lines_visible = 2
	hbox.add_child(msg_label)

	# Tap to dismiss.
	panel.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			_dismiss(panel)
	)

	return panel


func _animate_in(toast: Control) -> void:
	toast.modulate.a = 0.0
	toast.position.y -= 20.0
	var target_y := toast.position.y + 20.0
	var tw := toast.create_tween().set_parallel(true)
	tw.tween_property(toast, "modulate:a", 1.0, SLIDE_IN_TIME) \
		.set_ease(Tween.EASE_OUT)
	tw.tween_property(toast, "position:y", target_y, SLIDE_IN_TIME) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	SfxPlayer.play("toast")


func _dismiss(toast: Control) -> void:
	if not is_instance_valid(toast) or not toast.is_inside_tree():
		return
	if toast in _active_toasts:
		_active_toasts.erase(toast)

	var tw := toast.create_tween().set_parallel(true)
	tw.tween_property(toast, "modulate:a", 0.0, SLIDE_OUT_TIME) \
		.set_ease(Tween.EASE_IN)
	tw.tween_property(toast, "position:y", toast.position.y - 15.0, SLIDE_OUT_TIME) \
		.set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(toast.queue_free)
