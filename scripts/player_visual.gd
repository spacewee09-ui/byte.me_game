extends Node2D
## Draws the meat guy. Pure cosmetics: no physics here, just squish.
## Everything is drawn with primitive shapes so the game needs no art files.

const MEAT := Color("#e8514a")
const MEAT_DARK := Color("#a32b28")
const MEAT_LIGHT := Color("#ff9a7c")
const OUTLINE := Color("#3a0f0f")
const INK := Color("#20100f")

var facing := 1

var _squash := Vector2.ONE
var _time := 0.0
var _blink := 0.0
var _blink_timer := 2.5
var _wall_slide := 0.0
var _air_velocity := 0.0


func _process(delta: float) -> void:
	_time += delta
	_squash = _squash.lerp(Vector2.ONE, minf(1.0, delta * 14.0))
	_wall_slide = maxf(0.0, _wall_slide - delta * 4.0)

	_blink_timer -= delta
	if _blink_timer <= 0.0:
		_blink = 0.12
		_blink_timer = randf_range(2.0, 4.5)
	_blink = maxf(0.0, _blink - delta)

	# Stretch while flying through the air.
	var air := clampf(_air_velocity / 1600.0, -0.28, 0.28)
	scale = _squash * Vector2(1.0 - air * 0.5, 1.0 + air * 0.5)

	queue_redraw()


func squash(value: Vector2) -> void:
	_squash = value


func on_wall_slide() -> void:
	_wall_slide = 1.0


func set_air_velocity(vy: float) -> void:
	_air_velocity = vy


func reset() -> void:
	_squash = Vector2.ONE
	_air_velocity = 0.0
	show()


func _draw() -> void:
	var bob := sin(_time * 9.0) * 0.7
	var leg_swing := sin(_time * 15.0) * 2.2
	if _wall_slide > 0.0:
		leg_swing = 1.0

	# Little legs.
	draw_line(Vector2(-6, 9), Vector2(-6 + leg_swing, 16), OUTLINE, 3.0)
	draw_line(Vector2(6, 9), Vector2(6 - leg_swing, 16), OUTLINE, 3.0)

	# Body: a dark ring, then the meat, then a soft shadow at the bottom.
	draw_circle(Vector2(0, bob), 14.0, OUTLINE)
	draw_circle(Vector2(0, bob), 12.5, MEAT)
	draw_circle(Vector2(2.5, bob + 4.5), 8.6, Color(MEAT_DARK, 0.5))
	draw_circle(Vector2(-4.5, bob - 5.0), 4.0, Color(MEAT_LIGHT, 0.85))

	# Speckles and a shine.
	draw_circle(Vector2(6.0, bob - 2.0), 1.6, Color(MEAT_DARK, 0.9))
	draw_circle(Vector2(-2.0, bob + 7.0), 1.3, Color(MEAT_DARK, 0.7))
	draw_circle(Vector2(9.0, bob + 3.0), 1.0, Color(MEAT_LIGHT, 0.8))

	# Eyes.
	var eye_y := bob - 3.5
	var look := float(facing) * 1.4
	for ex in [-4.6, 4.6]:
		draw_circle(Vector2(ex, eye_y), 3.8, Color.WHITE)
		if _blink > 0.0:
			draw_line(Vector2(ex - 3.0, eye_y), Vector2(ex + 3.0, eye_y), INK, 1.6)
		else:
			draw_circle(Vector2(ex + look, eye_y), 1.7, INK)

	# A small worried mouth.
	draw_arc(Vector2(0, bob + 5.5), 3.4, PI * 0.15, PI * 0.85, 8, Color(OUTLINE, 0.9), 1.5)
