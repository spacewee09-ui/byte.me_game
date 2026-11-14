extends Control
## The meat-packing plant behind the action. Pure decoration, but it sells
## the theme and gives the level depth.

var _time := 0.0
var _cam := Vector2(640, 360)
var _dust: Array = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rng.seed = 987654321
	for i in 46:
		_dust.append(Vector3(_rng.randf() * 1600.0, _rng.randf() * 800.0, _rng.randf_range(0.3, 1.0)))


func _process(delta: float) -> void:
	_time += delta
	var cam := get_viewport().get_camera_2d()
	if cam != null:
		_cam = cam.get_screen_center_position()
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w <= 1.0:
		w = 1280.0
		h = 720.0

	# Cold, dark slaughterhouse gradient.
	for i in 16:
		var t := float(i) / 15.0
		draw_rect(Rect2(0, h * t, w, h / 15.0 + 1.0), Color("#2d1016").lerp(Color("#0b0406"), t))

	_draw_tanks(w, h)
	_draw_pipes(w, h)
	_draw_chains(w, h)
	_draw_dust(w, h)
	_draw_vignette(w, h)


func _offset(factor: float, period: float) -> float:
	return -fmod(_cam.x * factor, period)


func _draw_tanks(w: float, h: float) -> void:
	var period := 640.0
	var base := _offset(0.12, period)
	for i in 3:
		var x := base + i * period + 90.0
		draw_circle(Vector2(x, h * 0.42), 96.0, Color("#3a1820"))
		draw_circle(Vector2(x, h * 0.42), 96.0, Color("#000000", 0.0))
		draw_rect(Rect2(x - 96, h * 0.42, 192, h), Color("#3a1820"))
		draw_rect(Rect2(x - 96, h * 0.42, 192, h), Color("#000000", 0.0))
		# panel lines
		for j in 3:
			draw_line(Vector2(x - 96, h * 0.42 + 40 + j * 46), Vector2(x + 96, h * 0.42 + 40 + j * 46), Color(0, 0, 0, 0.25), 2.0)


func _draw_pipes(w: float, h: float) -> void:
	var period := 420.0
	var base := _offset(0.28, period)
	for i in 4:
		var x := base + i * period
		var y := 120.0 + fmod(i * 97.0, 220.0)
		draw_rect(Rect2(x, y, 210, 26), Color("#1c0a0f"))
		draw_rect(Rect2(x, y + 4, 210, 8), Color("#411c25"))
		draw_circle(Vector2(x, y + 13), 18.0, Color("#1c0a0f"))
		draw_circle(Vector2(x + 210, y + 13), 18.0, Color("#1c0a0f"))
		# a valve wheel
		draw_arc(Vector2(x + 105, y + 13), 15.0, 0.0, TAU, 16, Color("#4a2029"), 3.0)
		draw_line(Vector2(x + 105, y + 13), Vector2(x + 105 + 15, y + 13), Color("#4a2029"), 3.0)


func _draw_chains(w: float, h: float) -> void:
	var period := 260.0
	var base := _offset(0.45, period)
	for i in 8:
		var x := base + i * period
		var chain_len := 150.0 + fmod(i * 53.0, 140.0)
		for j in int(chain_len / 18.0):
			draw_circle(Vector2(x, 8.0 + j * 18.0), 4.0, Color("#1b0a0e"))
		# hook
		var hook_y := 8.0 + chain_len
		draw_arc(Vector2(x, hook_y + 12.0), 13.0, PI * 0.15, PI * 1.15, 12, Color("#1b0a0e"), 5.0)


func _draw_dust(w: float, h: float) -> void:
	for mote in _dust:
		var x: float = fmod(mote.x - _cam.x * 0.75, w + 120.0) - 60.0
		var y: float = fmod(mote.y - _time * 14.0 * mote.z + h * 4.0, h)
		var alpha: float = 0.05 + mote.z * 0.1
		draw_circle(Vector2(x, y), 1.2 + mote.z * 1.6, Color(1.0, 0.75, 0.65, alpha))


func _draw_vignette(w: float, h: float) -> void:
	draw_rect(Rect2(0, 0, w, 90), Color(0, 0, 0, 0.35))
	draw_rect(Rect2(0, h - 70, w, 70), Color(0, 0, 0, 0.4))
	draw_rect(Rect2(0, 0, 80, h), Color(0, 0, 0, 0.22))
	draw_rect(Rect2(w - 80, 0, 80, h), Color(0, 0, 0, 0.22))
