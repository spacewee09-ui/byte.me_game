extends Area2D
## The exit: a meat grinder. Touch it to finish the level.

const METAL := Color("#8d99a6")
const METAL_DARK := Color("#4a545e")
const METAL_LIGHT := Color("#c6d0da")
const GLOW := Color("#ffcf6b")

var _t := 0.0


func _ready() -> void:
	collision_layer = 8
	collision_mask = 2
	monitoring = true
	monitorable = false

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(34.0, 52.0)
	shape.shape = rect
	shape.position = Vector2(0, -8)
	add_child(shape)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(_t * 3.0)

	# Light spilling out of the machine.
	draw_circle(Vector2(0, -30), 30.0, Color(GLOW, 0.05 + pulse * 0.05))
	draw_rect(Rect2(-20, -52, 40, 54), Color(GLOW, 0.04 + pulse * 0.04))

	# Funnel on top.
	draw_colored_polygon(
		PackedVector2Array([Vector2(-16, -52), Vector2(16, -52), Vector2(10, -30), Vector2(-10, -30)]),
		METAL_DARK
	)
	draw_colored_polygon(
		PackedVector2Array([Vector2(-16, -52), Vector2(0, -52), Vector2(0, -30), Vector2(-10, -30)]),
		METAL
	)

	# Body.
	draw_rect(Rect2(-18, -30, 36, 42), METAL_DARK)
	draw_rect(Rect2(-16, -28, 32, 38), METAL)
	draw_rect(Rect2(-16, -28, 32, 5), METAL_LIGHT)

	# Grinding rollers.
	for i in 5:
		var x := -13.0 + i * 6.5
		draw_line(Vector2(x, -8), Vector2(x, 6), Color(METAL_DARK, 0.8), 1.5)
	draw_line(Vector2(-16, -1), Vector2(16, -1), Color("#2c333a"), 2.0)

	# Crank on the side, spinning.
	var crank := Vector2(24, -8)
	draw_line(Vector2(16, -8), crank, METAL_DARK, 3.5)
	draw_circle(crank, 4.0, METAL_LIGHT)
	draw_line(crank, crank + Vector2(cos(_t * 5.0), sin(_t * 5.0)) * 8.0, METAL_LIGHT, 2.5)

	# Feet.
	draw_rect(Rect2(-20, 10, 10, 6), METAL_DARK)
	draw_rect(Rect2(10, 10, 10, 6), METAL_DARK)

	# Little arrow telling you "this way".
	var bob := sin(_t * 4.0) * 2.0
	draw_colored_polygon(
		PackedVector2Array([Vector2(0, -70 + bob), Vector2(-7, -79 + bob), Vector2(7, -79 + bob)]),
		Color(GLOW, 0.85)
	)
