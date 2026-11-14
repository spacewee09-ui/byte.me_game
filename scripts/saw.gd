extends Area2D
## A spinning saw blade. Static saws just sit there; patrolling saws slide
## back and forth along a rail, which is where the panic comes from.

const RADIUS := 23.0
const STEEL := Color("#9aa6b2")
const STEEL_LIGHT := Color("#cfd8e2")
const STEEL_DARK := Color("#4d5762")

## How far the saw slides from where the level placed it.
var patrol := Vector2.ZERO
## Radians per second.
var spin := 4.0
## How long a full back-and-forth takes.
var patrol_time := 2.6

var _angle := 0.0
var _origin := Vector2.ZERO
var _t := 0.0


func _ready() -> void:
	collision_layer = 4
	collision_mask = 2
	monitoring = true
	monitorable = false
	_origin = position
	_t = randf() * patrol_time

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = RADIUS
	shape.shape = circle
	add_child(shape)


func _process(delta: float) -> void:
	_angle += spin * delta
	if patrol != Vector2.ZERO:
		_t += delta
		var wave := sin(_t * TAU / patrol_time)
		position = _origin + patrol * wave
	queue_redraw()


func _draw() -> void:
	# Rail first so it sits behind the blade.
	if patrol != Vector2.ZERO:
		draw_line(-patrol, patrol, Color("#2b131c"), 4.0)
		draw_line(-patrol, patrol, Color("#6b4650"), 1.5)

	# Toothed blade.
	var teeth := 10
	var points := PackedVector2Array()
	for i in teeth * 2:
		var a := _angle + TAU * float(i) / float(teeth * 2)
		var r := RADIUS if i % 2 == 0 else RADIUS * 0.76
		points.append(Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(points, STEEL_DARK)

	var inner := PackedVector2Array()
	for i in 20:
		var a := _angle + TAU * float(i) / 20.0
		inner.append(Vector2(cos(a), sin(a)) * (RADIUS * 0.68))
	draw_colored_polygon(inner, STEEL)

	# Highlight sweep and hub.
	draw_arc(Vector2.ZERO, RADIUS * 0.82, _angle + 2.4, _angle + 4.1, 10, Color(STEEL_LIGHT, 0.8), 2.0)
	draw_circle(Vector2.ZERO, RADIUS * 0.3, Color("#5c6672"))
	draw_circle(Vector2.ZERO, RADIUS * 0.14, Color("#2f363f"))
