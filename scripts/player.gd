extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 5.0
const ACCELERATION = 1.5
const DECELERATION = 1.0

var hp:int = 100

var equiped = 1
var pistol_max = 6
var pistol_ammo = 6
var rifle_ammo = 20 
var rifle_max = 20

var bullet = load("res://scenes/bullet.tscn")
var bullet_trail = load("res://scenes/bullet_trail.tscn")
var instance

enum weapons {
	AUTO,
	PISTOLS
}

var weapon = weapons.AUTO
var can_shoot = true
@onready var weapon_switching = $AnimationPlayer

@onready var gun_anim: AnimationPlayer = $Camera3D/gunplakeholder/AnimationPlayer
@onready var gun_barrel: RayCast3D = $Camera3D/gunplakeholder/RayCast3D
@onready var auto_anim: AnimationPlayer = $Camera3D/rifle/AnimationPlayer
@onready var aim_ray: RayCast3D = $Camera3D/RayCast3D
@onready var aim_ray_end: Node3D = $Camera3D/aimrayend
@onready var auto_barrel: Node3D = $Camera3D/rifle/Barrel


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_lower_weapon()
	_raise_weapon(weapons.PISTOLS)


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("move_a", "move_d", "move_w", "move_s")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = move_toward(velocity.x, direction.x * SPEED, ACCELERATION)
		velocity.z = move_toward(velocity.z, direction.z * SPEED, ACCELERATION)
	else:
		velocity.x = move_toward(velocity.x, 0, DECELERATION)
		velocity.z = move_toward(velocity.z, 0, DECELERATION)
	if Input.is_action_just_pressed("reload"):
		can_shoot = false
		match weapon:
			weapons.AUTO:
				auto_anim.play("reload")
				rifle_ammo = rifle_max
				can_shoot = true
			weapons.PISTOLS:
				gun_anim.play("reload")
				pistol_ammo = pistol_max
				$Camera3D/Sprite3D/SubViewport/AmmoCount.text = str(pistol_ammo)
				can_shoot = true
	if Input.is_action_pressed("inspect"):
		gun_anim.play("inspect")
	if Input.is_action_pressed("spin"):
		gun_anim.play("spin")
	if Input.is_action_pressed("shoot") and can_shoot and equiped == 2 and rifle_ammo >= 1:
		_shoot_auto()
	if Input.is_action_just_pressed("shoot") and can_shoot and equiped == 1 and pistol_ammo >= 1:
		_shoot_pistols()
		
	if Input.is_action_just_pressed("weapon_one") and weapon != weapons.AUTO:
		_raise_weapon(weapons.AUTO)
		equiped = 2
	if Input.is_action_just_pressed("weapon_two") and weapon != weapons.PISTOLS:
		_raise_weapon(weapons.PISTOLS)
		equiped = 1

	move_and_slide()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * 0.01)
		$Camera3D.rotate_x(-event.relative.y * 0.01)
		$Camera3D.rotation.x = clampf($Camera3D.rotation.x, -deg_to_rad(89), deg_to_rad(89))

func hit(damage: int):
	if hp > 0:
		hp -= damage
		hp = max(hp, 0)
	
	
func _shoot_pistols():
	if !gun_anim.is_playing():
		gun_anim.play("fire")
		pistol_ammo -= 1
		$Camera3D/Sprite3D/SubViewport/AmmoCount.text = str(pistol_ammo)
		instance = bullet.instantiate()
		instance.damage = 20
		instance.position = gun_barrel.global_position
		instance.transform.basis = gun_barrel.global_transform.basis.rotated(gun_barrel.global_transform.basis * Vector3(0, -1, 0), PI/2)
		get_parent().add_child(instance)


func _shoot_auto():
	if !auto_anim.is_playing():
		auto_anim.play("shoot")
		rifle_ammo -= 1
		instance = bullet_trail.instantiate()
		if aim_ray.is_colliding():
			instance.init(auto_barrel.global_position, aim_ray.get_collision_point())
			get_parent().add_child(instance)
			if aim_ray.get_collider().has_method("hit"):
				aim_ray.get_collider().hit(10)
				instance.trigger_particles(aim_ray.get_collision_point(), auto_barrel.global_position, true)
			else:
				instance.trigger_particles(aim_ray.get_collision_point(), auto_barrel.global_position, false)
		else:
			instance.init(auto_barrel.global_position, aim_ray_end.global_position)
			get_parent().add_child(instance)

func _lower_weapon():
	match weapon:
		weapons.AUTO:
			weapon_switching.play("LowerAuto")
		weapons.PISTOLS:
			weapon_switching.play("LowerPistol")

func _raise_weapon(new_weapon):
	can_shoot = false
	_lower_weapon()
	await get_tree().create_timer(0.3).timeout
	match new_weapon:
		weapons.AUTO:
			weapon_switching.play_backwards("LowerAuto")
		weapons.PISTOLS:
			weapon_switching.play_backwards("LowerPistol")
	weapon = new_weapon
	can_shoot = true
