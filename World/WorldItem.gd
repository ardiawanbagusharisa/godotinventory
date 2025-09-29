extends RigidBody2D
class_name WorldItem

@export var item_id: StringName
@export var follow_while_dragging := true

@onready var vfx_parent: Node2D = get_tree().get_first_node_in_group("VFX") as Node2D

@export var collision_vfx: PackedScene 
@export var min_impact_speed: float = 80
@export var vfx_cooldown: float = 0.5   
var _vfx_cd_left := 0.0

var _dragging := false
var _inv_panel: Control
var _hover_state := false
var _last_highlighted_slot: ItemSlot

var _pre_linvel := Vector2.ZERO
var _pre_angvel := 0.0
var _last_mouse_pos := Vector2.ZERO
var _mouse_moved := false
const DRAG_EPS := 2.0   # pixels to consider as "moved"

func _ready() -> void:
	input_pickable = true
	var panels := get_tree().get_nodes_in_group("InventoryUI")
	if panels.size() > 0 and panels[0] is Control:
		_inv_panel = panels[0]
	
	# Comment this if your want no physics. You're boring! 
	if self is RigidBody2D:
		contact_monitor = true
		max_contacts_reported = 8

	if has_signal("body_entered"):
		connect("body_entered", _on_any_body_entered)
	if has_signal("area_entered"):
		connect("area_entered", _on_any_area_entered)

func _on_any_body_entered(_body: Node) -> void:
	_on_collided_or_given()
	#_try_spawn_VFX()

func _on_any_area_entered(_area: Area2D) -> void:
	_on_collided_or_given()
	#_try_spawn_VFX()

func _on_body_entered(_body: Node) -> void:
	_on_collided_or_given()
	#_try_spawn_VFX()

func _try_spawn_VFX() -> void:
	if _vfx_cd_left > 0.0:
		return
	_spawn_collision_vfx(global_position)
	_vfx_cd_left = vfx_cooldown

func set_item_id(id: StringName) -> void:
	item_id = id
	
