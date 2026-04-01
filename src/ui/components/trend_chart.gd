extends Control
## Lightweight multi-series trend chart for the finance screen.
## Each series is normalized to its own range so trends stay readable.

const PAD := 10.0

var _cash_series: Array[float] = []
var _revenue_series: Array[float] = []
var _users_series: Array[float] = []


func set_series(cash_series: Array[float], revenue_series: Array[float], users_series: Array[float]) -> void:
	_cash_series = cash_series.duplicate()
	_revenue_series = revenue_series.duplicate()
	_users_series = users_series.duplicate()
	queue_redraw()


func clear() -> void:
	_cash_series.clear()
	_revenue_series.clear()
	_users_series.clear()
	queue_redraw()


func _draw() -> void:
	var chart_rect := Rect2(Vector2(PAD, PAD), size - Vector2(PAD * 2.0, PAD * 2.0))
	if chart_rect.size.x <= 2.0 or chart_rect.size.y <= 2.0:
		return

	draw_rect(chart_rect, Color(0.10, 0.11, 0.17, 0.96), true)
	draw_rect(chart_rect, Color(0.24, 0.27, 0.40, 0.8), false, 1.0, true)
	_draw_grid(chart_rect)
	_draw_series(chart_rect, _cash_series, Color(0.33, 0.80, 0.52))
	_draw_series(chart_rect, _revenue_series, Color(0.37, 0.63, 0.95))
	_draw_series(chart_rect, _users_series, Color(0.96, 0.74, 0.31))


func _draw_grid(chart_rect: Rect2) -> void:
	for i in range(1, 4):
		var y := chart_rect.position.y + chart_rect.size.y * (float(i) / 4.0)
		draw_line(
			Vector2(chart_rect.position.x, y),
			Vector2(chart_rect.position.x + chart_rect.size.x, y),
			Color(1, 1, 1, 0.08),
			1.0,
			true
		)


func _draw_series(chart_rect: Rect2, series: Array[float], color: Color) -> void:
	if series.size() < 2:
		return

	var min_v := series[0]
	var max_v := series[0]
	for v in series:
		min_v = minf(min_v, v)
		max_v = maxf(max_v, v)
	var span := maxf(1.0, max_v - min_v)

	var points := PackedVector2Array()
	var n := series.size()
	for i in range(n):
		var t := 0.0
		if n > 1:
			t = float(i) / float(n - 1)
		var x := chart_rect.position.x + chart_rect.size.x * t
		var norm := clampf((series[i] - min_v) / span, 0.0, 1.0)
		var y := chart_rect.position.y + chart_rect.size.y * (1.0 - norm)
		points.append(Vector2(x, y))

	draw_polyline(points, color, 2.0, true)
	draw_circle(points[points.size() - 1], 2.4, color)
