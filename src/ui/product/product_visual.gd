extends PanelContainer
## ProductVisual — an evolving mock-UI of the player's product.
## Call  setup(company_type)  once when the product screen loads,
## then  refresh(shipped_feature_ids)  after each quarter advance.
## Newly-unlocked elements fade in automatically.

const FEATURE_IDLE_STYLES := {
	# Consumer
	"push_notifications": "ping",
	"stories": "ping",
	"recommendations": "breathe",
	"iap": "scan",
	"live_chat": "ping",
	# SaaS
	"api_v2": "scan",
	"analytics": "scan",
	"custom_reports": "scan",
	"integrations": "breathe",
	"audit_log": "ping",
	"multi_tenancy": "breathe",
	# Marketplace
	"delivery_tracking": "scan",
	"disputes": "ping",
	"promoted_listings": "ping",
	"referral_program": "breathe",
	"seller_analytics": "scan",
	# Dev Tools
	"sandbox": "breathe",
	"webhooks": "ping",
	"rate_limiting": "scan",
	"usage_dashboard": "scan",
	"plugin_system": "breathe",
	"cicd_integration": "ping",
}

var _feature_map: Dictionary = {}       # feature_id -> Control to reveal
var _unlocked_features: Dictionary = {} # feature_id -> true when permanently unlocked
var _preview_feature_id: String = ""    # temporary in-progress preview (not shipped yet)
var _idle_tweens: Dictionary = {}       # feature_id -> Tween (looping idle effects)
var _preview_tween: Tween               # pulsing preview tween while building
var _company_type: int = -1
var _consumer_nodes: Dictionary = {}    # named refs for richer consumer animations
var _consumer_tweens: Array[Tween] = []
var _ken_burns_tweens: Array[Tween] = []  # slow-zoom loops on image cards
var _shimmer_tweens: Dictionary = {}      # feature_id -> Tween (skeleton sweep)
var _shimmer_nodes: Dictionary = {}       # feature_id -> ColorRect overlay

# ─────────────────────────────────────────────────────────────────────────────
# Public API
# ─────────────────────────────────────────────────────────────────────────────

func setup(company_type: int) -> void:
	for c: Node in get_children():
		c.queue_free()
	_clear_idle_animations()
	_clear_preview_animation()
	_clear_consumer_runtime()
	_feature_map.clear()
	_unlocked_features.clear()
	_preview_feature_id = ""
	_company_type = company_type
	add_theme_stylebox_override("panel", _sfb(Color(0.055, 0.060, 0.110), 8))
	match company_type:
		CompanyData.CompanyType.CONSUMER:    _build_consumer()
		CompanyData.CompanyType.SAAS:        _build_saas()
		CompanyData.CompanyType.MARKETPLACE: _build_marketplace()
		CompanyData.CompanyType.DEV_TOOLS:   _build_dev_tools()


func _exit_tree() -> void:
	_clear_preview_animation()
	_clear_idle_animations()
	_clear_consumer_runtime()
	_feature_map.clear()
	_unlocked_features.clear()
	_preview_feature_id = ""
	_company_type = -1


func refresh(shipped_ids: Array) -> void:
	for fid: String in shipped_ids:
		if fid.is_empty():
			continue
		var was_unlocked: bool = _unlocked_features.get(fid, false)
		_unlocked_features[fid] = true
		var node: Control = _feature_map.get(fid)
		if node and not was_unlocked:
			_reveal_feature(fid, node)

	# Once shipped, preview is no longer temporary.
	if not _preview_feature_id.is_empty() and _unlocked_features.get(_preview_feature_id, false):
		_clear_preview_animation()
		_preview_feature_id = ""


func set_build_preview(feature_id: String, progress_01: float) -> void:
	var next_id: String = feature_id.strip_edges()

	# Clear the old temporary preview if we switched targets.
	if _preview_feature_id != next_id and not _preview_feature_id.is_empty():
		if not _unlocked_features.get(_preview_feature_id, false):
			var old_node: Control = _feature_map.get(_preview_feature_id)
			if old_node:
				old_node.visible = false
				old_node.modulate = Color(1, 1, 1, 1)
				old_node.scale = Vector2.ONE
		_clear_preview_animation()
		_stop_shimmer(_preview_feature_id)
		_preview_feature_id = ""

	if next_id.is_empty():
		_clear_preview_animation()
		_update_consumer_build_meter("", 0.0)
		return
	if _unlocked_features.get(next_id, false):
		_clear_preview_animation()
		_stop_shimmer(next_id)
		_update_consumer_build_meter("", 0.0)
		return

	var node: Control = _feature_map.get(next_id)
	if node == null:
		_clear_preview_animation()
		_update_consumer_build_meter("", 0.0)
		return

	_preview_feature_id = next_id
	node.visible = true
	_set_preview_state(node, progress_01)
	_start_preview_animation(node, progress_01)
	# Start shimmer the first time this preview target becomes active.
	if not _shimmer_tweens.has(next_id):
		_start_shimmer(node, next_id)
	_update_consumer_build_meter(next_id, progress_01)


# ─────────────────────────────────────────────────────────────────────────────
# Layout helpers
# ─────────────────────────────────────────────────────────────────────────────

func _clear_idle_animations() -> void:
	for tw: Tween in _idle_tweens.values():
		if tw:
			tw.kill()
	_idle_tweens.clear()


func _clear_preview_animation() -> void:
	if _preview_tween:
		_preview_tween.kill()
		_preview_tween = null


func _clear_consumer_runtime() -> void:
	for tw: Tween in _consumer_tweens:
		if tw:
			tw.kill()
	_consumer_tweens.clear()
	for tw: Tween in _ken_burns_tweens:
		if tw:
			tw.kill()
	_ken_burns_tweens.clear()
	for fid: String in _shimmer_tweens:
		var tw := _shimmer_tweens[fid] as Tween
		if tw:
			tw.kill()
	_shimmer_tweens.clear()
	for fid: String in _shimmer_nodes:
		var sn := _shimmer_nodes[fid] as Node
		if sn and is_instance_valid(sn):
			sn.queue_free()
	_shimmer_nodes.clear()
	_consumer_nodes.clear()


func _track_consumer_tween(tw: Tween) -> void:
	if tw:
		_consumer_tweens.append(tw)


