extends Control
## Ranks your company against competitors.

@onready var back_btn: Button = %BackButton
@onready var list_container: VBoxContainer = %LeaderboardList
@onready var industry_label: Label = %IndustryLabel

var _card_style: StyleBoxFlat
var _player_style: StyleBoxFlat
var _detail_panel: PanelContainer


func _ready() -> void:
	_card_style = _make_style(Color(0.12, 0.12, 0.16))
	_player_style = _make_style(Color(0.15, 0.20, 0.30))
	back_btn.pressed.connect(_on_back)
	_refresh()
	UITouchHelper.harden_tree(self)
	Analytics.track_screen("market")
	AnimHelper.stagger_list(list_container, 0.04, 0.0, 22.0)


func _exit_tree() -> void:
	_card_style = null
	_player_style = null


func _refresh() -> void:
	SceneLoader.free_children(list_container)

	if GameState.company == null:
		return

	industry_label.text = "%s Industry" % GameState.company.type_name()

	var entries: Array[Dictionary] = []

	entries.append({
		"name": GameState.company.company_name,
		"users": GameState.product.users,
		"tagline": GameState.company.type_name(),
		"is_player": true,
		"funding": GameState.financials.total_raised(),
		"quality": roundi(GameState.product.avg_feature_quality()),
	})

	for comp in GameState.market.competitors:
		entries.append({
			"name": comp.get("name", "???"),
			"users": comp.get("users", 0),
			"tagline": comp.get("tagline", ""),
			"is_player": false,
			"funding": comp.get("funding", 0),
			"quality": comp.get("product_quality", 50),
		})

	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["users"] > b["users"])

	for i in entries.size():
		var entry: Dictionary = entries[i]
		var rank := i + 1
		list_container.add_child(_create_row(rank, entry))


