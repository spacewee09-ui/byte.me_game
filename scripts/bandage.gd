extends Area2D
## A bandage: the optional collectible. One per level, saved forever.

const PATCH := Color("#f4e6c8")
const PATCH_DARK := Color("#c9b48c")
const GLOW := Color("#ffd479")

var _t := 0.0
var _base := Vector2.ZERO


func _ready() -> void:
	collision_layer = 8
	collision_mask = 2
	monitoring = true
	monitorable = false
	_base = position
	_t = randf() * TAU

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 14.0
	shape.shape = circle
	add_child(shape)


func _process(delta: float) -> void:
	_t += delta
	position = _base + Vector2(0, sin(_t * 2.6) * 4.0)
	rotation = sin(_t * 1.7) * 0.14
	queue_redraw()


func _draw() -> void:
	# Glow and shadow.
	draw_circle(Vector2.ZERO, 19.0, Color(GLOW, 0.13))
	draw_circle(Vector2.ZERO, 14.0, Color("#1b0709"))
	# The patch itself: a rounded cream square with a darker border.
	draw_rect(Rect2(-11, -11, 22, 22), PATCH_DARK)
	draw_rect(Rect2(-10, -10, 20, 20), PATCH)
	# Stitches and the little pad in the middle.
	draw_rect(Rect2(-7, -3.2, 14, 6.4), Color("#e8d3a8"))
	for i in 3:
		draw_line(Vector2(-8 + i * 6, -8), Vector2(-8 + i * 6, 8), Color(PATCH_DARK, 0.5), 1.0)
	draw_line(Vector2(-9, -8), Vector2(-5, -8), Color("#8a7550"), 1.4)
	draw_line(Vector2(5, 8), Vector2(9, 8), Color("#8a7550"), 1.4)
