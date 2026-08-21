extends CharacterBody2D

enum SkeletonState {
	walk,
	dead
}

var status : SkeletonState

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox


func _physics_process(delta: float) -> void:

	if not is_on_floor():
		velocity += get_gravity() * delta

	match status:
		SkeletonState.walk:
			walk_state(delta)
		SkeletonState.dead:
			dead_state(delta)
	move_and_slide()
	
func _ready() -> void:
	go_to_walk_state() 
	
func go_to_walk_state():
	status = SkeletonState.walk
	anim.play("walk")

func go_to_dead_state():
	status = SkeletonState.dead
	anim.play("dead")
	hitbox.process_mode = Node.PROCESS_MODE_DISABLED
	
func walk_state(_delta):
	pass
	
func dead_state(_delta):
	pass
	
func take_damage():
	go_to_dead_state();
	
