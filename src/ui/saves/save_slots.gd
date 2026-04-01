extends Control
## Save slot management screen — view, load, and delete up to 5 saved companies.

@onready var back_btn: Button = %BackButton
@onready var slot_container: VBoxContainer = %SlotContainer

var _card_style: StyleBoxFlat
var _empty_style: StyleBoxFlat
var _confirm_slot: String = ""


func _ready() -> void:
	_card_style = _make_style(Color(0.12, 0.12, 0.16))
	_empty_style = _make_style(Color(0.09, 0.09, 0.12))
	back_btn.pressed.connect(_on_back)
	_refresh()


func _exit_tree() -> void:
	_card_style = null
	_empty_style = null


func _refresh() -> void:
	SceneLoader.free_children(slot_container)
	_confirm_slot = ""

	var saves := GameState.list_saves()
	if saves.is_empty():
		for idx in range(1, 6):
			saves.append({
				"slot": "slot_%d" % idx,
				"exists": false,
			})
	for raw_info in saves:
		var save_info: Dictionary = raw_info if raw_info is Dictionary else {}
		var slot_name: String = str(save_info.get("slot", ""))
		if not _is_slot_unlocked(slot_name):
			slot_container.add_child(_create_locked_slot(save_info))
		elif save_info.get("exists", false):
			slot_container.add_child(_create_occupied_slot(save_info))
		else:
			slot_container.add_child(_create_empty_slot(save_info))

	# Safety fallback: if save listing fails for any reason, still show one entry
	# so players are never blocked from starting a new run.
	if slot_container.get_child_count() == 0:
		slot_container.add_child(_create_empty_slot({"slot": "slot_1"}))


func _create_occupied_slot(info: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _card_style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	panel.add_child(hbox)

	var info_vbox := VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 3)
	hbox.add_child(info_vbox)

	var name_label := Label.new()
	var type_name: String = CompanyData.TYPE_NAMES.get(info.get("company_type", 0), "Unknown")
	name_label.text = "%s — %s" % [info.get("company_name", "???"), type_name]
	name_label.add_theme_font_size_override("font_size", 16)
	info_vbox.add_child(name_label)

	var detail_label := Label.new()
	var cash_str := SceneLoader.format_money(info.get("cash", 0.0))
	var user_str := SceneLoader.format_number(info.get("users", 0))
	detail_label.text = "Year %d, Q%d · $%s · %s users · %d employees" % [
		info.get("year", 1),
		info.get("quarter", 1),
		cash_str,
		user_str,
		info.get("employees", 0),
	]
	detail_label.add_theme_font_size_override("font_size", 12)
	detail_label.add_theme_color_override("font_color", Color(0.55, 0.55, 0.6))
	info_vbox.add_child(detail_label)

	var diff_label := Label.new()
	diff_label.text = info.get("difficulty", "normal").capitalize()
	diff_label.add_theme_font_size_override("font_size", 11)
	diff_label.add_theme_color_override("font_color", Color(0.45, 0.45, 0.5))
	info_vbox.add_child(diff_label)

	var btn_vbox := VBoxContainer.new()
	btn_vbox.add_theme_constant_override("separation", 6)
	hbox.add_child(btn_vbox)

	var slot_name: String = info["slot"]

	var load_btn := Button.new()
	load_btn.text = "Load"
	load_btn.custom_minimum_size = Vector2(80, 34)
	load_btn.pressed.connect(_on_load.bind(slot_name))
	btn_vbox.add_child(load_btn)

	var delete_btn := Button.new()
	delete_btn.text = "Delete"
	delete_btn.custom_minimum_size = Vector2(80, 34)
	delete_btn.pressed.connect(_on_delete_pressed.bind(slot_name, delete_btn))
	btn_vbox.add_child(delete_btn)

	return panel


