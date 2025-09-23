extends Node
class_name SFX

const BUS := "SFX"

# Preload clips
var _streams: Dictionary = {
	&"ui_click": preload("res://Audios/Beep S.wav"),
	&"ui_rightclick": preload("res://Audios/Hit XS.wav"),
	&"ui_drag": preload("res://Audios/PowerUp M2.wav"),
	&"ui_dragout": preload("res://Audios/PowerUp M.wav"),
	&"grumpy_explode": preload("res://Audios/Hit M.wav"),
	&"grumpy_satisfied": preload("res://Audios/Beep M.wav"),
}

func play_ui(id: StringName, volume_db: float = -6.0, pitch: float = 1.0) -> void:
	var stream: AudioStream = _streams.get(id)
	if stream == null:
		push_warning("Sfx: unknown id '%s'" % [id])
		return
	var p := AudioStreamPlayer.new()
	p.bus = BUS if _bus_exists(BUS) else "Master"
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = pitch
	add_child(p)
	p.finished.connect(p.queue_free)  
	p.play()

# World helper (for 2D positional sounds). Not required for UI clicks. 
func play_2d(id: StringName, parent: Node, at_world: Vector2, volume_db: float = -6.0, pitch: float = 1.0) -> void:
	var stream: AudioStream = _streams.get(id)
	if stream == null:
		push_warning("Sfx: unknown id '%s'" % [id])
		return
	var p := AudioStreamPlayer2D.new()
	p.bus = BUS if _bus_exists(BUS) else "Master"
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = pitch
	parent.add_child(p)
	p.global_position = at_world
	p.finished.connect(p.queue_free)
	p.play()

# Slight variation on pitch for “less repetitive” clicks
func play_ui_var(id: StringName, volume_db: float = -6.0, jitter: float = 0.05) -> void:
	var pitch := randf_range(1.0 - jitter, 1.0 + jitter)
	play_ui(id, volume_db, pitch)

func _bus_exists(name: String) -> bool:
	for i in AudioServer.bus_count:
		if AudioServer.get_bus_name(i) == name:
			return true
	return false
