extends Node
## Tiny sound helper, autoloaded as `Audio`.
## Call it from anywhere: Audio.play("jump")
## The sounds in assets/sfx were generated as simple 8-bit style blips.

const SOUNDS := {
	"jump": "res://assets/sfx/jump.wav",
	"walljump": "res://assets/sfx/walljump.wav",
	"land": "res://assets/sfx/land.wav",
	"death": "res://assets/sfx/death.wav",
	"collect": "res://assets/sfx/collect.wav",
	"win": "res://assets/sfx/win.wav",
	"click": "res://assets/sfx/click.wav",
}

const VOICES := 8

var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _cache := {}


func _ready() -> void:
	for i in VOICES:
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		_players.append(player)


func play(sound: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if not SOUNDS.has(sound) or _players.is_empty():
		return
	if not _cache.has(sound):
		_cache[sound] = load(SOUNDS[sound])
	var stream: AudioStream = _cache[sound]
	if stream == null:
		return
	var player := _players[_next]
	_next = (_next + 1) % _players.size()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.play()