func _create_empty_slot(_info: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _empty_style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	panel.add_child(hbox)

	var label := Label.new()
	label.text = "Empty Slot"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
	hbox.add_child(label)

	var slot_name: String = _info["slot"]
	var new_btn := Button.new()
	new_btn.text = "New Game"
	new_btn.custom_minimum_size = Vector2(100, 38)
	new_btn.pressed.connect(_on_new_game.bind(slot_name))
	hbox.add_child(new_btn)

	return panel


func _create_locked_slot(info: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _empty_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var slot_name: String = str(info.get("slot", "slot_0"))
	var slot_idx := _slot_index(slot_name)
	var title := Label.new()
	title.text = "Premium Slot %d" % slot_idx
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color(0.86, 0.76, 0.42))
	vbox.add_child(title)

	var desc := Label.new()
	if info.get("exists", false):
		desc.text = "Saved run in this slot is locked in free mode.\nUnlock full game to access it."
	else:
		desc.text = "Unlock full game to use this additional save slot."
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", Color(0.58, 0.58, 0.64))
	vbox.add_child(desc)

	var unlock_btn := Button.new()
	unlock_btn.text = "Unlock Full Game"
	unlock_btn.custom_minimum_size = Vector2(140, 36)
	unlock_btn.pressed.connect(func() -> void:
		_show_unlock_paywall(
			func() -> void: _refresh(),
			Callable()
		)
	)
	vbox.add_child(unlock_btn)
	return panel


func _on_load(slot_name: String) -> void:
	if not _is_slot_unlocked(slot_name):
		_show_unlock_paywall(
			func() -> void: _refresh(),
			Callable()
		)
		return
	GameState.current_slot = slot_name
	if GameState.load_game(slot_name):
		EventEngine.load_events("res://src/data/events.json")
		ProductData.load_feature_catalog("res://src/data/features.json")
		CompanyData.load_niche_catalog()
		HeadlineEngine.load_headlines("res://src/data/headlines.json")
		SceneLoader.goto_scene("res://src/ui/dashboard/quarter_dashboard.tscn")


func _on_new_game(slot_name: String) -> void:
	if not _is_slot_unlocked(slot_name):
		_show_unlock_paywall(
			func() -> void: _refresh(),
			Callable()
		)
		return
	GameState.current_slot = slot_name
	SceneLoader.goto_scene("res://src/ui/setup/new_game.tscn")


func _on_delete_pressed(slot_name: String, btn: Button) -> void:
	if _confirm_slot == slot_name:
		GameState.delete_save(slot_name)
		_refresh()
	else:
		_confirm_slot = slot_name
		btn.text = "Confirm?"
		btn.add_theme_color_override("font_color", Color(0.95, 0.3, 0.3))


func _on_back() -> void:
	SceneLoader.goto_scene("res://src/ui/main_menu/main_menu.tscn")


static func _make_style(bg: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(8)
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 12
	s.content_margin_bottom = 12
	return s


func _is_slot_unlocked(slot_name: String) -> bool:
	if _is_premium_safe():
		return true
	return _slot_index(slot_name) <= _max_save_slots()


static func _slot_index(slot_name: String) -> int:
	var parts := slot_name.split("_")
	if parts.size() < 2:
		return 999
	return maxi(1, int(parts[1]))


func _ad_manager() -> Node:
	return get_node_or_null("/root/AdManager")


func _is_premium_safe() -> bool:
	var mgr := _ad_manager()
	if mgr == null:
		return false
	if not mgr.has_method("is_premium"):
		return false
	return bool(mgr.call("is_premium"))


func _max_save_slots() -> int:
	var mgr := _ad_manager()
	if mgr == null:
		return 5
	if not mgr.has_method("max_save_slots"):
		return 5
	return clampi(int(mgr.call("max_save_slots")), 1, 5)


func _show_unlock_paywall(on_unlock: Callable = Callable(), on_cancel: Callable = Callable()) -> void:
	var mgr := _ad_manager()
	if mgr and mgr.has_method("show_paywall"):
		mgr.call("show_paywall", on_unlock, on_cancel)
	else:
		# Safe fallback: don't hard-block the player if paywall manager is unavailable.
		if on_unlock.is_valid():
			on_unlock.call()