## Slow Ken-Burns zoom on the first TextureRect child of a card node.
## Scales from 1.0 → 1.06 and back on a 13-second loop (6.5s each direction).
## Because the parent has clip_contents = true the overflow is hidden, so the
## zoom looks like the image is gently breathing inward from the top-left corner.
func _start_ken_burns(card_node: Control) -> void:
	for child: Node in card_node.get_children():
		if child is TextureRect:
			var tr := child as TextureRect
			var tw := create_tween()
			tw.set_loops()
			tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tw.tween_property(tr, "scale", Vector2(1.06, 1.06), 6.5)
			tw.tween_property(tr, "scale", Vector2.ONE, 6.5)
			_ken_burns_tweens.append(tw)
			break


## Skeleton-loading shimmer: a translucent white strip sweeps left→right across
## the node repeatedly.  Only runs on nodes that have clip_contents = true so
## the strip is neatly cropped to the card shape.
func _start_shimmer(node: Control, fid: String) -> void:
	if not node.clip_contents:
		return
	_stop_shimmer(fid)
	var shimmer := ColorRect.new()
	shimmer.color = Color(1.0, 1.0, 1.0, 0.13)
	shimmer.size = Vector2(30, 400)       # tall enough to fill any card height
	shimmer.position = Vector2(-38, 0)
	shimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shimmer.z_index = 10
	node.add_child(shimmer)
	_shimmer_nodes[fid] = shimmer
	var tw := create_tween()
	tw.set_loops()
	tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(shimmer, "position:x", 260.0, 0.85)
	tw.tween_interval(0.65)
	tw.tween_property(shimmer, "position:x", -38.0, 0.0)   # instant reset
	_shimmer_tweens[fid] = tw


func _stop_shimmer(fid: String) -> void:
	if _shimmer_tweens.has(fid):
		var tw := _shimmer_tweens[fid] as Tween
		if tw:
			tw.kill()
		_shimmer_tweens.erase(fid)
	if _shimmer_nodes.has(fid):
		var sn := _shimmer_nodes[fid] as Node
		if sn and is_instance_valid(sn):
			sn.queue_free()
		_shimmer_nodes.erase(fid)


func _reveal_feature(feature_id: String, node: Control) -> void:
	_stop_shimmer(feature_id)   # remove skeleton sweep now that feature is real
	if _company_type == CompanyData.CompanyType.CONSUMER and _reveal_consumer_feature(feature_id, node):
		return

	var tw: Tween = _reveal(node)
	if tw:
		tw.finished.connect(func() -> void:
			_start_idle_animation(feature_id, node)
		)


func _reveal(node: Control) -> Tween:
	node.visible = true
	node.modulate.a = 0.0
	node.scale = Vector2(0.95, 0.95)
	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.parallel().tween_property(node, "modulate:a", 1.0, 0.45)
	tw.parallel().tween_property(node, "scale", Vector2.ONE, 0.45)
	return tw


func _reveal_consumer_feature(feature_id: String, node: Control) -> bool:
	var tw: Tween = _reveal(node)
	if tw == null:
		return false

	match feature_id:
		"push_notifications":
			tw.finished.connect(func() -> void:
				var bell := _consumer_nodes.get("bell_label") as Label
				if bell:
					bell.pivot_offset = bell.size * 0.5
					var wiggle := create_tween()
					wiggle.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
					wiggle.tween_property(bell, "rotation_degrees", -16.0, 0.06)
					wiggle.tween_property(bell, "rotation_degrees", 14.0, 0.07)
					wiggle.tween_property(bell, "rotation_degrees", -10.0, 0.06)
					wiggle.tween_property(bell, "rotation_degrees", 8.0, 0.06)
					wiggle.tween_property(bell, "rotation_degrees", 0.0, 0.07)
					_track_consumer_tween(wiggle)
				_start_idle_animation(feature_id, node)
			)
			return true

		"profile_pages":
			tw.finished.connect(func() -> void:
				var pulse := create_tween()
				pulse.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				pulse.tween_property(node, "scale", Vector2(1.08, 1.08), 0.12)
				pulse.tween_property(node, "scale", Vector2.ONE, 0.14)
				_track_consumer_tween(pulse)
				_start_idle_animation(feature_id, node)
			)
			return true

		"social_feed":
			tw.finished.connect(func() -> void:
				var cards: Array = _consumer_nodes.get("feed_cards", [])
				for i in range(cards.size()):
					var card := cards[i] as Control
					if card == null:
						continue
					card.modulate.a = 0.0
					card.scale = Vector2(0.96, 0.96)
					var st := create_tween()
					st.tween_interval(float(i) * 0.07)
					st.parallel().tween_property(card, "modulate:a", 1.0, 0.24)
					st.parallel().tween_property(card, "scale", Vector2.ONE, 0.24)
					_track_consumer_tween(st)
					# Ken Burns starts after each card finishes its own reveal.
					var captured := card
					st.finished.connect(func() -> void: _start_ken_burns(captured))
				_start_idle_animation(feature_id, node)
			)
			return true

		"stories":
			tw.finished.connect(func() -> void:
				var bubbles: Array = _consumer_nodes.get("stories_bubbles", [])
				for i in range(bubbles.size()):
					var b := bubbles[i] as Control
					if b == null:
						continue
					b.scale = Vector2(0.7, 0.7)
					b.modulate.a = 0.0
					var st := create_tween()
					st.tween_interval(float(i) * 0.05)
					st.parallel().tween_property(b, "modulate:a", 1.0, 0.20)
					st.parallel().tween_property(b, "scale", Vector2.ONE, 0.20)
					_track_consumer_tween(st)
					# After reveal: a gentle phase-offset scale breathe per bubble.
					var bubble_size := b.custom_minimum_size
					var phase_delay: float = 0.25 + float(i) * 0.5
					var captured := b
					get_tree().create_timer(phase_delay).timeout.connect(func() -> void:
						if not is_instance_valid(captured):
							return
						captured.pivot_offset = bubble_size * 0.5
						var pulse := create_tween()
						pulse.set_loops()
						pulse.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
						pulse.tween_property(captured, "scale", Vector2(1.10, 1.10), 1.3)
						pulse.tween_property(captured, "scale", Vector2.ONE, 1.3)
						_ken_burns_tweens.append(pulse)
					)
				_start_idle_animation(feature_id, node)
			)
			return true

		"recommendations":
			tw.finished.connect(func() -> void:
				var cards: Array = _consumer_nodes.get("recommendation_cards", [])
				for i in range(cards.size()):
					var card := cards[i] as Control
					if card == null:
						continue
					card.modulate.a = 0.0
					var st := create_tween()
					st.tween_interval(float(i) * 0.06)
					st.tween_property(card, "modulate:a", 1.0, 0.28)
					_track_consumer_tween(st)
					# Ken Burns with a random-feel phase offset per card.
					var captured := card
					var kb_delay: float = 0.30 + float(i) * 0.08
					get_tree().create_timer(kb_delay).timeout.connect(func() -> void:
						if is_instance_valid(captured):
							_start_ken_burns(captured)
					)
				_start_idle_animation(feature_id, node)
			)
			return true

		"dark_mode":
			tw.finished.connect(func() -> void:
				var overlay := _consumer_nodes.get("dark_overlay") as ColorRect
				if overlay:
					overlay.visible = true
					var dtw := create_tween()
					dtw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
					dtw.tween_property(overlay, "color:a", 0.42, 0.45)
					_track_consumer_tween(dtw)
				_start_idle_animation(feature_id, node)
			)
			return true

		"iap":
			node.scale = Vector2(1.0, 0.72)
			tw.finished.connect(func() -> void:
				var bounce := create_tween()
				bounce.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				bounce.tween_property(node, "scale", Vector2(1.0, 1.08), 0.14)
				bounce.tween_property(node, "scale", Vector2.ONE, 0.16)
				_track_consumer_tween(bounce)
				_start_idle_animation(feature_id, node)
			)
			return true

		"sharing", "offline_mode":
			tw.finished.connect(func() -> void:
				var hop := create_tween()
				hop.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				hop.tween_property(node, "scale", Vector2(1.12, 1.12), 0.11)
				hop.tween_property(node, "scale", Vector2.ONE, 0.13)
				_track_consumer_tween(hop)
				_start_idle_animation(feature_id, node)
			)
			return true

		"live_chat":
			tw.finished.connect(func() -> void:
				var bob := create_tween()
				bob.set_loops()
				bob.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
				bob.tween_property(node, "scale", Vector2(1.04, 1.04), 0.9)
				bob.tween_property(node, "scale", Vector2.ONE, 0.9)
				_track_consumer_tween(bob)
				_start_idle_animation(feature_id, node)
			)
			return true

		_:
			tw.finished.connect(func() -> void:
				_start_idle_animation(feature_id, node)
			)
			return true


