extends CharacterBody2D
class_name GrumpyVillager

signal villager_satisfied(wanted: StringName)

@export var main_root: Main 

# --- Movement / patrol ---
@export var gravity: float = 1200.0
@export var speed: float = 60.0
@export var patrol_width: float = 800.0
@export var turn_on_wall: bool = true
@export var consume_item_on_touch: bool = true
@export var collision_vfx: PackedScene 
# --- Demand / balloon ---
@export var wanted_id: StringName = &""
@export var fallback_icons: Dictionary = {}

@export var angry_waiting_time: float = 15
@export var calm_color: Color = Color(1, 1, 1, 1)     
@export var angry_color: Color = Color(1, 0.15, 0.15, 1) 
@export var vfx_cooldown: float = 0.5  

@export var character_textures: Array[Texture2D] = []

var _wait_elapsed := 0.0
var _satisfied := false

var _patrol_left := -INF
var _patrol_right := INF
var _dir := -1.0

# cached nodes
var _balloon: Sprite2D
var _balloon_icon: TextureRect
var _char_sprite: Sprite2D
var _touch: Area2D

var _vfx_cd_left := 0.0

func _ready() -> void:
	add_to_group("grumpy_villager")

	_balloon = $Balloon if has_node("Balloon") else null
	_balloon_icon = $Balloon/TextureRect if has_node("Balloon/TextureRect") else null
	_char_sprite = $CharacterSprite if has_node("CharacterSprite") else null
	_touch = $Touch if has_node("Touch") else null
	
	if character_textures.size() > 0:
		randomize()  # ok to call here; per-spawn randomness
		var tex := character_textures[randi() % character_textures.size()]
		_char_sprite.texture = tex
	
	if main_root == null: 
		main_root = _find_main()
	if _char_sprite:
		_char_sprite.modulate = calm_color
	if _balloon_icon:
		#_balloon_icon.modulate = Color(1, 1, 1, 1) 
		_balloon_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		#_balloon_icon.custom_minimum_size = Vector2(64, 64)
		#_balloon_icon.size = _balloon_icon.custom_minimum_size
	_refresh_balloon_icon()
	
	# If spawner didn't set bounds, default to centered window using patrol_width
	if _patrol_left == -INF and _patrol_right == INF:
		var half := patrol_width * 0.5
		_patrol_left = global_position.x - half
		_patrol_right = global_position.x + half
		
	if _touch and _touch.has_signal("body_entered"):
		_touch.connect("body_entered", Callable(self, "_on_touch_body_entered"))

func _find_main() -> Main:
	# 1) Walk up parents
	var p := get_parent()
	while p:
		if p is Main:
			return p
	p = p.get_parent()

	# 2) Current scene root (or child named "Main")
	var cs := get_tree().current_scene
	if cs is Main:
		return cs
	if cs:
		var found := cs.find_child("Main", true, false)
		if found is Main:
			return found

	# 3) A node named "Main" at the window root
	var r := get_tree().root
	if r and r.has_node("Main"):
		var n := r.get_node("Main")
		if n is Main:
			return n

	# 4) Optional: if you add Main to a group "MainRoot"
	for n in get_tree().get_nodes_in_group("MainRoot"):
		if n is Main:
			return n

	return null
	
func set_patrol_bounds(left: float, right: float) -> void:
	_patrol_left = min(left, right)
	_patrol_right = max(left, right)

func set_speed(v: float) -> void:
	speed = v

func set_wanted_id(id: StringName) -> void:
	wanted_id = id
	_refresh_balloon_icon()

