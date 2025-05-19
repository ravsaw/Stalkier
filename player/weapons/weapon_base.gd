extends Node3D
class_name Weapon

enum WeaponClass { LONG, SHORT }
enum FireMode { SEMI, BURST, AUTO }

@export var weapon_name: String = "Pistol"
@export var weapon_class: WeaponClass = WeaponClass.SHORT
@export var fire_mode: FireMode = FireMode.SEMI
@export var damage: float = 25.0
@export var fire_rate: float = 0.2  # Time between shots
@export var max_ammo: int = 12
@export var reserve_ammo: int = 48
@export var reload_time: float = 1.5
@export var bullet_scene: PackedScene

# Nodes
@onready var audio_player = $AudioPlayer
@onready var animation_player = $AnimationPlayer
@onready var muzzle_flash = $MuzzleFlash
@onready var ray_cast = $RayCast3D

var current_ammo: int = max_ammo
var can_fire: bool = true
var is_reloading: bool = false
var last_shot_time: float = 0

signal ammo_changed()

func _ready():
	muzzle_flash.hide()

func fire() -> bool:
	if !can_fire or current_ammo <= 0 or is_reloading:
		#if current_ammo <= 0:
			#play_sound("empty")
		return false
	
	# Rate of fire check
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_shot_time < fire_rate:
		return false
	
	last_shot_time = current_time
	
	# Fire weapon
	current_ammo -= 1
	emit_signal("ammo_changed")
	
	# Effects
	animation_player.play("fire")
	#play_sound("fire")
	display_muzzle_flash()
	
	# Bullet collision detection
	if ray_cast.is_colliding():
		var hit_point = ray_cast.get_collision_point()
		var hit_object = ray_cast.get_collider()
		
		# Spawn impact effect
		#spawn_impact_effect(hit_point, ray_cast.get_collision_normal())
		
		# Apply damage if applicable
		if hit_object.has_method("take_damage"):
			hit_object.take_damage(damage, hit_point)
	
	# If we have a bullet scene, instantiate it
	if bullet_scene:
		spawn_bullet()
	
	return true

func reload() -> bool:
	if is_reloading or current_ammo == max_ammo or reserve_ammo <= 0:
		return false
	
	is_reloading = true
	#play_sound("reload")
	animation_player.play("reload")
	
	# Schedule reload completion after animation
	await get_tree().create_timer(reload_time).timeout
	
	# Calculate ammo to reload
	var ammo_needed = max_ammo - current_ammo
	var ammo_to_load = min(ammo_needed, reserve_ammo)
	
	current_ammo += ammo_to_load
	reserve_ammo -= ammo_to_load
	
	is_reloading = false
	emit_signal("ammo_changed")
	
	return true

#func play_sound(sound_type: String) -> void:
	# Play appropriate sound based on type
#	match sound_type:
#		"fire":
#			audio_player.stream = preload("res://audio/weapons/pistol_fire.wav")
#		"reload":
#			audio_player.stream = preload("res://audio/weapons/pistol_reload.wav")
#		"empty":
#			audio_player.stream = preload("res://audio/weapons/empty_click.wav")
	
#	audio_player.play()

func display_muzzle_flash() -> void:
	muzzle_flash.show()
	await get_tree().create_timer(0.05).timeout
	muzzle_flash.hide()

#func spawn_impact_effect(position: Vector3, normal: Vector3) -> void:
#	# Instantiate impact effect at hit point
#	var impact = preload("res://effects/bullet_impact.tscn").instantiate()
#	get_tree().root.add_child(impact)
#	impact.global_transform.origin = position
#	impact.global_transform.basis = Basis(normal.cross(Vector3.UP).normalized(), normal, normal.cross(Vector3.RIGHT).normalized())

func spawn_bullet() -> void:
	var bullet = bullet_scene.instantiate()
	get_tree().root.add_child(bullet)
	bullet.global_transform = ray_cast.global_transform
	bullet.direction = -ray_cast.global_transform.basis.z

func on_equip() -> void:
	animation_player.play("equip")

func on_unequip() -> void:
	animation_player.play("unequip")
