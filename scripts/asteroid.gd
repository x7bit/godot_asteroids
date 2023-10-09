class_name Asteroid extends Area2D

enum AsteroidSize{SMALL, MEDIUM, LARGE}

signal exploded(pos: Vector2, new_rotation: float, size: Asteroid.AsteroidSize, points: int)

const BASE_SPEED: float = 50.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var cshape: CollisionShape2D = $CollisionShape2D

@export var size: AsteroidSize = AsteroidSize.LARGE
var center_offset: Vector2 = Vector2.ZERO
var speed: float = BASE_SPEED
var speed_multiplier: float = 1.0
var move_rotation: float = 0.0
var alfa: float = 1.0
var twin_id: int = -1

var id: int:
	get:
		return get_instance_id()

var global_center: Vector2:
	get:
		return global_position + center_offset

var radius: float:
	get:
		return cshape.shape.radius

var points: int:
	get:
		match size:
			AsteroidSize.SMALL: return 100
			AsteroidSize.MEDIUM: return 50
			AsteroidSize.LARGE: return 25
			_: return 0

var explosion_scale: float:
	get:
		match size:
			AsteroidSize.SMALL: return 0.4
			AsteroidSize.MEDIUM: return 0.5
			AsteroidSize.LARGE: return 0.8
			_: return 0.0

var mass_multiplier: float:
	get:
		return pow(2, size) * 2

func _ready():
	rotation = randf_range(0, 2 * PI)
	match size:
		AsteroidSize.SMALL:
			speed = randf_range(speed_multiplier * 2.5 * BASE_SPEED, speed_multiplier * 3.5 * BASE_SPEED)
			sprite.texture = preload("res://assets/textures/asteroid_small.png")
			cshape.shape = preload("res://resources/asteroid_cshape_small.tres")
		AsteroidSize.MEDIUM:
			speed = randf_range(speed_multiplier * 1.5 * BASE_SPEED, speed_multiplier * 2.5 * BASE_SPEED)
			sprite.texture = preload("res://assets/textures/asteroid_medium.png")
			cshape.shape = preload("res://resources/asteroid_cshape_medium.tres")
		AsteroidSize.LARGE:
			alfa = 0.0
			speed = randf_range(speed_multiplier * BASE_SPEED, speed_multiplier * 1.5 * BASE_SPEED)
			sprite.modulate.a = alfa
			sprite.texture = preload("res://assets/textures/asteroid_large.png")
			cshape.shape = preload("res://resources/asteroid_cshape_large.tres")
	center_offset = cshape.position.rotated(rotation)

func _process(delta: float):
	if alfa < 1.0:
		alfa = minf(alfa + 1.5 * delta, 1.0)
		sprite.modulate.a = alfa
	else:
		global_position += Vector2.UP.rotated(move_rotation) * speed * delta
		var screen_size: Vector2 = get_viewport_rect().size
		if (global_position.y + radius) < 0: #UP
			global_position.y = screen_size.y + radius
		elif (global_position.y - radius) > screen_size.y: #DOWN
			global_position.y = -radius
		if (global_position.x + radius) < 0: #LEFT
			global_position.x = screen_size.x + radius
		elif (global_position.x - radius) > screen_size.x: #RIGHT
			global_position.x = -radius

func _on_area_entered(area: Area2D):
	if area is Laser:
		if !area.exploded:
			explode(area)
			area.explode_and_free(explosion_scale)
	if area is Asteroid:
		if size <= area.size && twin_id != area.id:
			bounce(area)

func _on_body_entered(body: CharacterBody2D):
	if body is Player:
		body.die()

func _on_area_exited(area: Area2D):
	if area is Asteroid:
		if twin_id == area.id:
			twin_id = -1

func init(_pos: Vector2, _new_rotation: float, _size: Asteroid.AsteroidSize, _twin_id: int):
	global_position = _pos
	size = _size
	move_rotation = _new_rotation
	twin_id = _twin_id
	speed_multiplier = Global.asteroid_speed_multiplier

func explode(laser: Laser):
	var new_rotation = Util.get_explosion_rotation(laser, self)
	emit_signal("exploded", global_position, new_rotation, size, points)
	queue_free()

func bounce(asteroid: Asteroid):
	var center_diff_vector: Vector2 = global_center - asteroid.global_center
	var normal_vector: Vector2 = center_diff_vector.orthogonal().normalized()
	reflect(normal_vector)

func reflect(normal_vector: Vector2):
	var move_vector := Vector2.UP.rotated(move_rotation)
	move_rotation = Util.get_rotation_based_up_vector(move_vector.reflect(normal_vector))
