extends CharacterBody2D

enum PlayerState {
	idle,
	walk,
	jump,
	duck,
	fall,
	slide,
	dead,
	wall,
	attack,
	jutsu
}

#Health

signal health_change()
@export var maxHealth = 3
@export var health: int = 3 :
	set(value):
		health = value
		
var whatHitYou: String

#Charcter Information
signal name_character

@export var nameDisplay: String = "Naruto Uzumaki":
	set(value):
		nameDisplay = value
		name_character.emit()
#Steps
var step_timer := 0.0
var step_interval := 0.5

#Player Sounds
@onready var kage_bunshin: AudioStreamPlayer = $Sounds/KageBunshin
@onready var bunshin: AudioStreamPlayer = $Sounds/Bunshin
@onready var damage_01: AudioStreamPlayer = $Sounds/Damage_01
@onready var damage_02: AudioStreamPlayer = $Sounds/Damage_02
@onready var foot_step: AudioStreamPlayer = $MoveSounds/FootStep
@onready var jump: AudioStreamPlayer = $MoveSounds/Jump
@onready var hurt_sound: AudioStreamPlayer = $HurtSounds/HurtSound
@onready var died_soud: AudioStreamPlayer = $HurtSounds/DiedSoud
var isAudioPlaying: bool = false;

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var reload_timer: Timer = $ReloadTimer
@onready var hitbox_collision_shape: CollisionShape2D = $Hitbox/CollisionShape2D

@onready var water_detector: RayCast2D = $WaterDetector
@onready var left_wall_detector: RayCast2D = $LeftWallDetector
@onready var right_wall_detector: RayCast2D = $RightWallDetector

@onready var attack_area_shape: CollisionShape2D = $AttackArea/CollisionShape2D

const PLAYER_CLONE = preload("uid://hu2rp4qv7ngl")
var clone_spawn_direction: int = 0

@export var max_speed = 100.0
@export var acceleration = 400
@export var deceleration = 500
@export var slide_deceleration = 100
@export var wall_acceleration = 40
@export var wall_jump_vellocity = 240

const JUMP_VELOCITY = -285.0

var jump_count = 0
@export var max_jump_count = 2
var direction = 0
var status: PlayerState
var isDead = false

#Combo Variables
var combo_step: int = 0
var combo_buffered: bool = false 

#Bushin Variables
var bushin_combo: int = 0
@export var bushin_max_combo: int = 4
var isMakingClones: bool = false

func _ready() -> void:
	anim.animation_finished.connect(_on_animation_finished)
	go_to_idle_state()

func _physics_process(delta: float) -> void:
	match status:
		PlayerState.idle:
			idle_state(delta)
		PlayerState.walk:
			walk_state(delta)
		PlayerState.jump:
			jump_state(delta)
		PlayerState.fall:
			fall_state(delta)
		PlayerState.duck:
			duck_state(delta)
		PlayerState.slide:
			slide_state(delta)
		PlayerState.wall:
			wall_state(delta)
		PlayerState.dead:
			dead_state(delta)
		PlayerState.attack:
			attack_state(delta)
		PlayerState.jutsu:
			jutsu_state(delta)
		
	if direction != 0 and is_on_floor():
		step_timer -= delta

		if step_timer <= 0:
			foot_step.play()
			step_timer = step_interval
	else:
		step_timer = 0.0	
			
	move_and_slide()

func go_to_idle_state():
	if isDead:
		return
	status = PlayerState.idle
	combo_step = 0
	combo_buffered = false
	disable_attack_hitbox()
	anim.play("idle")
	
func go_to_attack_state():
	status = PlayerState.attack
	combo_step = 1
	combo_buffered = false
	velocity.x = 0
	anim.play("attack_1")
	enable_attack_hitbox()
	
func enable_attack_hitbox():
	attack_area_shape.disabled = false

func disable_attack_hitbox():
	attack_area_shape.set_deferred("disabled", true)
	
func go_to_walking_state():
	status = PlayerState.walk
	anim.play("walk")
	
func go_to_jump_state():
	status = PlayerState.jump
	anim.play("jump")
	jump.play()
	velocity.y = JUMP_VELOCITY
	jump_count += 1
	
