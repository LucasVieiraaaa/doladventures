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
	jutsu,
	rasengan
}

#Stats
@export var stats: Stats
#Health
signal health_change()
var whatHitYou: String

#Experience
signal experience_changed
var initialLevel: int = 1
@onready var level_up_icon: Sprite2D = $LevelUpIcon

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
@onready var tajuu_kage_bushin: AudioStreamPlayer = $Sounds/TajuuKageBushin
@onready var rasengan_formation: AudioStreamPlayer = $Sounds/RasenganFormation
@onready var damage_01: AudioStreamPlayer = $Sounds/Damage_01
@onready var damage_02: AudioStreamPlayer = $Sounds/Damage_02
@onready var scream_sound: AudioStreamPlayer = $MoveSounds/ScreamSound
@onready var foot_step: AudioStreamPlayer = $MoveSounds/FootStep
@onready var water_step: AudioStreamPlayer = $MoveSounds/WaterStep
@onready var jump: AudioStreamPlayer = $MoveSounds/Jump
@onready var hurt_sound: AudioStreamPlayer = $HurtSounds/HurtSound
@onready var died_soud: AudioStreamPlayer = $HurtSounds/DiedSoud
@onready var rasengan_hit: AudioStreamPlayer = $Sounds/RasenganHit
@onready var rasengan_2d: AnimatedSprite2D = $Rasengan2D
@onready var no_chakra: AudioStreamPlayer = $MoveSounds/NoChakra
@onready var shuriken_hit_sound: AudioStreamPlayer = $HurtSounds/ShurikenHitSound
@onready var shuriken_blocked_sound: AudioStreamPlayer = $MoveSounds/ShurikenBlockedSound
@onready var effect_phrase_sound: AudioStreamPlayer = $MoveSounds/EffectPhraseSound
@onready var odama_hit: AudioStreamPlayer = $Sounds/OdamaHit
@onready var level_up_sound: AudioStreamPlayer = $MoveSounds/LevelUpSound

var rasengan_on_cooldown: bool = false
var playerHitSomething: bool = false;
var isAudioPlaying: bool = false;

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var reload_timer: Timer = $ReloadTimer
@onready var hitbox_collision_shape: CollisionShape2D = $Hitbox/CollisionShape2D

#Ray Casts
@onready var water_detector: RayCast2D = $WaterDetector
@onready var left_wall_detector: RayCast2D = $LeftWallDetector
@onready var right_wall_detector: RayCast2D = $RightWallDetector

@onready var attack_area_shape: CollisionShape2D = $AttackArea/CollisionShape2D
const PLAYER_CLONE = preload("uid://hu2rp4qv7ngl")
var clone_spawn_direction: int = 0
var rasengan_direction: int = 1

@export var max_speed = 100.0
@export var acceleration = 400
@export var deceleration = 500
@export var slide_deceleration = 50
@export var wall_acceleration = 40
@export var wall_jump_vellocity = 240

const JUMP_VELOCITY = -285.0

var jump_count = 0
@export var max_jump_count = 2
var direction = 0
var status: PlayerState
var isDead = false
var beenHit = false

#Combo Variables
var combo_step: int = 0
var combo_buffered: bool = false

#Bushin Variables
var bushin_combo: float = 0
@export var bushin_max_combo: float = 2.0
var isMakingClones: bool = false
var isBushinCooldown: bool = false
var clone = PLAYER_CLONE.instantiate()

@onready var interactUiNode = $InteractUI
@onready var inventoryUI = $InventoryUI

@onready var bushin_button_jutsu: TextureButton = $QuickTabUI/JutsuBar/JutsuButton
@onready var rasengan_button_jutsu: TextureButton = $QuickTabUI/JutsuBar/JutsuButton2

#Jutsu Bar Variables