func _create_row(rank: int, entry: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	var is_player: bool = entry.get("is_player", false)
	panel.add_theme_stylebox_override("panel", _player_style if is_player else _card_style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	panel.add_child(hbox)

	var rank_label := Label.new()
	rank_label.text = "#%d" % rank
	rank_label.custom_minimum_size = Vector2(40, 0)
	rank_label.add_theme_font_size_override("font_size", ThemeManager.FONT_LG)
	if rank <= 3:
		rank_label.add_theme_color_override("font_color", Color(0.95, 0.8, 0.2))
	hbox.add_child(rank_label)

	var info_vbox := VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(info_vbox)

	var name_label := Label.new()
	var name_text: String = entry["name"]
	if is_player:
		name_text += "  ← You"
	name_label.text = name_text
	name_label.add_theme_font_size_override("font_size", ThemeManager.FONT_MD)
	if is_player:
		name_label.add_theme_color_override("font_color", Color(0.4, 0.7, 1.0))
	info_vbox.add_child(name_label)

	var tagline: String = entry.get("tagline", "")
	if not tagline.is_empty():
		var tag_label := Label.new()
		tag_label.text = tagline
		tag_label.add_theme_font_size_override("font_size", 12)
		tag_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
		info_vbox.add_child(tag_label)

	var stats_vbox := VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 0)
	hbox.add_child(stats_vbox)

	var users_label := Label.new()
	users_label.text = "%s users" % SceneLoader.format_number(entry.get("users", 0))
	users_label.add_theme_font_size_override("font_size", ThemeManager.FONT_SM)
	users_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stats_vbox.add_child(users_label)

	var funding_label := Label.new()
	funding_label.text = "$%s raised" % SceneLoader.format_money(float(entry.get("funding", 0)))
	funding_label.add_theme_font_size_override("font_size", ThemeManager.FONT_XS)
	funding_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	funding_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stats_vbox.add_child(funding_label)

	# Quality badge — compact display on the row itself.
	var quality_val: int = entry.get("quality", 0)
	var quality_lbl := Label.new()
	quality_lbl.text = "Q:%d" % quality_val
	quality_lbl.add_theme_font_size_override("font_size", ThemeManager.FONT_XS)
	quality_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	if quality_val >= 70:
		quality_lbl.add_theme_color_override("font_color", ThemeManager.C_GREEN)
	elif quality_val >= 40:
		quality_lbl.add_theme_color_override("font_color", ThemeManager.C_GOLD)
	else:
		quality_lbl.add_theme_color_override("font_color", ThemeManager.C_RED)
	stats_vbox.add_child(quality_lbl)

	# Make row tappable for detail popup (skip player row — they know their own stats).
	if not is_player:
		panel.gui_input.connect(_on_row_tapped.bind(entry))
		panel.mouse_filter = Control.MOUSE_FILTER_STOP

	return panel



func _on_row_tapped(event: InputEvent, entry: Dictionary) -> void:
	if not event is InputEventMouseButton:
		return
	var mb := event as InputEventMouseButton
	if not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	_show_competitor_detail(entry)


func _show_competitor_detail(entry: Dictionary) -> void:
	_dismiss_detail()

	_detail_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.12, 0.20, 0.96)
	style.set_corner_radius_all(ThemeManager.CORNER_LG)
	style.set_content_margin_all(16.0)
	style.border_color = ThemeManager.C_BLUE.darkened(0.3)
	style.border_width_top = 1
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	_detail_panel.add_theme_stylebox_override("panel", style)
	_detail_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_detail_panel.custom_minimum_size = Vector2(320, 0)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_detail_panel.add_child(vbox)

	var title := Label.new()
	title.text = str(entry.get("name", "???"))
	title.add_theme_font_size_override("font_size", ThemeManager.FONT_LG)
	title.add_theme_color_override("font_color", ThemeManager.C_TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var tagline: String = entry.get("tagline", "")
	if not tagline.is_empty():
		var tag := Label.new()
		tag.text = tagline
		tag.add_theme_font_size_override("font_size", ThemeManager.FONT_SM)
		tag.add_theme_color_override("font_color", ThemeManager.C_TEXT_DIM)
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(tag)

	var sep := HSeparator.new()
	sep.add_theme_color_override("color", Color(0.20, 0.24, 0.40, 0.5))
	vbox.add_child(sep)

	var stats: Array[PackedStringArray] = [
		PackedStringArray(["Users", SceneLoader.format_number(entry.get("users", 0))]),
		PackedStringArray(["Funding Raised", "$%s" % SceneLoader.format_money(float(entry.get("funding", 0)))]),
		PackedStringArray(["Product Quality", "%d / 100" % entry.get("quality", 0)]),
	]
	for pair: PackedStringArray in stats:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		vbox.add_child(row)
		var key_lbl := Label.new()
		key_lbl.text = pair[0]
		key_lbl.add_theme_font_size_override("font_size", ThemeManager.FONT_SM)
		key_lbl.add_theme_color_override("font_color", ThemeManager.C_TEXT_DIM)
		key_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(key_lbl)
		var val_lbl := Label.new()
		val_lbl.text = pair[1]
		val_lbl.add_theme_font_size_override("font_size", ThemeManager.FONT_SM)
		val_lbl.add_theme_color_override("font_color", ThemeManager.C_TEXT)
		row.add_child(val_lbl)

	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.custom_minimum_size = Vector2(0, ThemeManager.TOUCH_MIN_H)
	close_btn.pressed.connect(_dismiss_detail)
	vbox.add_child(close_btn)

	add_child(_detail_panel)
	AnimHelper.pop_in(_detail_panel, 0.0, 0.2)
	SfxPlayer.play("click")


func _dismiss_detail() -> void:
	if _detail_panel and is_instance_valid(_detail_panel):
		_detail_panel.queue_free()
		_detail_panel = null


func _on_back() -> void:
	if OS.is_debug_build():
		print("[Market] _on_back() called — transitioning=%s" % SceneLoader._transitioning)
	_dismiss_detail()
	SceneLoader.goto_scene("res://src/ui/dashboard/quarter_dashboard.tscn")


static func _make_style(bg: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(8)
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	return s
