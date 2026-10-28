extends Node2D
class_name ProbabilityChart
var _freq_map: Dictionary = {}
var _max_val: int = 6
var _max_count: int = 1

const BAR_COLOR       = Color(1.0, 1.0, 1.0, 0.85)
const THEORY_COLOR    = Color(1.0, 1.0, 1.0, 0.9)
const GRID_COLOR      = Color(1, 1, 1, 0.08)
const TEXT_COLOR      = Color(0.9, 0.9, 0.9)
const BG_COLOR        = Color(0.246, 0.002, 0.002, 1.0)

@export var chart_width: float  = 420.0
@export var chart_height: float = 160.0
@export var padding: float      = 60.0


func update_chart(freq: Dictionary, max_value: int) -> void:
	_freq_map = freq
	_max_val = max(max_value, 1)
	_max_count = 1
	for v in freq.values():
		if v > _max_count:
			_max_count = v
	queue_redraw()


func _draw() -> void:
	var w = chart_width
	var h = chart_height
	var p = padding

	# Background
	draw_rect(Rect2(-p, -p, w + p * 2, h + p * 2), BG_COLOR, true, 0.0)

	# Grade horizontal
	for i in range(5):
		var y = h - (float(i) / 4.0) * h
		draw_line(Vector2(0, y), Vector2(w, y), GRID_COLOR, 1.0)
		var lbl = str(int((float(i) / 4.0) * _max_count))
		draw_string(ThemeDB.fallback_font, Vector2(-p + 2, y + 4), lbl,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 11, TEXT_COLOR)

	if _freq_map.is_empty():
		_draw_empty_hint(w, h)
		return

	var bar_w = w / float(_max_val)

	# Barras de frequência observada
	for val in range(1, _max_val + 1):
		var count = _freq_map.get(val, 0)
		var bar_h = (float(count) / float(_max_count)) * h if _max_count > 0 else 0
		var x = (val - 1) * bar_w
		var rect = Rect2(x + 2, h - bar_h, bar_w - 4, bar_h)
		draw_rect(rect, BAR_COLOR, true, 0.0)
		draw_rect(rect, BAR_COLOR.lightened(0.3), false, 1.5)

		# Rótulo do eixo X
		var lx = x + bar_w * 0.5
		draw_string(ThemeDB.fallback_font, Vector2(lx - 6, h + 16), str(val),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 11, TEXT_COLOR)

	# Linha de probabilidade teórica (uniforme)
	_draw_theory_line(w, h, bar_w)

	# Legenda
	draw_rect(Rect2(w - 130, -p + 4, 12, 12), BAR_COLOR, true)
	draw_string(ThemeDB.fallback_font, Vector2(w - 114, -p + 14),
		"Observado", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, TEXT_COLOR)
	draw_rect(Rect2(w - 130, -p + 20, 12, 3), THEORY_COLOR, true)
	draw_string(ThemeDB.fallback_font, Vector2(w - 114, -p + 30),
		"Teórico", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, TEXT_COLOR)


func _draw_theory_line(w: float, h: float, bar_w: float) -> void:
	# Frequência esperada = total_rolls / max_val
	var total = 0
	for v in _freq_map.values():
		total += v
	if total == 0:
		return
	var expected = float(total) / float(_max_val)
	var theory_h = (expected / float(_max_count)) * h if _max_count > 0 else 0
	var y = h - theory_h

	var pts: PackedVector2Array = []
	for val in range(1, _max_val + 1):
		var x = (val - 1) * bar_w + bar_w * 0.5
		pts.append(Vector2(x, y))

	for i in range(pts.size() - 1):
		draw_line(pts[i], pts[i + 1], THEORY_COLOR, 2.5)
	for pt in pts:
		draw_circle(pt, 4.0, THEORY_COLOR)


func _draw_empty_hint(w: float, h: float) -> void:
	draw_string(ThemeDB.fallback_font,
		Vector2(w * 0.5 - 80, h * 0.5),
		"Lance os dados para ver o gráfico!",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.6, 0.6, 0.6))
