extends Node2D
## A single flying chunk of meat (or dust, or confetti). Fire and forget.

var velocity := Vector2.ZERO
var gravity := 2200.0
var spin := 0.0
var life := 1.0
var color := Color("#c11f24")
var chunk_size := 5.0
var stretch := 1.6
var is_round := false
var drag := 0.0

var _age := 0.0


func _process(delta: float) -> void:
	_age += delta
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	velocity.y += gravity * delta
	velocity -= velocity * drag * delta
	position += velocity * delta
	rotation += spin * delta
	modulate.a = clampf(life * 2.0, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	if is_round:
		draw_circle(Vector2.ZERO, chunk_size, color)
	else:
		draw_rect(Rect2(-chunk_size * 0.5, -chunk_size * stretch * 0.5, chunk_size, chunk_size * stretch), color)
