extends Node

class_name SparkEmitter2D
## Drop this anywhere, or call SparkEmitter2D.emit_spark(...) statically.
## Works with either a PackedScene("SparkBurst2D.tscn") or any GPUParticles2D you pass in.

@export var spark_scene: PackedScene  # assign SparkBurst2D.tscn in the editor

# Small “config” bag so callers don’t need a dozen params.
class SparkConfig:
	var amount: int = 28
	var lifetime: float = 0.45
	var spread_deg: float = 160.0
	var vel_min: float = 120.0
	var vel_max: float = 240.0
	var gravity_y: float = 500.0
	var color_a: Color = Color(1.0, 0.9, 0.5, 0.95)
	var color_b: Color = Color(1.0, 0.6, 0.2, 0.0)
	var angular_velocity_min: float = -12.0
	var angular_velocity_max: float =  12.0
	var scale_min: float = 0.2
	var scale_max: float = 1.5
	var dot_size: int = 4
	var dot_color: Color = Color(1, 0.85, 0.3, 0.75)

static func default_config() -> SparkConfig:
	return SparkConfig.new()

static func for_world_item() -> SparkConfig:
	var c := SparkConfig.new()
	c.amount = 28
	c.lifetime = 0.45
	c.spread_deg = 180.0
	c.vel_min = 120.0
	c.vel_max = 240.0
	c.gravity_y = 500.0
	c.color_a = Color(1.0, 0.9, 0.5, 0.95)
	c.color_b = Color(1.0, 0.6, 0.2, 0.0)
	c.angular_velocity_min = -12.0
	c.angular_velocity_max =  12.0
	c.scale_min = 0.2
	c.scale_max = 1.5
	c.dot_size = 4
	c.dot_color = Color(1, 0.85, 0.3, 0.75)
	return c

static func for_grumpy_villager() -> SparkConfig:
	var c := SparkConfig.new()
	c.amount = 28
	c.lifetime = 0.45
	c.spread_deg = 180.0
	c.vel_min = 150.0
	c.vel_max = 300.0
	c.gravity_y = 400.0
	c.color_a = Color(1.0, 0.3, 0.3, 1.0)
	c.color_b = Color(1.0, 0.6, 0.2, 0.0)
	c.angular_velocity_min = -12.0
	c.angular_velocity_max =  12.0
	c.scale_min = 0.2
	c.scale_max = 1.5
	c.dot_size = 8
	c.dot_color = Color(1, 0.3, 0.3, 1.0)  
	return c

func make_spark(parent: Node, at_position: Vector2, cfg: SparkConfig = default_config()) -> GPUParticles2D:
	assert(parent, "SparkEmitter2D.make_spark: parent is null")

	#var inst: Node2D = (spark_scene?.instantiate() as Node2D) ?? Node2D.new()
	var inst: Node2D = (spark_scene.instantiate() as Node2D) if (spark_scene != null) else Node2D.new()
	parent.add_child(inst)
	inst.global_position = at_position

	var gp := inst.get_node_or_null("Particles") as GPUParticles2D
	if gp == null:
		gp = GPUParticles2D.new()
		inst.add_child(gp)

	gp.amount = cfg.amount
	gp.lifetime = cfg.lifetime
	gp.explosiveness = 1.0
	gp.one_shot = true
	gp.emitting = false

	var m := ParticleProcessMaterial.new()
	m.spread = cfg.spread_deg
	m.initial_velocity_min = cfg.vel_min
	m.initial_velocity_max = cfg.vel_max
	m.gravity = Vector3(0.0, cfg.gravity_y, 0.0) 
	m.angular_velocity_min = cfg.angular_velocity_min
	m.angular_velocity_max = cfg.angular_velocity_max
	m.scale_min = cfg.scale_min
	m.scale_max = cfg.scale_max

	# Color ramp
	var grad := Gradient.new()
	grad.add_point(0.0, cfg.color_a)
	grad.add_point(1.0, cfg.color_b)
	var ramp := GradientTexture1D.new()
	ramp.gradient = grad
	m.color_ramp = ramp

	gp.process_material = m

	# Tiny dot texture
	var size = max(1, cfg.dot_size)
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(cfg.dot_color)
	var tex := ImageTexture.create_from_image(img)
	gp.texture = tex

	return gp

static func emit_spark(parent: Node, at_position: Vector2, cfg: SparkConfig = default_config()) -> void:
	var temp := SparkEmitter2D.new()
	parent.add_child(temp)
	var gp := temp.make_spark(parent, at_position, cfg)
	gp.emitting = true
	await temp.get_tree().create_timer(gp.lifetime + 0.1).timeout
	if is_instance_valid(temp.get_parent()): 
		temp.queue_free()

func _cleanup_after(gp: GPUParticles2D) -> void:
	if not is_instance_valid(gp): return
	var host := gp.get_parent()
	await get_tree().create_timer(gp.lifetime + 0.1).timeout
	if is_instance_valid(host): host.queue_free()
	queue_free()
