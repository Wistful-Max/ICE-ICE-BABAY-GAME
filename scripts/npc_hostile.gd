extends CharacterBody3D

@export var walk_pathNPC:Array[Marker3D]

@onready var Player = $"../Player"

@onready var NPCnav_3d:NavigationAgent3D = $NavigationAgent3D
@onready var idle_timer: Timer =$Idle_Timer

@onready var Animation_player :AnimationPlayer =$Rembot_NPC/AnimationPlayer

enum  NPCStates {
	IDLE,
	walking,
	death,
	jump
}

var current_states:NPCStates
var current_place:Marker3D

var SPEED:float = 2.0
var hp:int = 100

func _ready() -> void:
	_set_state(NPCStates.IDLE)
	
func _set_state(new_state:NPCStates) -> void:
	current_states = new_state
	
	match current_states:
		NPCStates.IDLE:
			Animation_player.play(["idle_1","idle_breathing"].pick_random())
			idle_timer.start(1.0 + randf())
		NPCStates.walking:
			Animation_player.play("forward")
		NPCStates.death:
			Animation_player.play("deadth")
		NPCStates.jump:
			velocity.y = 3
			_set_state(NPCStates.walking)

func _physics_process(delta: float) -> void:
	match current_states:
		NPCStates.IDLE:
			look_at(Player.position)
			velocity.x = 0
			velocity.z = 0
		NPCStates.walking:
			var next_path_poth:Vector3 = NPCnav_3d.get_next_path_position()
			var new_velocity:Vector3 = global_position.direction_to(next_path_poth) * SPEED
			velocity.x = new_velocity.x
			velocity.z = new_velocity.z
			var next_point:Vector3 = Vector3(next_path_poth.x,global_position.y,next_path_poth.z)
			#so the npc turnes and dont look weird
			if not Vector3(global_position - next_point).length() < 0.05:
				look_at(next_point)
				rotate_y(PI)
			else:
				_set_state(NPCStates.IDLE)
			if velocity.z <= 1.4 && velocity.x <= 1.4 && is_on_floor():
				_set_state(NPCStates.jump)
				print("hester!!")
			else:
					print(velocity.x)
				
		
		
		
		
		
		NPCStates.death:
			velocity.x = 0
			velocity.z = 0
	if not is_on_floor():
		velocity += get_gravity() * delta
	move_and_slide()
	
				
func _on_idle_timer_timeout() -> void:
	next_state()
	print("Hester.")
	print("Hester.")
	print("Hester.")
	print("Hester.")
	print("Hester.")
	print("Hester.")
	print("Hester.")
	print("Hester.")
	
	
func next_state() -> void:
	# only if alredy idle 
	if current_states == NPCStates.IDLE:
		new_target()
		_set_state(NPCStates.walking)
		
func new_target():
	current_place = walk_pathNPC.pick_random()
	NPCnav_3d.target_position = current_place.global_position
 
func hit(damage: int):
	if current_states != NPCStates.death:
		Animation_player.play("idle_2")
		hp -= damage
		if hp <= 0:
			_set_state(NPCStates.death)
			hp = 0
		$Rembot_NPC/Sprite3D/SubViewport/Npc_walker_healthbar.value = hp
	print("waow " + str(hp))
	
