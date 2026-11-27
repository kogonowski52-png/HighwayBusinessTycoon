extends Control

const PALE := Color("#e9dfbd")
const COLORS := [Color("#e8a45d"), Color("#62b8a8"), Color("#e07e72"),
	Color("#8eafd1"), Color("#c8b56f"), Color("#9babb9")]

var session: RefCounted
var preview := Vector2i(-1, -1)
var splash := Vector2(-200, -200)
var wave := 0.0

func _draw() -> void:
	if session == null:
		return
	match session.practice:
		"fuel": draw_pump()
		"wash":
			if wave > 0:
				draw_arc(splash, lerpf(39.0, 13.0, wave), 0, TAU, 30, Color(0.77,1,.95,wave), 4, true)
				for i in 5:
					var offset := Vector2.from_angle(i * TAU / 5.0 + .18) * lerpf(54.0, 21.0, wave)
					draw_circle(splash + offset, 3.5, Color(0.66,0.91,0.94,wave), true, -1, true)
		"cargo": draw_crates()

func draw_pump() -> void:
	var from := Vector2(33, size.y * .68)
	var to := Vector2(size.x - 33, from.y)
	var span := to.x - from.x
	draw_line(from, to, Color("#223c45"), 25, true)
	for i in 21:
		var tick := from + Vector2(i * span / 20.0, 0)
		draw_line(tick - Vector2(0, 1), tick - Vector2(0, 31 if i % 5 == 0 else 15), Color("#9c9b81"), 3, true)
	if session.attempts.size() < session.BANDS.size():
		var index: int = session.attempts.size()
		var center: float = session.BANDS[index]
		var band: float = session.WIDTHS[index]
		draw_line(from + Vector2(span * (center - band * .5), 0), from + Vector2(span * (center + band * .5), 0),
			Color("#7dc6a3"), 20, true)
	var needle := from + Vector2(span * session.needle(), 0)
	draw_line(needle - Vector2(0, 33), needle + Vector2(0, 21), Color("#ffd37c"), 12, true)
	draw_circle(needle - Vector2(0, 34), 9.0, PALE, true, -1, true)
	for i in 4:
		var point := Vector2(size.x * .5 - 51 + i * 35, 18)
		var value: float = session.attempts[i] if i < session.attempts.size() else 0.0
		draw_circle(point, 10.0, Color("#2d5158").lerp(Color("#eebe71"), value), true, -1, true)

func metric() -> float:
	return maxf(1.0, minf(size.x * .15, (size.y - 22) / 6.0))

func bed() -> Vector2:
	return Vector2((size.x - metric() * 4.0) * .5, 14.0)

func slot(at: Vector2) -> Vector2i:
	var state := (at - bed()) / metric()
	return Vector2i(floori(state.x), floori(state.y))

func draw_crates() -> void:
	var cell := metric()
	var origin := bed()
	var outline := Rect2(origin - Vector2(11, 10), Vector2(cell * 4 + 22, cell * 6 + 20))
	draw_rect(outline, Color("#947349"))
	draw_rect(outline.grow(-5), Color("#31464a"))
	for y in 6:
		for x in 4:
			var tile := Rect2(origin + Vector2(x, y) * cell + Vector2(2,2), Vector2.ONE * (cell - 4))
			draw_rect(tile, Color("#536b68") if y % 2 else Color("#637973"))
			var place := Vector2i(x,y)
			if session.loaded.has(place):
				draw_box(tile.grow(-1), COLORS[session.loaded[place]])
	if not session.piece().is_empty():
		var current: int = session.piece_count()
		var next_origin := Vector2(origin.x + 4.0 * cell + 32, 33)
		var step := minf(cell * .45, (size.x - next_origin.x) / 3.2)
		for part: Vector2i in session.piece():
			draw_box(Rect2(next_origin + Vector2(part) * step, Vector2.ONE * (step - 3)), COLORS[current])
		if preview.x >= 0 and preview.y >= 0 and preview.x < 4 and preview.y < 6:
			var tint := Color("#88bca0") if session.fits(preview) else Color("#e99575")
			for part: Vector2i in session.piece():
				var shown := part + preview
				if shown.x < 4 and shown.y < 6:
					draw_rect(Rect2(origin + Vector2(shown) * cell + Vector2(3,3), Vector2.ONE * (cell - 6)),
						Color(tint, .74), false, 5, true)

func draw_box(tile: Rect2, tint: Color) -> void:
	if tile.size.x <= 0.0:
		return
	draw_rect(tile, tint.darkened(.35))
	draw_rect(Rect2(tile.position, tile.size - Vector2(0, 7)), tint)
	draw_line(tile.position + Vector2(2,2), tile.position + Vector2(tile.size.x - 2, 2), tint.lightened(.31), 4, true)
	for pos in [.28, .72]:
		var x: float = tile.position.x + tile.size.x * pos
		draw_line(Vector2(x, tile.position.y + 3), Vector2(x, tile.end.y - 4), tint.darkened(.19), 3, true)
