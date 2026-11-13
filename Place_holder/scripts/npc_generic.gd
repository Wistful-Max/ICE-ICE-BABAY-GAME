extends CharacterBody3D
class_name NPCGeneric

@export var destinations_array:Array[Marker3D]
@export var happy_destination:Marker3D

@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D
@onready var animation_player: AnimationPlayer = $Rembot_NPC/AnimationPlayer
@onready var idle_timer: Timer = $IdleTimer
@onready var debug_label_3d: Label3D = $DebugLabel3D

enum NPCState {
	IDLE,
	WALKING
}

var SPEED:float = 2.0
var current_state:NPCState
var current_destination:Marker3D

# stats
var happiness:float

func _ready() -> void:
	_set_state(NPCState.IDLE)
	happiness = randf()
	
func _set_state(new_state:NPCState) -> void:
	current_state = new_state
	
	match current_state:
		NPCState.IDLE:
			animation_player.play(["idle_1","idle_2","idle_breathing"].pick_random())
			idle_timer.start(1.0 + randf())
		NPCState.WALKING:
			if happiness > 0.0:
				animation_player.play("forward")
			else:
				animation_player.play("forward_sad")
	
func _physics_process(delta: float) -> void:
	match current_state:
		NPCState.IDLE:
			pass
		NPCState.WALKING:
			var next_path_pos:Vector3 = navigation_agent_3d.get_next_path_position()
			var new_velocity:Vector3 = global_position.direction_to(next_path_pos) * SPEED
			velocity = new_velocity
			var look_at_target:Vector3 = Vector3(next_path_pos.x,global_position.y,next_path_pos.z)
			if not global_position.is_equal_approx(look_at_target):
				look_at(look_at_target)
			
			move_and_slide()
	
	apply_stats(delta)
	debug_label_3d.text = str(happiness)
	
func _on_idle_timer_timeout() -> void:
	decide_next_state()

func decide_next_state() -> void:
	# already IDLE
	if current_state == NPCState.IDLE:
		get_new_target()
		_set_state(NPCState.WALKING)
	
func get_new_target():
	if happiness > 0.0:
		#normal behaviour
		current_destination = destinations_array.pick_random()
	else:
		# unhappy
		current_destination = happy_destination
	navigation_agent_3d.target_position = current_destination.global_position
	
func _on_navigation_agent_3d_navigation_finished() -> void:
	if current_destination == happy_destination:
		happiness = 1.0
	_set_state(NPCState.IDLE)
	
func apply_stats(delta:float):
	happiness -= delta / 20.0