func _input_event(_vp: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_dragging = true
		_mouse_moved = false
		_last_mouse_pos = get_global_mouse_position()

		# cache current velocities (not strictly needed, but handy if you later want "throw")
		_pre_linvel = linear_velocity
		_pre_angvel = angular_velocity

		# freeze as kinematic for safe dragging
		set_deferred("freeze_mode", RigidBody2D.FREEZE_MODE_KINEMATIC)
		set_deferred("freeze", true)

		# kill any residual motion immediately
		linear_velocity = Vector2.ZERO
		angular_velocity = 0.0
		sleeping = true

func _input(event: InputEvent) -> void:
	if not _dragging: return
	
	if event is InputEventMouseMotion and follow_while_dragging and _dragging:
			var mp := get_global_mouse_position()
			if not _mouse_moved and mp.distance_to(_last_mouse_pos) > DRAG_EPS:
				_mouse_moved = true
			global_position = mp
			_last_mouse_pos = mp
			_update_inventory_slot_highlight()
			var over := _over_inventory_panel()
			if over != _hover_state:
				_hover_state = over
				if _inv_panel and _inv_panel.has_method("set_hover"):
					_inv_panel.set_hover(_hover_state)
					
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_dragging = false
		_clear_inventory_slot_highlight()
		 
		if _inv_panel and _inv_panel.has_method("set_hover"):
			_inv_panel.set_hover(false)
		if _over_inventory_panel():
			if item_id != &"": Inventory.add_item(item_id, 1)
			else: push_warning("WorldItem has empty item_id; set it in the Inspector")
			queue_free()
			SFXManager.play_ui(&"ui_drag")
		else:
			set_deferred("freeze", false)
			call_deferred("_drop_stabilize") 

func _drop_stabilize() -> void:
	await get_tree().physics_frame
	# hard zero any residual motion after the freeze toggle
	#linear_velocity = Vector2.ZERO
	#angular_velocity = 0.0
	#constant_force = Vector2.ZERO   # 4.4 property (no applied_force)
	#constant_torque = 0.0
	sleeping = false
	
func _over_inventory_panel() -> bool:
	if _inv_panel == null or not _inv_panel.visible: return false
	var rect: Rect2 = _inv_panel.get_global_rect()
	var mouse_screen := get_viewport().get_mouse_position()
	return rect.has_point(mouse_screen)

func _update_inventory_slot_highlight() -> void:
	var target: ItemSlot = null

	# Hovered matching slot UI.
	var hovered := get_viewport().gui_get_hovered_control()
	while hovered:
		if hovered is ItemSlot and hovered.item_id == item_id:
			target = hovered
			break
		hovered = hovered.get_parent() as Control

	# Fallback: find a matching slot anywhere. 
	if target == null:
		target = _find_matching_inventory_slot(item_id)

	# Clear previously different or invalid.
	if _last_highlighted_slot != null:
		if not is_instance_valid(_last_highlighted_slot) or _last_highlighted_slot != target:
			if is_instance_valid(_last_highlighted_slot):
				_last_highlighted_slot.set_highlight(false)
			_last_highlighted_slot = null

	# Apply highlight if valid only. 
	if target != null and is_instance_valid(target):
		target.set_highlight(true)
		_last_highlighted_slot = target
	else:
		_clear_inventory_slot_highlight()

func _clear_inventory_slot_highlight() -> void:
	if _last_highlighted_slot != null and is_instance_valid(_last_highlighted_slot):
		_last_highlighted_slot.set_highlight(false)
	_last_highlighted_slot = null

func _find_matching_inventory_slot(id: StringName) -> ItemSlot:
	if _inv_panel and _inv_panel.is_inside_tree():
		if _inv_panel.has_method("get_slots"):
			for s in _inv_panel.get_slots():
				if s and s.is_visible_in_tree() and s.item_id == id:
					return s

	for n in get_tree().get_nodes_in_group("ItemSlot"):
		if n is ItemSlot and n.is_visible_in_tree() and n.item_id == id:
			return n

	return null

func _physics_process(delta: float) -> void:
	_vfx_cd_left = max(0.0, _vfx_cd_left - delta)
	if _vfx_cd_left > 0.0:
		return

	# RigidBody2D path: use contacts if available
	if self is RigidBody2D:
		var rb := self as RigidBody2D
		var cc := rb.get_contact_count()
		if cc <= 0:
			return

		# Rough impact check using linear speed
		var speed := rb.linear_velocity.length()
		if speed < min_impact_speed:
			return

		# Try to get a world-space contact point; fall back to an approximation
		var hit_pos: Vector2 = global_position
		var used := false

		# (A) Preferred: collider position if the method exists
		if rb.has_method("get_contact_collider_position"):
			hit_pos = rb.get_contact_collider_position(0)
			used = true

		# (B) Fallback: local normal -> offset a bit from the body
		if not used and rb.has_method("get_contact_local_normal"):
			var n = rb.get_contact_local_normal(0)
			if n != Vector2.ZERO:
				hit_pos = to_global(n.normalized() * 8.0) # small offset
				used = true

		#_spawn_collision_vfx(hit_pos)
		_vfx_cd_left = vfx_cooldown
		return

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

func _on_collided_or_given() -> void:
	var vfx_parent := get_tree().get_first_node_in_group("VFX") as Node
	var pos := global_position 
	SparkEmitter2D.emit_spark(vfx_parent if vfx_parent else get_tree().current_scene, pos, SparkEmitter2D.for_world_item())

	
func _make_default_spark_2d() -> GPUParticles2D:
	var p := GPUParticles2D.new()
	p.one_shot = true
	p.lifetime = 0.45
	p.amount = 28
	p.explosiveness = 1.0

	var mat := ParticleProcessMaterial.new()
	# 2D fields (Vector2), keep it simple and compatible
	mat.gravity = Vector3(0.0, 500.0, 0.0)
	mat.initial_velocity_min = 120.0
	mat.initial_velocity_max = 240.0
	mat.angular_velocity_min = -12.0
	mat.angular_velocity_max =  12.0
	mat.spread = 180
	mat.scale_min = 0.2
	mat.scale_max = 1.5
	p.process_material = mat

	# Tiny texture dot so sparks are visible
	var img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 0.85, 0.3, 0.75))
	var tex := ImageTexture.create_from_image(img)
	p.texture = tex

	return p
