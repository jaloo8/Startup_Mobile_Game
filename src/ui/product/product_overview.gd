extends Control
## Product overview screen — see product health and feature list.

@onready var features_label: Label = %FeaturesLabel
@onready var tech_debt_bar: ProgressBar = %TechDebtBar
@onready var bugs_label: Label = %BugsLabel
@onready var stability_bar: ProgressBar = %StabilityBar
@onready var ux_bar: ProgressBar = %UxBar
@onready var users_label: Label = %UsersLabel
@onready var churn_label: Label = %ChurnLabel
@onready var feature_list_container: VBoxContainer = %FeatureListContainer
@onready var back_btn: Button = %BackButton

const MAX_VISIBLE_FEATURES := 50


func _ready() -> void:
	back_btn.pressed.connect(_on_back)
	_refresh()


func _refresh() -> void:
	var p := GameState.product
	if p == null:
		return

	features_label.text = "%d features (avg quality: %d)" % [p.feature_count(), roundi(p.avg_feature_quality())]
	tech_debt_bar.value = p.tech_debt
	bugs_label.text = "%d bugs" % p.bugs
	stability_bar.value = p.stability
	ux_bar.value = p.ux_score
	users_label.text = "%s users (%s DAU)" % [_fmt(p.users), _fmt(p.dau)]
	churn_label.text = "Churn: %.1f%%" % (p.churn_rate * 100)

	_free_children(feature_list_container)

	if p.features.is_empty():
		var lbl := Label.new()
		lbl.text = "No features shipped yet."
		lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
		feature_list_container.add_child(lbl)
		return

	var visible_features: Array = p.features
	if visible_features.size() > MAX_VISIBLE_FEATURES:
		visible_features = visible_features.slice(-MAX_VISIBLE_FEATURES)

	for f in visible_features:
		var lbl := Label.new()
		var quality: int = f.get("quality", 0)
		var color: Color
		if quality >= 70:
			color = Color(0.3, 0.85, 0.4)
		elif quality >= 50:
			color = Color(0.9, 0.8, 0.2)
		else:
			color = Color(0.9, 0.3, 0.3)
		lbl.text = "%s — quality %d (Q%d)" % [f.get("name", "?"), quality, f.get("quarter_shipped", 0)]
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.add_theme_color_override("font_color", color)
		feature_list_container.add_child(lbl)


func _fmt(n: int) -> String:
	if n >= 1_000_000:
		return "%.1fM" % (n / 1_000_000.0)
	elif n >= 1_000:
		return "%.1fK" % (n / 1_000.0)
	return str(n)


func _on_back() -> void:
	SceneLoader.goto_scene("res://src/ui/dashboard/quarter_dashboard.tscn")


static func _free_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
