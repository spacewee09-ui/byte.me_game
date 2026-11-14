extends Camera2D
## Follows the meat guy with a bit of lag, stays inside the level, and
## shakes when something violent happens.

var target: Node2D = null

var _shake := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed = 8.0
	_rng.randomize()


func _process(delta: float) -> void:
	if target != null and is_instance_valid(target):
		global_position = target.global_position + Vector2(0, -30)

	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta * 55.0)
		offset = Vector2(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0)) * _shake
	elif offset != Vector2.ZERO:
		offset = Vector2.ZERO


func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)
