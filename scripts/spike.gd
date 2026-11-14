extends Area2D
## A row of spikes. The level places one of these per spike tile.
## Pointing down is the same node flipped vertically.

const STEEL := Color("#aab6c4")
const STEEL_DARK := Color("#5d6875")
const STEEL_LIGHT := Color("#dfe6ee")

var pointing_down := false


func _ready() -> void:
	collision_layer = 4
	collision_mask = 2
	monitoring = true
	monitorable = false

	if pointing_down:
		scale = Vector2(1, -1)

	# Only the base of the spike is solid-ish, so brushing the very tip
	# at full speed still hurts but you are not killed by thin air.
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(30.0, 15.0)
	shape.shape = rect
	shape.position = Vector2(0, 8)
	add_child(shape)


func _draw() -> void:
	# Three little blades per tile.
	for i in 3:
		var x := -11.0 + i * 11.0
		var tip := Vector2(x, -4.0)
		var left := Vector2(x - 5.5, 13.0)
		var right := Vector2(x + 5.5, 13.0)
		draw_colored_polygon(PackedVector2Array([left, tip, right]), STEEL_DARK)
		draw_colored_polygon(
			PackedVector2Array([Vector2(x - 1.5, -1.0), tip, Vector2(x - 3.0, 12.0)]),
			STEEL
		)
		draw_line(tip, right, STEEL_DARK, 1.2)
		draw_line(left + Vector2(1, 12), right, STEEL_LIGHT, 1.0)
	# Base plate.
	draw_rect(Rect2(-15, 12, 30, 4), Color("#3b1f26"))