func _pretty_feature_name(feature_id: String) -> String:
	var parts := feature_id.split("_")
	for i in range(parts.size()):
		var p: String = parts[i]
		if p.is_empty():
			continue
		parts[i] = p.substr(0, 1).to_upper() + p.substr(1)
	return " ".join(parts)


func _update_consumer_build_meter(feature_id: String, progress_01: float) -> void:
	if _company_type != CompanyData.CompanyType.CONSUMER:
		return

	var panel := _consumer_nodes.get("build_meter_panel") as Control
	var bar := _consumer_nodes.get("build_meter_bar") as ProgressBar
	var label := _consumer_nodes.get("build_meter_label") as Label
	if panel == null or bar == null or label == null:
		return

	if feature_id.is_empty():
		panel.visible = false
		if _idle_tweens.has("__consumer_build_meter"):
			var tw := _idle_tweens["__consumer_build_meter"] as Tween
			if tw:
				tw.kill()
			_idle_tweens.erase("__consumer_build_meter")
		return

	panel.visible = true
	label.text = "Building %s..." % _pretty_feature_name(feature_id)
	bar.value = clampf(progress_01, 0.0, 1.0)

	if not _idle_tweens.has("__consumer_build_meter"):
		var tw := create_tween()
		tw.set_loops()
		tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(panel, "modulate:a", 0.72, 0.55)
		tw.tween_property(panel, "modulate:a", 1.0, 0.55)
		_idle_tweens["__consumer_build_meter"] = tw


func _start_idle_animation(feature_id: String, node: Control) -> void:
	if node == null or not FEATURE_IDLE_STYLES.has(feature_id):
		return
	if _idle_tweens.has(feature_id):
		return

	node.modulate.a = 1.0
	node.scale = Vector2.ONE

	var style: String = FEATURE_IDLE_STYLES.get(feature_id, "")
	var tw := create_tween()
	tw.set_loops()
	tw.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	match style:
		"ping":
			tw.tween_property(node, "modulate:a", 0.58, 0.22)
			tw.tween_property(node, "modulate:a", 1.0, 0.22)
			tw.tween_interval(1.0)
		"scan":
			tw.tween_property(node, "modulate:a", 0.68, 0.45)
			tw.tween_property(node, "modulate:a", 0.92, 0.45)
			tw.tween_property(node, "modulate:a", 1.0, 0.30)
			tw.tween_interval(0.55)
		_:
			# breathe
			tw.tween_property(node, "modulate:a", 0.76, 0.95)
			tw.tween_property(node, "modulate:a", 1.0, 0.95)

	_idle_tweens[feature_id] = tw


func _set_preview_state(node: Control, progress_01: float) -> void:
	var p := clampf(progress_01, 0.0, 1.0)
	node.modulate.a = lerpf(0.22, 0.78, p)
	var s := lerpf(0.95, 0.99, p)
	node.scale = Vector2(s, s)


func _start_preview_animation(node: Control, progress_01: float) -> void:
	_clear_preview_animation()
	if node == null:
		return

	var p := clampf(progress_01, 0.0, 1.0)
	var low_a: float = lerpf(0.24, 0.70, p)
	var high_a: float = minf(0.92, low_a + 0.18)

	_preview_tween = create_tween()
	_preview_tween.set_loops()
	_preview_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_preview_tween.tween_property(node, "modulate:a", high_a, 0.55)
	_preview_tween.tween_property(node, "modulate:a", low_a, 0.55)


func _gate(feature_id: String, node: Control) -> void:
	_feature_map[feature_id] = node
	node.visible = false


func _hide_on_reveal(placeholder: Control, trigger: Control) -> void:
	trigger.visibility_changed.connect(func() -> void:
		if trigger.visible:
			placeholder.visible = false
	)