func _process(delta: float) -> void:
	if _satisfied:
		return
	_wait_elapsed += delta
	var t = clamp(_wait_elapsed / angry_waiting_time, 0.0, 1.0)

	if _char_sprite:
		_char_sprite.modulate = calm_color.lerp(angry_color, t)

	if _wait_elapsed >= angry_waiting_time:
		main_root.update_angry_souls(1)
		main_root.update_satisfied_souls(-1)
		queue_free()
		_try_spawn_VFX()
		SFXManager.play_ui(&"grumpy_explode")
		if main_root.angry_souls >= 5: 
			print("Game Over!")
			get_tree().paused = true

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 50.0  # small stick to floor

	velocity.x = speed * _dir

	if turn_on_wall:
		for i in get_slide_collision_count():
			var col := get_slide_collision(i)
			if col and abs(col.get_normal().x) > 0.8:
				_dir *= -1.0
				break

	if global_position.x < _patrol_left:
		global_position.x = _patrol_left
		_dir = 1.0
	elif global_position.x > _patrol_right:
		global_position.x = _patrol_right
		_dir = -1.0

	if _char_sprite:
		_char_sprite.flip_h = _dir < 0.0

	move_and_slide()

func _on_touch_body_entered(body: Node) -> void:
	if body is WorldItem:
		var wi := body as WorldItem
		if wanted_id != &"" and wi.item_id == wanted_id:
			_satisfied = true
			if consume_item_on_touch:
				wi.queue_free()
			emit_signal("villager_satisfied", wanted_id)
			main_root.update_satisfied_souls(1)
			main_root.update_angry_souls(-1)
			queue_free()
			SFXManager.play_ui(&"grumpy_satisfied")

func _refresh_balloon_icon() -> void:
	if not _balloon_icon:
		return
	var tex := _resolve_icon_for_id(wanted_id)
	_balloon_icon.texture = tex
	_balloon_icon.visible = tex != null
	if _balloon:
		_balloon.visible = true  

func _resolve_icon_for_id(id: StringName) -> Texture2D:
	# 1) Try ItemDB autoload/node exposing get_item(id) -> ItemData
	var root := get_tree().root
	if root and root.has_node("ItemDB"):
		var db := root.get_node("ItemDB")
		if db and db.has_method("get_item"):
			var data = db.call("get_item", id)
			# data should be ItemData; just read .icon safely
			if data and data is ItemData and data.icon:
				return data.icon

	# 2) Fallback from inspector dictionary (optional)
	if fallback_icons.has(String(id)):
		return fallback_icons[String(id)] as Texture2D

	return null

func _try_spawn_VFX() -> void:
	if _vfx_cd_left > 0.0:
		return
	_spawn_collision_vfx(global_position)
	_vfx_cd_left = vfx_cooldown
	
func _spawn_collision_vfx(at_pos: Vector2) -> void:
	var vfx: Node2D
	if collision_vfx:
		vfx = collision_vfx.instantiate() as Node2D
	else:
		vfx = _make_default_spark_2d()

	if vfx == null:
		return

	vfx.global_position = at_pos
	get_tree().current_scene.add_child(vfx)

	if vfx is GPUParticles2D:
		vfx.one_shot = true
		vfx.emitting = true
		(vfx as GPUParticles2D).finished.connect(vfx.queue_free)
	else:
		get_tree().create_timer(0.6).timeout.connect(vfx.queue_free)

func _make_default_spark_2d() -> GPUParticles2D:
	var p := GPUParticles2D.new()
	p.one_shot = true
	p.lifetime = 0.45
	p.amount = 28
	p.explosiveness = 1.0

	var mat := ParticleProcessMaterial.new()
	# 2D fields (Vector2), keep it simple and compatible
	mat.gravity = Vector3(0.0, 400.0, 0.0)
	mat.initial_velocity_min = 150.0
	mat.initial_velocity_max = 300.0
	mat.angular_velocity_min = -12.0
	mat.angular_velocity_max =  12.0
	mat.spread = 180
	mat.scale_min = 0.2
	mat.scale_max = 1.5
	p.process_material = mat

	# Tiny texture dot so sparks are visible
	var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 0.3, 0.3, 1.0))
	var tex := ImageTexture.create_from_image(img)
	p.texture = tex

	return p