func _ready() -> void:
	# Stats Set
	stats.health = stats.base_max_health
	initialLevel = stats.level
	go_to_idle_state()
	
	# Animations set
	interactUiNode.visible = false
	rasengan_2d.visible = false
	anim.animation_finished.connect(_on_animation_finished)
	
	# Calling Global and Stats
	Global.set_player_reference(self)
	health_change.emit.call_deferred()
	experience_changed.emit.call_deferred()

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
		PlayerState.attack:
			rasengan_state(delta)
	
	if stats.level != initialLevel:
		go_to_level_up_state()
		
		
	if direction != 0 and is_on_floor():
		step_timer -= delta

		if step_timer <= 0:
			what_is_character_steping()
			step_timer = step_interval
	else:
		step_timer = 0.0
			
	move_and_slide()

func _input(event):
	if event.is_action_pressed("ui_inventory"):
		inventoryUI.visible = !inventoryUI.visible

func apply_item_effect(item):
	match item["effect"]:
		"Jump Boost":
			max_jump_count = 3
		"Health":
			stats.health += (stats.base_max_health / 10.0)
			health_change.emit()
		"Experience":
			stats.experience += 100	
		"Ramen":
			stats.health = stats.base_max_health
			health_change.emit()
		"Inventory":
			Global.increase_inventory_size(1)

func go_to_idle_state():
	rasengan_2d.visible = false
	if isDead:
		return
	status = PlayerState.idle
	combo_step = 0
	combo_buffered = false
	beenHit = false
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
	if jump_count == 0:
		anim.play("jump")
	elif jump_count >= 1:
		anim.play("double_jump")
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

func exit_from_duck_state():
	set_larger_collider()
	
func go_to_level_up_state():
	if initialLevel != stats.level:
		stats.level = initialLevel
		initialLevel = stats.level
		var tween: Tween = create_tween()
		level_up_sound.play()
		for i in range(6):
			level_up_icon.visible = true
			tween.tween_method(
				func(value):
				$AnimatedSprite2D.material.set_shader_parameter("brightness", value), 1.0,2000.0, 0.1
			)
			tween.tween_method(
				func(value):
				$AnimatedSprite2D.material.set_shader_parameter("brightness", value), 100.0,1.0, 0.1
			)
		tween.finished.connect(_flash_finished)

func _flash_finished():
	level_up_icon.visible = false
	return

func level_up_state(delta):
	apply_gravity(delta)
	move(delta)
	
func go_to_dead_state():
	getDamage()

	if not isDead && stats.health == 0:
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
	playerHitSomething = false
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
	
	if Input.is_action_just_pressed("bushin_attack_all"):
		go_to_jutsu_state("bushin_attack_all")
		return
	
	if Input.is_action_just_pressed("bushin_attack"):
		go_to_jutsu_state("bushin_attack")
		return
	
	if Input.is_action_just_pressed("odama_rasengan"):
		go_to_jutsu_state("odama_rasengan")
		return
	
	if Input.is_action_just_pressed("rasengan_normal"):
		go_to_jutsu_state("rasengan_normal")
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
		what_is_character_steping()

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
		if Input.is_action_just_released("duck"):
			exit_from_slide_state()
			go_to_walking_state()
		if Input.is_action_pressed("duck"):
			go_to_duck_state()
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
		updateRasenganPosition(-1)
		rasenganPosition(8,-4)
	elif direction > 0:
		anim.flip_h = false
		$AttackArea.scale.x = 1
		clone_spawn_direction = 1
		updateRasenganPosition(1)
		rasenganPosition(-12,-4)
	
func jutsu_state(delta: float) -> void:
	apply_gravity(delta)
	velocity.x = move_toward(velocity.x, 0, deceleration * delta)
	bushin_max_combo = (stats.level + 1)
	
	if bushin_max_combo  >= 9.0:
		bushin_max_combo = 9.0

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
	set_hitbox_size(4,5)
	
func set_hitbox_size(size: float, position: float):
	hitbox_collision_shape.shape.size.y = size
	hitbox_collision_shape.position.y = position

func set_attack_area(sizey:float, sizex:float, positiony: float, positionx: float):
	attack_area_shape.shape.size.y = sizey
	attack_area_shape.shape.size.x = sizex
	
	attack_area_shape.position.y = positiony
	attack_area_shape.position.x = positionx