func _sfb(bg: Color, corner: int = 5, pad: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(corner)
	if pad > 0:
		s.set_content_margin_all(pad)
	return s


func _lbl(text: String, sz: int = 9, col: Color = Color(0.70, 0.72, 0.82)) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	return l


func _pill(bg: Color, w: float = 0, h: float = 0, corner: int = 5) -> PanelContainer:
	var p := PanelContainer.new()
	if w > 0 or h > 0:
		p.custom_minimum_size = Vector2(w, h)
	p.add_theme_stylebox_override("panel", _sfb(bg, corner))
	return p


func _hbox(sep: int = 5) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h


func _vbox(sep: int = 4) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v


func _spacer_h() -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return c


func _mg(child: Control, l := 8, r := 8, t := 6, b := 6) -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", l)
	m.add_theme_constant_override("margin_right", r)
	m.add_theme_constant_override("margin_top", t)
	m.add_theme_constant_override("margin_bottom", b)
	m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m.add_child(child)
	return m


func _card(col: Color, h: float = 46, r: int = 4) -> PanelContainer:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(0, h)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_theme_stylebox_override("panel", _sfb(col, r))
	return p


func _placeholder(msg: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	p.add_theme_stylebox_override("panel", _sfb(Color(0.09, 0.10, 0.15), 5, 12))
	var l := _lbl(msg, 9, Color(0.28, 0.30, 0.36))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.size_flags_vertical = Control.SIZE_EXPAND_FILL
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p.add_child(l)
	return p


func _company_name() -> String:
	return GameState.company.company_name if GameState.company else "Your Co"


# ─────────────────────────────────────────────────────────────────────────────
# Texture-backed UI helpers
# ─────────────────────────────────────────────────────────────────────────────

const _ASSET_BASE := "res://assets/illustrations/"


func _load_tex(filename: String) -> Texture2D:
	var path := _ASSET_BASE + filename
	if ResourceLoader.exists(path):
		return ResourceLoader.load(path) as Texture2D
	return null


## Card filled with an image texture (falls back to solid color if asset missing).
func _img_card(filename: String, h: float = 46, r: int = 4) -> Control:
	var tex := _load_tex(filename)
	if tex == null:
		return _card(Color(0.18, 0.18, 0.24), h, r)
	var clip := PanelContainer.new()
	clip.custom_minimum_size = Vector2(0, h)
	clip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clip.clip_contents = true
	clip.add_theme_stylebox_override("panel", _sfb(Color(0, 0, 0, 0), r))
	var tr := TextureRect.new()
	tr.texture = tex
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clip.add_child(tr)
	return clip


## Circular bubble filled with an image (falls back to solid color).
func _img_bubble(filename: String, size: float = 16) -> Control:
	var tex := _load_tex(filename)
	if tex == null:
		return _pill(Color(0.35, 0.35, 0.48), size, size, int(size / 2.0))
	var clip := PanelContainer.new()
	clip.custom_minimum_size = Vector2(size, size)
	clip.clip_contents = true
	clip.add_theme_stylebox_override("panel", _sfb(Color(0, 0, 0, 0), int(size / 2.0)))
	var tr := TextureRect.new()
	tr.texture = tex
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clip.add_child(tr)
	return clip


## Small rounded icon from an image (falls back to a coloured pill).
func _img_icon(filename: String, size: float, corner: int,
		fallback_col: Color = Color(0.82, 0.12, 0.12)) -> Control:
	var tex := _load_tex(filename)
	if tex == null:
		return _pill(fallback_col, size, size, corner)
	var clip := PanelContainer.new()
	clip.custom_minimum_size = Vector2(size, size)
	clip.clip_contents = true
	clip.add_theme_stylebox_override("panel", _sfb(Color(0, 0, 0, 0), corner))
	var tr := TextureRect.new()
	tr.texture = tex
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clip.add_child(tr)
	return clip


# ─────────────────────────────────────────────────────────────────────────────
# Consumer App  (Streaming / Social)
# ─────────────────────────────────────────────────────────────────────────────

func _build_consumer() -> void:
	var root := _vbox(0)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(root)
	_consumer_nodes["root"] = root

	# Full-surface tint used by Dark Mode unlock animation.
	var dark_overlay := ColorRect.new()
	dark_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dark_overlay.color = Color(0.03, 0.04, 0.09, 0.0)
	dark_overlay.visible = false
	dark_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dark_overlay.z_index = 30
	add_child(dark_overlay)
	_consumer_nodes["dark_overlay"] = dark_overlay

	# ── Header bar ──────────────────────────────────────────────────────────
	var hdr_p := _pill(Color(0.08, 0.09, 0.15))
	hdr_p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(hdr_p)

	var hdr_row := _hbox(7)
	hdr_p.add_child(_mg(hdr_row, 10, 10, 7, 7))

	# Brand badge icon (uses generated asset, falls back to red pill)
	var icon_p := _img_icon("consumer_brand_badge.png", 22, 9)
	hdr_row.add_child(icon_p)

	hdr_row.add_child(_lbl(_company_name().to_upper(), 9, Color(0.95, 0.95, 1.0)))

	# Dark mode chip — feature-gated
	var dm_chip := _pill(Color(0.18, 0.18, 0.25), 0, 14, 7)
	dm_chip.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var dm_lbl := _lbl("  Dark  ", 7, Color(0.55, 0.55, 0.65))
	dm_chip.add_child(dm_lbl)
	_gate("dark_mode", dm_chip)
	hdr_row.add_child(dm_chip)

	hdr_row.add_child(_spacer_h())

	# Bell + dot — push_notifications
	var bell_wrap := _hbox(2)
	var bell := _lbl("🔔", 11)
	var dot := _pill(Color(0.95, 0.28, 0.25), 6, 6, 3)
	bell_wrap.add_child(bell)
	bell_wrap.add_child(dot)
	_gate("push_notifications", bell_wrap)
	hdr_row.add_child(bell_wrap)
	_consumer_nodes["bell_label"] = bell

	# Profile avatar — profile_pages (real image asset)
	var avatar_p := _img_bubble("consumer_profile_avatar.png", 22)
	_gate("profile_pages", avatar_p)
	hdr_row.add_child(avatar_p)

	# ── Premium banner — iap ─────────────────────────────────────────────────
	var prem_p := _pill(Color(0.50, 0.33, 0.04))
	prem_p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var prem_l := _lbl("★  PREMIUM — Unlock exclusive content", 8, Color(1.0, 0.86, 0.45))
	prem_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prem_p.add_child(prem_l)
	_gate("iap", prem_p)
	root.add_child(prem_p)

	# ── Content area ─────────────────────────────────────────────────────────
	var content_v := _vbox(6)
	content_v.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_mg(content_v, 8, 8, 7, 7))

	# Build meter shown while a feature is in-progress.
	var build_meter_panel := _pill(Color(0.11, 0.14, 0.22), 0, 18, 5)
	build_meter_panel.visible = false
	build_meter_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_v.add_child(build_meter_panel)
	var meter_row := _hbox(8)
	build_meter_panel.add_child(_mg(meter_row, 8, 8, 2, 2))
	var meter_label := _lbl("Building...", 8, Color(0.66, 0.80, 1.0))
	meter_row.add_child(meter_label)
	var meter_bar := ProgressBar.new()
	meter_bar.min_value = 0.0
	meter_bar.max_value = 1.0
	meter_bar.value = 0.0
	meter_bar.show_percentage = false
	meter_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meter_bar.custom_minimum_size = Vector2(0, 12)
	meter_row.add_child(meter_bar)
	_consumer_nodes["build_meter_panel"] = build_meter_panel
	_consumer_nodes["build_meter_label"] = meter_label
	_consumer_nodes["build_meter_bar"] = meter_bar

	# Recommendations row — feature-gated
	var recs_v := _vbox(3)
	_gate("recommendations", recs_v)
	content_v.add_child(recs_v)
	recs_v.add_child(_lbl("For You", 9, Color(0.45, 0.76, 1.0)))
	var recs_row := _hbox(5)
	recs_v.add_child(recs_row)
	var rec_cards: Array[Control] = []
	for img_file: String in ["consumer_rec_1.png", "consumer_rec_2.png", "consumer_rec_3.png"]:
		var c := _img_card(img_file, 38, 4)
		recs_row.add_child(c)
		rec_cards.append(c)
	_consumer_nodes["recommendation_cards"] = rec_cards

	# Main section — placeholder until social_feed ships
	var main_v := _vbox(3)
	main_v.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_v.add_child(main_v)

	var ph := _placeholder("Ship features\nto bring your app to life!")
	main_v.add_child(ph)

	# Social feed cards — feature-gated
	var feed_v := _vbox(3)
	_gate("social_feed", feed_v)
	main_v.add_child(feed_v)
	_hide_on_reveal(ph, feed_v)

	feed_v.add_child(_lbl("Trending Now", 9, Color(0.70, 0.72, 0.80)))

	# Stories row — stories
	var stories_row := _hbox(5)
	_gate("stories", stories_row)
	feed_v.add_child(stories_row)
	var story_bubbles: Array[Control] = []
	for img_file: String in ["consumer_story_1.png", "consumer_story_2.png", "consumer_story_3.png", "consumer_story_4.png"]:
		var bubble := _img_bubble(img_file, 20)
		stories_row.add_child(bubble)
		story_bubbles.append(bubble)
	_consumer_nodes["stories_bubbles"] = story_bubbles

	var feed_row := _hbox(5)
	feed_v.add_child(feed_row)
	var feed_cards: Array[Control] = []
	for img_file: String in ["consumer_thumb_1.png", "consumer_thumb_2.png", "consumer_thumb_3.png"]:
		var card := _img_card(img_file, 52, 4)
		feed_row.add_child(card)
		feed_cards.append(card)
	_consumer_nodes["feed_cards"] = feed_cards

	# Action icons row (child features of social_feed era)
	var act_row := _hbox(10)
	feed_v.add_child(act_row)

	var share_l := _lbl("↗  Share", 8, Color(0.45, 0.70, 0.95))
	_gate("sharing", share_l)
	act_row.add_child(share_l)

	var dl_l := _lbl("↓  Download", 8, Color(0.40, 0.80, 0.55))
	_gate("offline_mode", dl_l)
	act_row.add_child(dl_l)

	# Chat FAB — live_chat
	var chat_row := _hbox(0)
	chat_row.alignment = BoxContainer.ALIGNMENT_END
	content_v.add_child(chat_row)

	var chat_fab := _pill(Color(0.15, 0.50, 0.92), 0, 20, 10)
	chat_fab.size_flags_horizontal = Control.SIZE_SHRINK_END
	var chat_l := _lbl("  Chat  ", 8, Color(1, 1, 1))
	chat_fab.add_child(chat_l)
	_gate("live_chat", chat_fab)
	chat_row.add_child(chat_fab)


# ─────────────────────────────────────────────────────────────────────────────
# SaaS B2B Dashboard
# ─────────────────────────────────────────────────────────────────────────────

func _build_saas() -> void:
	var root := _vbox(0)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(root)

	# ── Header ──────────────────────────────────────────────────────────────
	var hdr_p := _pill(Color(0.08, 0.10, 0.17))
	hdr_p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(hdr_p)

	var hdr_row := _hbox(8)
	hdr_p.add_child(_mg(hdr_row, 10, 10, 7, 7))

	var grid_p := _pill(Color(0.22, 0.50, 0.82), 18, 18, 4)
	var grid_l := _lbl("▦", 9, Color(1, 1, 1))
	grid_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	grid_p.add_child(grid_l)
	hdr_row.add_child(grid_p)

	hdr_row.add_child(_lbl(_company_name(), 9, Color(0.92, 0.92, 1.0)))
	hdr_row.add_child(_lbl("Dashboard", 8, Color(0.40, 0.52, 0.70)))
	hdr_row.add_child(_spacer_h())

	# SSO badge — sso_login
	var sso_p := _pill(Color(0.14, 0.34, 0.16), 0, 14, 7)
	sso_p.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	sso_p.add_child(_mg(_lbl("SSO", 7, Color(0.45, 0.85, 0.48)), 6, 6, 1, 1))
	_gate("sso_login", sso_p)
	hdr_row.add_child(sso_p)

	# ── Tab row ─────────────────────────────────────────────────────────────
	var tab_row := _hbox(4)
	root.add_child(_mg(tab_row, 8, 8, 4, 2))

	# Active tab (always visible)
	var active_tab := _pill(Color(0.18, 0.28, 0.48), 0, 18, 4)
	active_tab.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	active_tab.add_child(_mg(_lbl("Dashboard", 8, Color(0.55, 0.75, 1.0)), 8, 8, 2, 2))
	tab_row.add_child(active_tab)

	for info: Array in [
		["billing",        "Billing",  Color(0.52, 0.55, 0.65)],
		["api_v2",         "API v2",   Color(0.52, 0.55, 0.65)],
		["admin_panel",    "Admin",    Color(0.52, 0.55, 0.65)],
		["custom_reports", "Reports",  Color(0.52, 0.55, 0.65)],
	]:
		var tp := _pill(Color(0.12, 0.13, 0.20), 0, 18, 4)
		tp.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		tp.add_child(_mg(_lbl(info[1], 8, info[2]), 8, 8, 2, 2))
		_gate(info[0], tp)
		tab_row.add_child(tp)

	# ── Content ──────────────────────────────────────────────────────────────
	var content_v := _vbox(7)
	content_v.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_mg(content_v, 8, 8, 6, 8))

	var ph := _placeholder("Ship features to\npopulate your dashboard")
	ph.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_v.add_child(ph)

	# Metric cards — user_dashboard
	var metrics_row := _hbox(6)
	_gate("user_dashboard", metrics_row)
	content_v.add_child(metrics_row)
	_hide_on_reveal(ph, metrics_row)

	for info: Array in [
		["Users",    Color(0.14, 0.24, 0.44), Color(0.45, 0.70, 1.0)],
		["Revenue",  Color(0.10, 0.25, 0.15), Color(0.38, 0.82, 0.48)],
		["Churn",    Color(0.28, 0.12, 0.12), Color(0.88, 0.40, 0.40)],
	]:
		var mc := _pill(info[1], 0, 36, 5)
		mc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var ml := _lbl(info[0], 8, info[2])
		ml.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ml.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		mc.add_child(ml)
		metrics_row.add_child(mc)

	# Mini bar chart — analytics
	var chart_v := _vbox(3)
	_gate("analytics", chart_v)
	content_v.add_child(chart_v)
	chart_v.add_child(_lbl("Revenue Trend", 8, Color(0.50, 0.53, 0.65)))

	var bars_row := _hbox(3)
	chart_v.add_child(bars_row)
	for bh: int in [16, 22, 18, 30, 26, 35, 38]:
		var bar := PanelContainer.new()
		bar.custom_minimum_size = Vector2(0, bh)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.size_flags_vertical = Control.SIZE_SHRINK_END
		bar.add_theme_stylebox_override("panel", _sfb(Color(0.20, 0.45, 0.82), 2))
		bars_row.add_child(bar)

	# Integration icons — integrations
	var integrations_v := _vbox(3)
	_gate("integrations", integrations_v)
	content_v.add_child(integrations_v)
	integrations_v.add_child(_lbl("Integrations", 8, Color(0.50, 0.53, 0.65)))

	var int_row := _hbox(6)
	integrations_v.add_child(int_row)
	for ic: Color in [Color(0.25, 0.10, 0.50), Color(0.10, 0.26, 0.52), Color(0.06, 0.38, 0.28), Color(0.46, 0.24, 0.06)]:
		var ip := _pill(ic, 24, 20, 5)
		int_row.add_child(ip)

	# Multi-tenancy status row — multi_tenancy
	var tenant_row := _hbox(6)
	_gate("multi_tenancy", tenant_row)
	content_v.add_child(tenant_row)
	tenant_row.add_child(_lbl("Tenant Isolation", 8, Color(0.52, 0.55, 0.65)))
	for tcol: Color in [Color(0.18, 0.45, 0.85), Color(0.18, 0.68, 0.45), Color(0.72, 0.52, 0.20)]:
		var tenant := _pill(tcol.darkened(0.35), 0, 14, 4)
		tenant.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		tenant.add_child(_mg(_lbl("Isolated", 7, tcol), 4, 4, 1, 1))
		tenant_row.add_child(tenant)

	# Audit log strip — audit_log
	var audit_v := _vbox(2)
	_gate("audit_log", audit_v)
	content_v.add_child(audit_v)
	audit_v.add_child(_lbl("Audit Log", 8, Color(0.50, 0.53, 0.65)))
	for entry: String in ["user.login  •  just now", "billing.update  •  2 min ago"]:
		audit_v.add_child(_lbl(entry, 8, Color(0.38, 0.40, 0.50)))


