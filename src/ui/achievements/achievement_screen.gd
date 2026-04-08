extends Control
## Achievement browser — shows all achievements, their unlock status, and progress.

@onready var back_btn: Button = %BackButton

const TIER_COLORS: Dictionary = {
	"bronze": Color(0.72, 0.55, 0.35),
	"silver": Color(0.70, 0.72, 0.78),
	"gold": Color(0.96, 0.74, 0.31),
	"platinum": Color(0.80, 0.60, 0.92),
}

const CATEGORY_ORDER: Array = [
	"milestone", "financial", "product", "team", "challenge", "secret",
]

const CATEGORY_LABELS: Dictionary = {
	"milestone": "Milestones",
	"financial": "Financial",
	"product": "Product",
	"team": "Team",
	"challenge": "Challenges",
	"secret": "Secrets",
}

var _scroll: ScrollContainer
var _list_vbox: VBoxContainer


func _ready() -> void:
	back_btn.pressed.connect(_on_back)
	UITouchHelper.harden_tree(self)
	Analytics.track_screen("achievements")
	_build_ui()


# ---------------------------------------------------------------------------
# UI construction
# ---------------------------------------------------------------------------

func _build_ui() -> void:
	var root_vbox := VBoxContainer.new()
	root_vbox.layout_mode = 1
	root_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_vbox.offset_top = 64.0
	root_vbox.offset_left = 16.0
	root_vbox.offset_right = -16.0
	root_vbox.offset_bottom = -16.0
	root_vbox.add_theme_constant_override("separation", 12)
	add_child(root_vbox)

	# Header row: title + progress.
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	root_vbox.add_child(header)

	var title := Label.new()
	title.text = "ACHIEVEMENTS"
	title.add_theme_font_size_override("font_size", ThemeManager.FONT_XL)
	title.add_theme_color_override("font_color", ThemeManager.C_GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var progress_lbl := Label.new()
	var ach_mgr: Node = _get_achievement_manager()
	if ach_mgr:
		progress_lbl.text = "%d / %d" % [ach_mgr.get_unlock_count(), ach_mgr.get_total_count()]
	else:
		progress_lbl.text = ""
	progress_lbl.add_theme_font_size_override("font_size", ThemeManager.FONT_LG)
	progress_lbl.add_theme_color_override("font_color", ThemeManager.C_TEXT_DIM)
	progress_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(progress_lbl)

	# Scrollable list.
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_vbox.add_child(_scroll)

	_list_vbox = VBoxContainer.new()
	_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_vbox.add_theme_constant_override("separation", 8)
	_scroll.add_child(_list_vbox)

	if ach_mgr == null:
		_add_empty_state("Achievement data unavailable")
		return

	var all: Array[Dictionary] = ach_mgr.get_all()
	if all.is_empty():
		_add_empty_state("No achievements defined")
		return

	# Group by category.
	var by_cat: Dictionary = {}
	for def: Dictionary in all:
		var cat: String = def.get("category", "milestone")
		if not by_cat.has(cat):
			by_cat[cat] = []
		by_cat[cat].append(def)

	# Build sections in defined order.
	for cat in CATEGORY_ORDER:
		if not by_cat.has(cat):
			continue
		_build_category_section(cat, by_cat[cat], ach_mgr)

	# Animate the list in.
	AnimHelper.stagger_list(_list_vbox, 0.04, 0.02, 16.0)


func _build_category_section(cat: String, defs: Array, ach_mgr: Node) -> void:
	# Count unlocked in this category.
	var unlocked_count := 0
	for def: Dictionary in defs:
		if ach_mgr.is_unlocked(def.get("id", "")):
			unlocked_count += 1

	# Category header.
	var cat_label := Label.new()
	cat_label.text = "%s  (%d/%d)" % [CATEGORY_LABELS.get(cat, cat.capitalize()), unlocked_count, defs.size()]
	cat_label.add_theme_font_size_override("font_size", ThemeManager.FONT_SM)
	cat_label.add_theme_color_override("font_color", ThemeManager.C_TEXT_DIM)
	_list_vbox.add_child(cat_label)

	# Achievement cards.
	for def: Dictionary in defs:
		var id: String = def.get("id", "")
		var unlocked: bool = ach_mgr.is_unlocked(id)
		var hidden: bool = def.get("hidden", false)
		_list_vbox.add_child(_build_card(def, unlocked, hidden))


func _build_card(def: Dictionary, unlocked: bool, hidden: bool) -> PanelContainer:
	var card := PanelContainer.new()
	var tier: String = def.get("tier", "bronze")
	var tier_color: Color = TIER_COLORS.get(tier, TIER_COLORS["bronze"])

	# Card style — subtle tier tint on unlocked, muted on locked.
	var card_bg: Color
	var card_border: Color
	if unlocked:
		card_bg = Color(tier_color.r * 0.12, tier_color.g * 0.12, tier_color.b * 0.12, 1.0).lerp(ThemeManager.C_SURFACE, 0.7)
		card_border = tier_color.lerp(ThemeManager.C_BORDER, 0.5)
	else:
		card_bg = ThemeManager.C_SURFACE_LOW
		card_border = ThemeManager.C_BORDER.lerp(ThemeManager.C_SURFACE_LOW, 0.5)
	var style := ThemeManager._flat_box_static(card_bg, card_border, ThemeManager.CORNER_MD)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	card.add_theme_stylebox_override("panel", style)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)

	# Icon.
	var icon_lbl := Label.new()
	if unlocked or not hidden:
		icon_lbl.text = def.get("icon", "?")
	else:
		icon_lbl.text = "?"
	icon_lbl.add_theme_font_size_override("font_size", 24)
	icon_lbl.custom_minimum_size = Vector2(36, 0)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if not unlocked:
		icon_lbl.modulate.a = 0.35
	row.add_child(icon_lbl)

	# Text column.
	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.add_theme_constant_override("separation", 2)
	row.add_child(text_col)

	# Title.
	var title_lbl := Label.new()
	if unlocked or not hidden:
		title_lbl.text = def.get("title", "???")
	else:
		title_lbl.text = "???"
	title_lbl.add_theme_font_size_override("font_size", ThemeManager.FONT_MD)
	if unlocked:
		title_lbl.add_theme_color_override("font_color", ThemeManager.C_TEXT)
	else:
		title_lbl.add_theme_color_override("font_color", ThemeManager.C_TEXT_MUTED)
	text_col.add_child(title_lbl)

	# Description.
	var desc_lbl := Label.new()
	if unlocked or not hidden:
		desc_lbl.text = def.get("description", "")
	else:
		desc_lbl.text = "Hidden — unlock to reveal"
	desc_lbl.add_theme_font_size_override("font_size", ThemeManager.FONT_XS)
	desc_lbl.add_theme_color_override("font_color", ThemeManager.C_TEXT_DIM if unlocked else ThemeManager.C_TEXT_MUTED)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_col.add_child(desc_lbl)

	# Reward chips (show for unlocked or visible achievements).
	var chips: int = int(def.get("reward_chips", 0))
	if chips > 0 and (unlocked or not hidden):
		var chips_lbl := Label.new()
		chips_lbl.text = "+%d" % chips if unlocked else "%d" % chips
		chips_lbl.add_theme_font_size_override("font_size", ThemeManager.FONT_SM)
		chips_lbl.add_theme_color_override("font_color", ThemeManager.C_CHIP if unlocked else ThemeManager.C_TEXT_MUTED)
		chips_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		chips_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		chips_lbl.custom_minimum_size = Vector2(32, 0)
		row.add_child(chips_lbl)

	# Tier badge.
	var tier_lbl := Label.new()
	tier_lbl.text = tier.substr(0, 1).to_upper()
	tier_lbl.add_theme_font_size_override("font_size", ThemeManager.FONT_XS)
	if unlocked:
		tier_lbl.add_theme_color_override("font_color", tier_color)
	else:
		tier_lbl.add_theme_color_override("font_color", ThemeManager.C_TEXT_MUTED)
	tier_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tier_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tier_lbl.custom_minimum_size = Vector2(18, 0)
	row.add_child(tier_lbl)

	return card


func _add_empty_state(message: String) -> void:
	var lbl := Label.new()
	lbl.text = message
	lbl.add_theme_font_size_override("font_size", ThemeManager.FONT_MD)
	lbl.add_theme_color_override("font_color", ThemeManager.C_TEXT_DIM)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list_vbox.add_child(lbl)


func _get_achievement_manager() -> Node:
	return get_node_or_null("/root/AchievementManager")


func _on_back() -> void:
	SceneLoader.goto_scene("res://src/ui/main_menu/main_menu.tscn")
