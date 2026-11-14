class_name MeatGuy
extends CharacterBody2D
## The meat guy himself.
##
## Everything that makes the movement feel good lives in the constants below.
## Coyote time = you can still jump for a moment after leaving a ledge.
## Jump buffer = pressing jump slightly before landing still counts.
## Those two tricks are what make a platformer feel tight instead of fussy.

signal died
signal jumped
signal wall_jumped
signal landed

# --- Feel knobs: tweak these to change how the game plays --------------------
const RUN_SPEED := 300.0
const GROUND_ACCEL := 3200.0
const AIR_ACCEL := 2300.0
const FRICTION := 3600.0
const GRAVITY := 2000.0
const FALL_GRAVITY := 2500.0
const MAX_FALL_SPEED := 1000.0
const JUMP_VELOCITY := -580.0
const JUMP_CUT := 0.4
const COYOTE_TIME := 0.1
const JUMP_BUFFER_TIME := 0.12
const WALL_SLIDE_SPEED := 150.0
const WALL_JUMP_PUSH := 350.0
const WALL_JUMP_UP := -570.0
const WALL_CONTROL_LOCK := 0.11

var alive := true
var controls_enabled := true

var _coyote := 0.0
var _jump_buffer := 0.0
var _wall_lock := 0.0
var _was_on_floor := false
var _facing := 1

@onready var visual = $Visual


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1


func _physics_process(delta: float) -> void:
	if not alive:
		return

	_jump_buffer = maxf(0.0, _jump_buffer - delta)
	_wall_lock = maxf(0.0, _wall_lock - delta)
	if is_on_floor():
		_coyote = COYOTE_TIME
	else:
		_coyote = maxf(0.0, _coyote - delta)

	var dir := 0.0
	if controls_enabled:
		dir = Input.get_axis("move_left", "move_right")
		if Input.is_action_just_pressed("jump"):
			_jump_buffer = JUMP_BUFFER_TIME
		# Let go early and you jump lower: variable jump height.
		if Input.is_action_just_released("jump") and velocity.y < -120.0:
			velocity.y *= JUMP_CUT

	# Horizontal movement. The wall lock stops you from instantly steering
	# back into the wall you just jumped off.
	if absf(dir) > 0.01:
		_facing = 1 if dir > 0.0 else -1
		if _wall_lock <= 0.0:
			var accel := GROUND_ACCEL if is_on_floor() else AIR_ACCEL
			velocity.x = move_toward(velocity.x, dir * RUN_SPEED, accel * delta)
	elif _wall_lock <= 0.0:
		var braking := FRICTION if is_on_floor() else AIR_ACCEL * 0.45
		velocity.x = move_toward(velocity.x, 0.0, braking * delta)

	if not is_on_floor():
		var g := GRAVITY if velocity.y < 0.0 else FALL_GRAVITY
		velocity.y = minf(velocity.y + g * delta, MAX_FALL_SPEED)

	_handle_wall_slide(dir)
	_handle_jump()

	var fall_speed := velocity.y
	move_and_slide()

	if is_on_floor() and not _was_on_floor:
		if fall_speed > 320.0:
			Audio.play("land", -10.0, randf_range(0.94, 1.06))
		visual.squash(Vector2(1.3, 0.74))
		landed.emit()
	_was_on_floor = is_on_floor()

	visual.facing = _facing
	visual.set_air_velocity(velocity.y)


func _handle_wall_slide(dir: float) -> void:
	if is_on_floor() or not is_on_wall():
		return
	var normal := get_wall_normal()
	# Pressing into the wall while falling = slow slide.
	if dir != 0.0 and signf(dir) == -signf(normal.x) and velocity.y > 0.0:
		velocity.y = minf(velocity.y, WALL_SLIDE_SPEED)
		visual.on_wall_slide()


func _handle_jump() -> void:
	if _jump_buffer <= 0.0 or not controls_enabled:
		return

	if is_on_floor() or _coyote > 0.0:
		velocity.y = JUMP_VELOCITY
		_coyote = 0.0
		_jump_buffer = 0.0
		visual.squash(Vector2(0.76, 1.32))
		Audio.play("jump", -7.0, randf_range(0.95, 1.08))
		jumped.emit()
		return

	if is_on_wall():
		var normal := get_wall_normal()
		velocity.x = normal.x * WALL_JUMP_PUSH
		velocity.y = WALL_JUMP_UP
		_wall_lock = WALL_CONTROL_LOCK
		_jump_buffer = 0.0
		visual.squash(Vector2(1.28, 0.78))
		Audio.play("walljump", -7.0, randf_range(0.95, 1.1))
		wall_jumped.emit()


func die() -> void:
	if not alive:
		return
	alive = false
	controls_enabled = false
	velocity = Vector2.ZERO
	visible = false
	set_physics_process(false)
	died.emit()


func respawn(at: Vector2) -> void:
	global_position = at
	velocity = Vector2.ZERO
	alive = true
	controls_enabled = true
	visible = true
	_coyote = 0.0
	_jump_buffer = 0.0
	_wall_lock = 0.0
	_was_on_floor = false
	set_physics_process(true)
	visual.reset()


func freeze() -> void:
	controls_enabled = false
	velocity.x = 0.0