func set_larger_collider():
	collision_shape.shape.radius = 6
	collision_shape.shape.height = 16
	collision_shape.position.y = -2
	set_hitbox_size(15,0.5)
	
func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("Enemies"):
		hit_enemy(area)
	elif area.is_in_group("LethalArea"):
		whatHitYou = area.objectName
		hit_lethal_area()
		
func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("LethalArea"):
		status = PlayerState.dead
		whatHitYou = body.name
		go_to_dead_state()
	
func hit_enemy(area: Area2D):
	if velocity.y > 0:
		var entity = area.get_parent()
		area.get_parent().take_damage(10)
		damage_02.play()
		xpGiveAway(entity)
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
	match self.whatHitYou:
		"Shuriken":
			if status == PlayerState.rasengan:
				shuriken_blocked_sound.play()
				return
			stats.health -= 10
			shuriken_hit_sound.play()
			health_change.emit()
			playHurt()
		"Lava":
			stats.health -= stats.health
			health_change.emit()
			playHurt()
	
func playHurt():
	anim.play("damage")
	if stats.health > 0:
		beenHit = true
		rasengan_2d.visible = false
		shakeCamera(5,0.2)
		hurt_sound.play()
		velocity = Vector2.ZERO
		await get_tree().create_timer(1.0).timeout
		go_to_idle_state()
			
func killHitBox():
	hitbox_collision_shape.shape.size.y = 0
	hitbox_collision_shape.position.y = 0

### START SIMPLE COMBO LOGIC ###

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
###END SIMPLE COMBO LOGIC ###

func _on_attack_area_area_entered(area: Area2D) -> void:
	if area != null:
		playerHitSomething = true;
	else:
		playerHitSomething = false;
	var entity = area.get_parent()
	if entity.has_method("take_damage"):
		entity.take_damage(stats.base_attack)
		xpGiveAway(entity)
		
### START BUSHIN JUTSU LOGIC ###
func spawn_clone(distance: float, isHelpingRasengan: String):
	if bushin_combo <= bushin_max_combo:
		clone = PLAYER_CLONE.instantiate()
		if isHelpingRasengan == "regular_rasengan":
			clone.isHelpingRasengan(isHelpingRasengan)
		elif isHelpingRasengan == "odama_rasengan":
			clone.isHelpingRasengan(isHelpingRasengan)

		clone.bushin_destroyed.connect(_on_bushin_destroyed)
		get_parent().add_child(clone)
		clone.setup_direction(clone_spawn_direction)
		var facing_dir = direction
		if facing_dir == 0:
			facing_dir = -1 if anim.flip_h else 1

		clone.global_position = global_position + Vector2(distance * facing_dir, 0)
		clone.set_direction(facing_dir)

func _on_bushin_destroyed(xp: int) -> void:
	if xp <= 0:
		return
	stats.experience += xp
	
func regularBushinJutsu():
	if bushin_combo < bushin_max_combo && !isBushinCooldown:
		bushin_combo += 1;
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
		spawn_clone(25, "")
	
	if (bushin_combo == bushin_max_combo) && !isBushinCooldown:
		isBushinCooldown = true
		bushin_button_jutsu.recieve_signal(KEY_Q, 3.5);
		await get_tree().create_timer(3.5).timeout
		isBushinCooldown = false
		bushin_combo = 0;
	
	if isBushinCooldown:
		no_chakra.play()
		return
		
