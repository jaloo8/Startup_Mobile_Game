extends Control
## Market leaderboard — shows the player's company ranked among competitors.
## Sorted by users (the primary growth metric). Player row is highlighted.

@onready var back_btn: Button = %BackButton
@onready var list_container: VBoxContainer = %LeaderboardList
@onready var industry_label: Label = %IndustryLabel

var _card_style: StyleBoxFlat
var _player_style: StyleBoxFlat


func _ready() -> void:
	_card_style = _make_style(Color(0.12, 0.12, 0.16))
	_player_style = _make_style(Color(0.15, 0.20, 0.30))
	back_btn.pressed.connect(_on_back)
	_refresh()


func _exit_tree() -> void:
	_card_style = null
	_player_style = null


func _refresh() -> void:
	_free_children(list_container)

	if GameState.company == null:
		return

	industry_label.text = "%s Industry" % GameState.company.type_name()

	var entries: Array[Dictionary] = []

	entries.append({
		"name": GameState.company.company_name,
		"users": GameState.product.users,
		"tagline": GameState.company.type_name(),
		"is_player": true,
		"funding": _total_funding(),
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
	rank_label.add_theme_font_size_override("font_size", 18)
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
	name_label.add_theme_font_size_override("font_size", 15)
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
	users_label.text = "%s users" % _fmt_number(entry.get("users", 0))
	users_label.add_theme_font_size_override("font_size", 13)
	users_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stats_vbox.add_child(users_label)

	var funding_label := Label.new()
	funding_label.text = "$%s raised" % _fmt_money(float(entry.get("funding", 0)))
	funding_label.add_theme_font_size_override("font_size", 11)
	funding_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	funding_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stats_vbox.add_child(funding_label)

	return panel


func _total_funding() -> float:
	var total := 0.0
	for round_data: Dictionary in GameState.financials.funding_rounds:
		total += round_data.get("amount", 0.0)
	return total


func _on_back() -> void:
	SceneLoader.goto_scene("res://src/ui/dashboard/quarter_dashboard.tscn")


static func _fmt_number(n: int) -> String:
	if n >= 1_000_000:
		return "%.1fM" % (n / 1_000_000.0)
	elif n >= 1_000:
		return "%.1fK" % (n / 1_000.0)
	return str(n)


static func _fmt_money(amount: float) -> String:
	if absf(amount) >= 1_000_000:
		return "%.1fM" % (amount / 1_000_000)
	elif absf(amount) >= 1_000:
		return "%.0fK" % (amount / 1_000)
	return "%.0f" % amount


static func _make_style(bg: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(8)
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	return s


static func _free_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
