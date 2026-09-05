extends CharacterBody2D

enum SkeletonState {
	walk,
	dead,
	attack
}

const shuriken = preload("uid://rprq2p5g3r0w")

var status : SkeletonState

var entitieName = "Skeleton"

const SPEED = 20.0
const JUMP_VELOCITY = -400.0
var direction = 1
var can_throw = true


@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var wall_detector: RayCast2D = $WallDetector
@onready var ground_detector: RayCast2D = $GroundDetector
@onready var player_detector: RayCast2D = $PlayerDetector
@onready var player_is_protected_detector: RayCast2D = $PlayerIsProtectedDetector
@onready var bone_start_position: Node2D = $BoneStartPosition
@onready var shuriken_throw_sound: AudioStreamPlayer = $Audios/ShurikenThrowSound

@export var stats: Stats

func _physics_process(delta: float) -> void:

	if not is_on_floor():
		velocity += get_gravity() * delta

	match status:
		SkeletonState.walk:
			walk_state(delta)
		SkeletonState.dead:
			dead_state(delta)
		SkeletonState.attack:
			attack_state(delta)
			
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
	velocity =  Vector2.ZERO
	
func walk_state(_delta):
	velocity.x = SPEED * direction
	
	if wall_detector.is_colliding() || not 	ground_detector.is_colliding():
		scale.x *= -1
		direction *= -1
		
	if player_detector.is_colliding() && ! player_is_protected_detector.is_colliding():
		go_to_attack_state()
		return
		
func dead_state(_delta):
	pass
	
func take_damage(damage: int):
	if damage > 0 && ! is_dead():
		go_to_dead_state();
		
func xpGiveAway() -> int:
	if(status == SkeletonState.dead):
		var x: int  = randi_range(5, 8)
		return x
	else:
		return 0;
	
func go_to_attack_state():
	status = SkeletonState.attack
	anim.play("attack")
	velocity = Vector2.ZERO
	can_throw = true;
	
func attack_state(_delta):
	if anim.frame == 2 && can_throw:
		throw_bone()
		can_throw = false;

func throw_bone():
	var new_bone =  shuriken.instantiate()
	new_bone.set_shuriken_name("Shuriken")
	shuriken_throw_sound.play()
	add_sibling(new_bone)
	new_bone.position = bone_start_position.global_position
	new_bone.set_direction(self.direction)

func _on_animated_sprite_2d_animation_finished() -> void:
	if anim.animation == "attack":
		go_to_walk_state()
		return

func is_dead() -> bool:
	return status == SkeletonState.dead