func allBushinJutsu():
	if bushin_combo == bushin_max_combo:
		no_chakra.play()
	
	if bushin_combo == 0 && !beenHit && !isDead:
		bushin_combo = bushin_max_combo
		tajuu_kage_bushin.play()
		status = PlayerState.jutsu
		anim.play("jutsu")
		anim.pause()
		
		var timer = get_tree().create_timer(2.5)

		while timer.time_left > 0:
			if beenHit:
				tajuu_kage_bushin.stop()
				bushin_combo = 0
				go_to_idle_state()
				return
			await get_tree().process_frame
		
		for i in range(bushin_max_combo * 1.5):
			var offset: float = floor((i / 2.0 + 1) * 20)
			if i % 2 == 0:
				offset *= -1
			if !beenHit && !isDead:
				spawn_clone(offset, "")
			else:
				return
		go_to_idle_state()
		bunshin.volume_db = 16.0
		bunshin.play()

		bunshin.volume_db = -16.0
		bushin_button_jutsu.recieve_signal(KEY_Q, 12.0);
		await get_tree().create_timer(12.0).timeout
		bushin_combo = 0;

func go_to_jutsu_state(jutsu: String):
	match jutsu:
		"bushin_attack":
			regularBushinJutsu()
			return
		"bushin_attack_all":
			allBushinJutsu()
			return
		"odama_rasengan":
			odamaRasengan()
			return
		"rasengan_normal":
			regularRasengan()
			return
			
### END BUSHIN JUTSU LOGIC ###

func what_is_character_steping() -> void:
	if status != PlayerState.slide && status != PlayerState.duck:
		if water_detector.is_colliding():
			water_step.play()
		else:
			foot_step.play()
	
### START RASENGAN ###

func rasengan_state(delta):
	apply_gravity(delta)

func go_to_rasengan_state():
	status = PlayerState.rasengan

func regularRasengan():
	
	if rasengan_on_cooldown:
		no_chakra.play()
		return
	else:
		go_to_rasengan_state()
		
	rasengan_on_cooldown = true
	if !beenHit && !isDead:
		playRasenganStartAnimation()
		if beenHit || isDead:
			finishRasengan(5.0)
		await get_tree().create_timer(2.0).timeout
		moveWithRasengan("regular_rasengan")
		await get_tree().create_timer(2.0).timeout
		if rasengan_direction == 1.0:
			rasenganPosition(-12,-7)
		elif rasengan_direction == -1.0:
			rasenganPosition(8,-7)
	else:
		go_to_idle_state()

	rasengan_button_jutsu.recieve_signal(KEY_Q, 5.0);
	finishRasengan(5.0)
	
func finishRasengan(timer: float):
	go_to_idle_state()
	await get_tree().create_timer(timer).timeout
	rasengan_on_cooldown = false
	
func odamaRasengan():
	if rasengan_on_cooldown:
		no_chakra.play()
		return
	else:
		effect_phrase_sound.play()
		go_to_rasengan_state()
	rasengan_on_cooldown = true
		
	anim.play("odama_rasengan_init")
	
	# RESET DO TAMANHO
	rasengan_2d.scale = Vector2(0.7, 0.7)
	
	rasengan_2d.visible = true
	rasengan_2d.play("rasengan_formation")
	spawn_clone(-24, "odama_rasengan")
	
	if rasengan_direction == 1.0:
		rasenganPosition(-15,-6)
	elif rasengan_direction == -1.0:
		rasenganPosition(9,-6)
	
	rasengan_formation.play()
	await get_tree().create_timer(3.0).timeout
		
	if !beenHit && !isDead:
		if beenHit || isDead:
			finishRasengan(9.0)
		moveWithRasengan("odama_rasengan")
		await get_tree().create_timer(2.0).timeout
	else:
		go_to_idle_state()
	rasengan_button_jutsu.recieve_signal(KEY_Q, 16.0);
	finishRasengan(16.0)
		
	
func playRasenganStartAnimation():
	rasengan_2d.scale = Vector2(0.3, 0.3)
	
	anim.play("rasengan")
	await get_tree().create_timer(0.5).timeout
	bunshin.play()
	spawn_clone(-22, "regular_rasengan")
	anim.pause()
	scream_sound.play()
	rasengan_formation.play()
	rasengan_2d.play("rasengan_formation")
	rasengan_2d.visible = true
	return
	