func go_to_fall_state():
	status = PlayerState.fall
	anim.play("fall")
	
func go_to_duck_state():
	status = PlayerState.duck
	anim.play("duck")
	set_small_collider()
	
func go_to_slide_state():
	status = PlayerState.slide
	anim.play("slide")
	set_small_collider()
	
func exit_from_slide_state():
	set_larger_collider()
	
func go_to_wall_state():
	status = PlayerState.wall
	anim.play("wall")
	velocity = Vector2.ZERO
	jump_count = 0

func go_to_jutsu_state():
	bushin_combo += 1;
	
	if bushin_combo < bushin_max_combo:
		if !isAudioPlaying:
			isAudioPlaying = true;
			if bushin_combo == 0 || bushin_combo == 1:
				kage_bunshin.play()
				bunshin.play()
				isAudioPlaying = false;
			else:
				bunshin.play()
				isAudioPlaying = false;
			
		
		status = PlayerState.jutsu
		velocity.x = 0 
		anim.play("jutsu")
		spawn_clone() 
	elif bushin_combo == bushin_max_combo:
		await get_tree().create_timer(2.0).timeout
		bushin_combo = 0;

func exit_from_duck_state():
	set_larger_collider()
	
func go_to_dead_state():
	getDamage()

	if not isDead && health == 0:
		status = PlayerState.dead
		velocity.x = 0
		isDead = true
		killHitBox()
		died_soud.play()
		anim.play("dead")
		set_small_collider()
		reload_timer.start()
	
func idle_state(delta):
	apply_gravity(delta)
	
	move(delta)

	if velocity.x != 0:
		go_to_walking_state()
		return
	
	if Input.is_action_just_pressed("attack") && is_on_floor():
		go_to_attack_state()
		return
	
	if Input.is_action_just_pressed("jump"):
		go_to_jump_state()
		return
		
	if Input.is_action_pressed("duck"):
		go_to_duck_state()
		return
		
	if Input.is_action_just_pressed("bushin_attack"):
		go_to_jutsu_state()
		return
		
		 
func walk_state(delta):
	apply_gravity(delta)
	
	move(delta)
	if velocity.x == 0:
		go_to_idle_state()
		return
	
	if Input.is_action_just_pressed("jump"):
		go_to_jump_state()
		return
	
	if Input.is_action_just_pressed("duck"):
		go_to_slide_state()
		return	
	
	if Input.is_action_just_pressed("attack"):
		go_to_attack_state()
		return
		
	if !is_on_floor():
		go_to_fall_state()
		return		
		
func jump_state(delta):
	apply_gravity(delta)
	
	move(delta)
	
	if Input.is_action_just_pressed("jump") && can_jump():
		go_to_jump_state()
		return
	
	if velocity.y > 0:
		go_to_fall_state()
		return
		
func fall_state(delta):
	apply_gravity(delta)
	
	move(delta)

	if Input.is_action_just_pressed("jump") && can_jump():
		go_to_jump_state()
		return

	if is_on_floor():
		foot_step.play()
		jump_count = 0
		if velocity.y == 0:
			go_to_idle_state()
		else:
			go_to_walking_state()	
		return
	if (left_wall_detector.is_colliding() || right_wall_detector.is_colliding()) && is_on_wall():
		go_to_wall_state()
		return

func duck_state(delta):
	apply_gravity(delta)
	
	update_direction()
	
	if Input.is_action_just_released("duck"):
		exit_from_duck_state()
		go_to_idle_state()
		return
		
func slide_state(delta):
	velocity.x = move_toward(velocity.x, 0, slide_deceleration * delta)
	
	if Input.is_action_just_released("duck"):
		exit_from_duck_state()
		go_to_walking_state()
		return
		
	if velocity.x == 0:
		exit_from_slide_state()
		go_to_walking_state()
		return

func wall_state(delta):
	velocity.y += wall_acceleration * delta
	
	if left_wall_detector.is_colliding():
		anim.flip_h = true
		direction = 1
	elif right_wall_detector.is_colliding():
		anim.flip_h = false
		direction = -1
	else:
		go_to_fall_state()
		return
		
	if is_on_floor():
		go_to_idle_state()
		return
		
	if Input.is_action_just_pressed("jump"):
		velocity.x = wall_jump_vellocity * direction 
		go_to_jump_state()
		return