# ─────────────────────────────────────────────────────────────────────────────
# Marketplace / Storefront
# ─────────────────────────────────────────────────────────────────────────────

func _build_marketplace() -> void:
	var root := _vbox(0)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(root)

	# ── Header with search ───────────────────────────────────────────────────
	var hdr_p := _pill(Color(0.08, 0.10, 0.17))
	hdr_p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(hdr_p)

	var hdr_row := _hbox(8)
	hdr_p.add_child(_mg(hdr_row, 10, 10, 7, 7))

	var logo_p := _pill(Color(0.16, 0.50, 0.32), 18, 18, 9)
	var logo_l := _lbl("M", 10, Color(1, 1, 1))
	logo_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo_p.add_child(logo_l)
	hdr_row.add_child(logo_p)

	var search_p := _pill(Color(0.12, 0.14, 0.21), 0, 20, 10)
	search_p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search_p.add_child(_lbl("  Search products...", 8, Color(0.32, 0.34, 0.42)))
	hdr_row.add_child(search_p)

	var cart_l := _lbl("🛒", 12)
	_gate("payment_escrow", cart_l)
	hdr_row.add_child(cart_l)

	# ── Category tabs — categories ───────────────────────────────────────────
	var cats_row := _hbox(4)
	_gate("categories", cats_row)
	root.add_child(_mg(cats_row, 8, 8, 5, 2))

	for cat: String in ["All", "Featured", "New", "Sale"]:
		var ct := _pill(Color(0.13, 0.16, 0.24), 0, 18, 9)
		ct.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		ct.add_child(_mg(_lbl(cat, 8, Color(0.48, 0.72, 0.48)), 6, 6, 2, 2))
		cats_row.add_child(ct)

	# ── Filter chips — search_filters ────────────────────────────────────────
	var filters_row := _hbox(5)
	_gate("search_filters", filters_row)
	root.add_child(_mg(filters_row, 8, 8, 2, 2))

	for f: String in ["Price ▾", "Rating ▾", "Sort ▾"]:
		var fp := _pill(Color(0.13, 0.14, 0.22), 0, 16, 8)
		fp.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		fp.add_child(_mg(_lbl(f, 7, Color(0.58, 0.60, 0.70)), 6, 6, 1, 1))
		filters_row.add_child(fp)

	# ── Product grid ─────────────────────────────────────────────────────────
	var content_v := _vbox(5)
	content_v.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_mg(content_v, 8, 8, 5, 8))

	var ph := _placeholder("Add Seller Onboarding to\nstart filling your marketplace!")
	ph.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_v.add_child(ph)

	# Product cards — seller_onboarding
	var grid_row := _hbox(6)
	_gate("seller_onboarding", grid_row)
	content_v.add_child(grid_row)
	_hide_on_reveal(ph, grid_row)

	for cd: Array in [
		[Color(0.22, 0.17, 0.10), Color(0.88, 0.64, 0.30), "Mug"],
		[Color(0.10, 0.16, 0.26), Color(0.45, 0.64, 0.92), "Lamp"],
		[Color(0.10, 0.22, 0.12), Color(0.40, 0.80, 0.44), "Tote"],
	]:
		var cv := _vbox(2)
		cv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cv.add_child(_card(cd[0], 46))
		cv.add_child(_lbl(cd[2], 8, cd[1]))
		grid_row.add_child(cv)

	# Ratings section — ratings
	var ratings_row := _hbox(5)
	_gate("ratings", ratings_row)
	content_v.add_child(ratings_row)
	ratings_row.add_child(_lbl("★★★★☆", 10, Color(0.92, 0.75, 0.18)))
	ratings_row.add_child(_lbl("4.8  ·  Reviews & Trust", 8, Color(0.60, 0.62, 0.70)))

	# Delivery tracking — delivery_tracking
	var tracking_v := _vbox(2)
	_gate("delivery_tracking", tracking_v)
	content_v.add_child(tracking_v)
	tracking_v.add_child(_lbl("Live Delivery Tracking", 8, Color(0.50, 0.53, 0.65)))
	for step: String in ["Packed  ✓", "In Transit  •", "Out for Delivery  •"]:
		tracking_v.add_child(_lbl(step, 8, Color(0.44, 0.76, 0.96)))

	# Dispute center — disputes
	var disputes_row := _hbox(6)
	_gate("disputes", disputes_row)
	content_v.add_child(disputes_row)
	var case_badge := _pill(Color(0.42, 0.24, 0.08), 0, 16, 4)
	case_badge.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	case_badge.add_child(_mg(_lbl("Case #1293", 7, Color(0.96, 0.70, 0.32)), 5, 5, 1, 1))
	disputes_row.add_child(case_badge)
	disputes_row.add_child(_lbl("Dispute center online", 8, Color(0.60, 0.62, 0.70)))

	# Promoted listings — promoted_listings
	var promo_row := _hbox(6)
	_gate("promoted_listings", promo_row)
	content_v.add_child(promo_row)

	var promo_badge := _pill(Color(0.72, 0.28, 0.05), 0, 16, 4)
	promo_badge.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	promo_badge.add_child(_mg(_lbl("Sponsored", 7, Color(1.0, 0.84, 0.55)), 5, 5, 1, 1))
	promo_row.add_child(promo_badge)
	promo_row.add_child(_lbl("Promoted listings active", 8, Color(0.58, 0.60, 0.70)))

	# Referral banner — referral_program
	var ref_p := _pill(Color(0.12, 0.25, 0.14), 0, 20, 5)
	ref_p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ref_p.add_child(_mg(
		_lbl("★  Refer a friend — earn rewards!", 8, Color(0.50, 0.90, 0.52)),
		8, 8, 3, 3
	))
	_gate("referral_program", ref_p)
	content_v.add_child(ref_p)

	# Seller analytics tab chip — seller_analytics
	var sa_chip := _hbox(5)
	_gate("seller_analytics", sa_chip)
	content_v.add_child(sa_chip)
	var sa_p := _pill(Color(0.14, 0.22, 0.14), 0, 16, 4)
	sa_p.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	sa_p.add_child(_mg(_lbl("Seller Hub", 8, Color(0.45, 0.82, 0.48)), 6, 6, 1, 1))
	sa_chip.add_child(sa_p)
	sa_chip.add_child(_lbl("Analytics now available", 8, Color(0.58, 0.60, 0.70)))


