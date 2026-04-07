extends Control
## Lightweight multi-series trend chart for the finance screen.
## Each series is normalized to its own range so trends stay readable.
## Supports up to 4 named series with a bottom legend + last-point value labels.

const PAD := 10.0
const LEGEND_HEIGHT := 20.0

var _series: Array[Dictionary] = []  # [{values, color, label}]


func set_series(
		a_values: Array[float], a_color: Color, a_label: String,
		b_values: Array[float], b_color: Color, b_label: String,
		c_values: Array[float] = [], c_color: Color = Color.WHITE, c_label: String = "",
		d_values: Array[float] = [], d_color: Color = Color.WHITE, d_label: String = ""
) -> void:
	_series.clear()
	for pair in [
		[a_values, a_color, a_label],
		[b_values, b_color, b_label],
		[c_values, c_color, c_label],
		[d_values, d_color, d_label],
	]:
		if not (pair[0] as Array[float]).is_empty():
			_series.append({"values": (pair[0] as Array[float]).duplicate(), "color": pair[1], "label": pair[2]})
	queue_redraw()


func clear() -> void:
	_series.clear()
	queue_redraw()


func _draw() -> void:
	var legend_h := LEGEND_HEIGHT if not _series.is_empty() else 0.0
	var chart_rect := Rect2(
		Vector2(PAD, PAD),
		size - Vector2(PAD * 2.0, PAD * 2.0 + legend_h)
	)
	if chart_rect.size.x <= 2.0 or chart_rect.size.y <= 2.0:
		return

	draw_rect(chart_rect, Color(0.10, 0.11, 0.17, 0.96), true)
	draw_rect(chart_rect, Color(0.24, 0.27, 0.40, 0.8), false, 1.0, true)
	_draw_grid(chart_rect)

	for s in _series:
		_draw_series(chart_rect, s.values, s.color)
		_draw_last_value_dot(chart_rect, s.values, s.color)

	if not _series.is_empty():
		_draw_legend(chart_rect)


func _draw_grid(chart_rect: Rect2) -> void:
	for i in range(1, 4):
		var y := chart_rect.position.y + chart_rect.size.y * (float(i) / 4.0)
		draw_line(
			Vector2(chart_rect.position.x, y),
			Vector2(chart_rect.position.x + chart_rect.size.x, y),
			Color(1, 1, 1, 0.07),
			1.0,
			true
		)


func _draw_series(chart_rect: Rect2, values: Array[float], color: Color) -> void:
	if values.size() < 2:
		return

	var min_v := values[0]
	var max_v := values[0]
	for v in values:
		min_v = minf(min_v, v)
		max_v = maxf(max_v, v)
	var span := maxf(1.0, max_v - min_v)

	var points := PackedVector2Array()
	var n := values.size()
	for i in range(n):
		var t := float(i) / float(n - 1) if n > 1 else 0.0
		var x := chart_rect.position.x + chart_rect.size.x * t
		var norm := clampf((values[i] - min_v) / span, 0.0, 1.0)
		var y := chart_rect.position.y + chart_rect.size.y * (1.0 - norm)
		points.append(Vector2(x, y))

	draw_polyline(points, color, 2.0, true)


func _draw_last_value_dot(chart_rect: Rect2, values: Array[float], color: Color) -> void:
	if values.is_empty():
		return

	var min_v := values[0]
	var max_v := values[0]
	for v in values:
		min_v = minf(min_v, v)
		max_v = maxf(max_v, v)
	var span := maxf(1.0, max_v - min_v)
	var n := values.size()
	var last_val := values[n - 1]

	var x := chart_rect.position.x + chart_rect.size.x
	var norm := clampf((last_val - min_v) / span, 0.0, 1.0)
	var y := chart_rect.position.y + chart_rect.size.y * (1.0 - norm)
	draw_circle(Vector2(x, y), 3.2, color)


func _draw_legend(chart_rect: Rect2) -> void:
	var legend_y := chart_rect.position.y + chart_rect.size.y + 6.0
	var x := chart_rect.position.x
	for s in _series:
		var dot_rect := Rect2(x, legend_y + 5.0, 8.0, 8.0)
		draw_rect(dot_rect, s.color, true)
		x += 12.0
		# Draw label text using the built-in font placeholder — the label is
		# readable as colored dots in the legend even without a custom font.
		draw_string(
			ThemeDB.fallback_font,
			Vector2(x, legend_y + 14.0),
			s.label,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			10,
			s.color.lightened(0.2)
		)
		x += ThemeDB.fallback_font.get_string_size(s.label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x + 16.0