func moveWithRasengan(rasengan: String):
	anim.play("rasengan_moving")

	if rasengan == "regular_rasengan":
		if rasengan_direction == 1.0:
			rasenganPosition(-12, -7)
		elif rasengan_direction == -1.0:
			rasenganPosition(8, -7)

	var timer = get_tree().create_timer(0.7)
	stats._damage_while_doing_jutsu(rasengan)

	while timer.time_left > 0:
		if not is_inside_tree():
			return

		acceleration = -100
		deceleration = 2000
		velocity.x = 250 * rasengan_direction
		enable_attack_hitbox()

		if playerHitSomething:
			break
		if beenHit:
			go_to_idle_state()
			audio_fade_out(rasengan_formation)
			stats._get_attack_normal_when_done_jutsu(rasengan)
			return

		await get_tree().process_frame

	acceleration = 400
	deceleration = 500

	if timer.time_left == 0 && !playerHitSomething:
		if clone != null:
			clone.isCloneActionOver(rasengan)
		stats._get_attack_normal_when_done_jutsu(rasengan)
		audio_fade_out(rasengan_formation)
		go_to_idle_state()
		return

	rasenganHitSomething(rasengan)
	velocity = Vector2.ZERO
	
func updateRasenganPosition(number: int):
	rasengan_direction = number
	return
	
func rasenganPosition(x: int ,y: int):
	rasengan_2d.position.x = x
	rasengan_2d.position.y = y
	return
	
func grow_rasengan(x: float, y: float, time: float, rasengan: String):
	rasengan_2d.scale = Vector2(1, 1)
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	match rasengan:
		"odama_rasengan":
			rasengan_2d.play("odama_colision")
		"regular_rasengan":
			rasengan_2d.play("rasengan_colision")
			
	tween.tween_property(rasengan_2d,"scale",Vector2(x, y),time)
	await tween.finished
	
func decrease_rasengan():
	rasengan_2d.scale = Vector2(1.1, 1.1)
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(rasengan_2d,"scale", Vector2(0, 0),0.5)

	await tween.finished
	rasengan_2d.visible = false
	rasengan_2d.scale = Vector2(0.4, 0.4)
	
func rasenganHitSomething(rasengan: String):
	if playerHitSomething:
		clone.isPlayerMoving = false
		if rasengan == "regular_rasengan":
			rasengan_hit.play()
			shakeCamera(18, 0.4)
			rasenganPosition(19 * rasengan_direction, -6)
			anim.play("rasengan_hit")
			anim.play("rasengan_hit_loop")
			grow_rasengan(1.1,1.1,1.0, rasengan)
		elif rasengan == "odama_rasengan":
			odama_hit.play()
			enable_attack_hitbox()
			
			set_attack_area(70,70, -14, 45)
			shakeCamera(27, 1.2)
			rasenganPosition(32 * rasengan_direction, -6)
			anim.play("rasengan_hit")
			anim.play("rasengan_hit_loop")
			grow_rasengan(1.6,1.6,1.5, rasengan)
		
		await get_tree().create_timer(1.0).timeout
		decrease_rasengan()
		audio_fade_out(rasengan_formation)
		stats._get_attack_normal_when_done_jutsu("rasengan")
		anim.play("rasengan_end")
		if rasengan == "odama_rasengan":
			set_attack_area(35,27, -5.5, 7)
		return
### END RASENGAN ###
	
### CAMERA ###
func shakeCamera(intensity: float, duration: float):
	var camera = get_viewport().get_camera_2d()
	camera.camera_shake(intensity, duration)
	
### AUDIOS ###
func audio_fade_out(player: AudioStreamPlayer, duracao: float = 3.0) -> void:
	if not player or not player.playing:
		return
		
	var tween = create_tween()
	tween.tween_property(player, "volume_db", -80.0, duracao)
	tween.finished.connect(func():
		player.stop()
		player.volume_db = 0.0
	)
	
### XP GIVE AWAY ###

func xpGiveAway(entity):
	if entity.has_method("xpGiveAway"):
		var xpGained: int = entity.xpGiveAway()
		if xpGained != 0:
			stats.experience += xpGained
			pass