# ─────────────────────────────────────────────────────────────────────────────
# Dev Tools / API Console
# ─────────────────────────────────────────────────────────────────────────────

func _build_dev_tools() -> void:
	var root := _vbox(0)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(root)

	# ── Window chrome (terminal title bar) ───────────────────────────────────
	var chrome_p := _pill(Color(0.13, 0.14, 0.20))
	chrome_p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(chrome_p)

	var chrome_row := _hbox(5)
	chrome_p.add_child(_mg(chrome_row, 10, 10, 7, 7))

	# Traffic light dots
	for dot_col: Color in [Color(0.90, 0.30, 0.30), Color(0.90, 0.70, 0.20), Color(0.26, 0.80, 0.30)]:
		var dot := _pill(dot_col, 10, 10, 5)
		chrome_row.add_child(dot)

	chrome_row.add_child(_spacer_h())
	chrome_row.add_child(_lbl(_company_name() + " API Console", 9, Color(0.62, 0.65, 0.75)))
	chrome_row.add_child(_spacer_h())

	# Sandbox badge — sandbox
	var sb_p := _pill(Color(0.12, 0.36, 0.20), 0, 14, 7)
	sb_p.size_flags_horizontal = Control.SIZE_SHRINK_END
	sb_p.add_child(_mg(_lbl("SANDBOX", 7, Color(0.40, 0.88, 0.52)), 5, 5, 1, 1))
	_gate("sandbox", sb_p)
	chrome_row.add_child(sb_p)

	# ── Terminal body ────────────────────────────────────────────────────────
	var term_p := PanelContainer.new()
	term_p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	term_p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	term_p.add_theme_stylebox_override("panel", _sfb(Color(0.055, 0.065, 0.095), 0))
	root.add_child(term_p)

	var term_v := _vbox(5)
	term_v.size_flags_vertical = Control.SIZE_EXPAND_FILL
	term_p.add_child(_mg(term_v, 10, 10, 8, 8))

	# Placeholder prompt
	var ph_lbl := _lbl("> Install SDK to get started...", 9, Color(0.28, 0.55, 0.35))
	term_v.add_child(ph_lbl)

	# CLI section — cli_tool
	var cli_v := _vbox(2)
	_gate("cli_tool", cli_v)
	term_v.add_child(cli_v)
	_hide_on_reveal(ph_lbl, cli_v)

	var slug := _company_name().to_lower().replace(" ", "-")
	cli_v.add_child(_lbl("$ " + slug + "-cli status", 9, Color(0.48, 0.88, 0.52)))
	cli_v.add_child(_lbl("  ✓ Connected  v2.1.0", 8, Color(0.32, 0.70, 0.42)))

	# SDK code block — sdk
	var sdk_p := _pill(Color(0.08, 0.10, 0.16), 0, 0, 4)
	sdk_p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_gate("sdk", sdk_p)
	term_v.add_child(sdk_p)

	var code_v := _vbox(1)
	sdk_p.add_child(_mg(code_v, 8, 8, 5, 5))
	var cname_slug := _company_name().replace(" ", "")
	code_v.add_child(_lbl("const client = new " + cname_slug + "Client(apiKey);", 8, Color(0.52, 0.70, 0.95)))
	code_v.add_child(_lbl("await client.events.list({ limit: 50 });", 8, Color(0.70, 0.52, 0.95)))

	# API docs panel — api_docs
	var docs_v := _vbox(3)
	_gate("api_docs", docs_v)
	term_v.add_child(docs_v)
	docs_v.add_child(_lbl("Endpoints", 8, Color(0.50, 0.53, 0.65)))

	for ep: Array in [
		["GET",    "/v1/events",  Color(0.32, 0.78, 0.44)],
		["POST",   "/v1/charges", Color(0.40, 0.60, 0.95)],
		["DELETE", "/v1/refunds", Color(0.88, 0.40, 0.40)],
	]:
		var ep_row := _hbox(6)
		docs_v.add_child(ep_row)
		var m_p := _pill(ep[2].darkened(0.45), 0, 14, 3)
		m_p.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		m_p.add_child(_mg(_lbl(ep[0], 7, ep[2]), 4, 4, 1, 1))
		ep_row.add_child(m_p)
		ep_row.add_child(_lbl(ep[1], 8, Color(0.60, 0.62, 0.70)))

	# Auth key row — auth_tokens
	var auth_row := _hbox(8)
	_gate("auth_tokens", auth_row)
	term_v.add_child(auth_row)
	auth_row.add_child(_lbl("API Key:", 8, Color(0.52, 0.55, 0.65)))
	var key_p := _pill(Color(0.10, 0.13, 0.20), 0, 16, 4)
	key_p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	key_p.add_child(_mg(_lbl("sk_live_••••••••••••••••", 8, Color(0.40, 0.72, 0.40)), 6, 6, 1, 1))
	auth_row.add_child(key_p)

	# Webhook event row — webhooks
	var wh_row := _hbox(6)
	_gate("webhooks", wh_row)
	term_v.add_child(wh_row)
	var wh_badge := _pill(Color(0.16, 0.40, 0.18), 0, 16, 4)
	wh_badge.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	wh_badge.add_child(_mg(_lbl("200 OK", 7, Color(0.40, 0.88, 0.40)), 4, 4, 1, 1))
	wh_row.add_child(wh_badge)
	wh_row.add_child(_lbl("POST /webhook  payment.succeeded", 8, Color(0.52, 0.55, 0.65)))

	# Rate limiting indicator — rate_limiting
	var rl_row := _hbox(6)
	_gate("rate_limiting", rl_row)
	term_v.add_child(rl_row)
	var rl_badge := _pill(Color(0.20, 0.28, 0.40), 0, 16, 4)
	rl_badge.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	rl_badge.add_child(_mg(_lbl("RPS 120/s", 7, Color(0.58, 0.76, 0.95)), 5, 5, 1, 1))
	rl_row.add_child(rl_badge)
	rl_row.add_child(_lbl("Adaptive rate limiting enabled", 8, Color(0.52, 0.55, 0.65)))

	# Usage bar chart — usage_dashboard
	var usage_v := _vbox(3)
	_gate("usage_dashboard", usage_v)
	term_v.add_child(usage_v)
	usage_v.add_child(_lbl("API Calls / month", 8, Color(0.50, 0.53, 0.65)))
	var usage_row := _hbox(3)
	usage_v.add_child(usage_row)
	for bh: int in [10, 16, 13, 20, 18, 26, 22, 28]:
		var bar := PanelContainer.new()
		bar.custom_minimum_size = Vector2(0, bh)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.size_flags_vertical = Control.SIZE_SHRINK_END
		bar.add_theme_stylebox_override("panel", _sfb(Color(0.20, 0.50, 0.32), 2))
		usage_row.add_child(bar)

	# Plugin system row — plugin_system
	var plugin_v := _vbox(3)
	_gate("plugin_system", plugin_v)
	term_v.add_child(plugin_v)
	plugin_v.add_child(_lbl("Plugin Marketplace", 8, Color(0.50, 0.53, 0.65)))
	var plugin_row := _hbox(5)
	plugin_v.add_child(plugin_row)
	for pc: Color in [Color(0.22, 0.14, 0.40), Color(0.10, 0.22, 0.40), Color(0.22, 0.14, 0.14)]:
		var pp := _pill(pc, 0, 18, 4)
		pp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		plugin_row.add_child(pp)

	# CI/CD status row — cicd_integration
	var cicd_row := _hbox(6)
	_gate("cicd_integration", cicd_row)
	term_v.add_child(cicd_row)
	var pass_badge := _pill(Color(0.16, 0.38, 0.20), 0, 16, 4)
	pass_badge.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	pass_badge.add_child(_mg(_lbl("Build Passing", 7, Color(0.42, 0.90, 0.50)), 5, 5, 1, 1))
	cicd_row.add_child(pass_badge)
	cicd_row.add_child(_lbl("GitHub Actions + Jenkins connected", 8, Color(0.52, 0.55, 0.65)))