func dead_state(delta):
	apply_gravity(delta)
	
func attack_state(delta: float) -> void:
	apply_gravity(delta)
	velocity.x = move_toward(velocity.x, 0, deceleration * delta)
	
	if Input.is_action_just_pressed("attack"):
		combo_buffered = true

func update_direction():
	direction = Input.get_axis("left", "right")
	if direction < 0:
		clone_spawn_direction = -1
		anim.flip_h = true
		$AttackArea.scale.x = -1
	elif direction > 0:
		anim.flip_h = false
		$AttackArea.scale.x = 1
		clone_spawn_direction = 1
		
func jutsu_state(delta: float) -> void:
	apply_gravity(delta)
	velocity.x = move_toward(velocity.x, 0, deceleration * delta)

func move(delta):
	if isDead:
		return
	update_direction()
	if direction:
		velocity.x = move_toward(velocity.x, direction * max_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)
			
func can_jump() -> bool:
	return jump_count < max_jump_count
	
func set_small_collider():
	collision_shape.shape.radius = 5
	collision_shape.shape.height = 5
	collision_shape.position.y = 7	
	
	hitbox_collision_shape.shape.size.y = 4
	hitbox_collision_shape.position.y = 5
	
func set_larger_collider():
	collision_shape.shape.radius = 6
	collision_shape.shape.height = 16
	collision_shape.position.y = -2	
	
	hitbox_collision_shape.shape.size.y = 15
	hitbox_collision_shape.position.y = 0.5
	
func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("Enemies"):
		hit_enemy(area)
	elif area.is_in_group("LethalArea"):
		whatHitYou = area.name
		hit_lethal_area()
		
func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("LethalArea"):
		status = PlayerState.dead
		whatHitYou = body.name
		go_to_dead_state()
	
func hit_enemy(area: Area2D):
	if velocity.y > 0:
		area.get_parent().take_damage()
		#go_to_jump_state()
		damage_02.play()
		anim.play("air_attack")
		velocity = Vector2.ZERO
		pass
	else:
		pass

func hit_lethal_area():
	go_to_dead_state()

func _on_reload_timer_timeout() -> void:
	set_larger_collider()
	get_tree().reload_current_scene()

func apply_gravity(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if water_detector.is_colliding():
		pass
		
func getDamage():
	if health > 0:
		hurt_sound.play()
		anim.play("damage")
		velocity = Vector2.ZERO
		
	match self.whatHitYou:
		"Shuriken":
			health -= 1
			health_change.emit()
		"Lava":
			health -= health
			health_change.emit()
			
	await get_tree().create_timer(0.5).timeout
	go_to_idle_state()
			
func killHitBox():
	hitbox_collision_shape.shape.size.y = 0
	hitbox_collision_shape.position.y = 0
	
func _on_animation_finished() -> void:
	if status == PlayerState.attack:
		if combo_step > 0 && combo_step <= 2:
			damage_01.play()
		elif combo_step == 3:
			damage_02.play()
		
		if combo_buffered:
			if combo_step == 1:
				combo_step = 2
				combo_buffered = false
				anim.play("attack_2")
			elif combo_step == 2:
				combo_step = 3
				combo_buffered = false
				anim.play("attack_3")
			elif combo_step == 3:
				damage_02.play()
				go_to_idle_state()
			else:
				go_to_idle_state()
		else:
			go_to_idle_state()
			
	elif status == PlayerState.jutsu:
		go_to_idle_state() 


func _on_attack_area_area_entered(area: Area2D) -> void:
	var entity = area.get_parent()
	if entity.has_method("take_damage"):
		entity.take_damage()
		
func spawn_clone():
	if bushin_combo <= bushin_max_combo:
		var clone = PLAYER_CLONE.instantiate()
		get_parent().add_child(clone)
		clone.setup_direction(clone_spawn_direction)
		var facing_dir = direction
		if facing_dir == 0:
			facing_dir = -1 if anim.flip_h else 1
	
		clone.global_position = global_position + Vector2(25 * facing_dir, 0)
		clone.set_direction(facing_dir)

		
