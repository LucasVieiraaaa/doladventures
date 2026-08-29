extends CharacterBody2D

@export var speed: float = 100.0
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
const JUMP_VELOCITY = -320.0

#Clone Sounds
@onready var poof: AudioStreamPlayer = $Sounds/Poof
@onready var foot_step: AudioStreamPlayer = $MoveSounds/FootStep
@onready var jump: AudioStreamPlayer = $MoveSounds/Jump
@onready var damage_01: AudioStreamPlayer = $Sounds/Damage_01
@onready var ground_detector: RayCast2D = $GroundDetector

#Steps
var step_timer := 0.0
var step_interval := 0.5

#Rays
@onready var wall_detector: RayCast2D = $WallDetector
var touching_wall := false

var direction: int = 1
var isBushinOver: bool = false
var isAttacking: bool = false
var isInitializing: bool = true
var isHelpingRasegan: String = ""
var buhsinTimeOut: float = randf_range(1.5, 4.5)
var xpCloneGained: int = 0
		
signal bushin_destroyed(xp: int)

func _ready() -> void:		
	if(isHelpingRasegan == ""):
		isInitializing = true
		anim.play("init")
		velocity = Vector2.ZERO
		await get_tree().create_timer(0.5).timeout
		isInitializing = false
		await get_tree().create_timer(buhsinTimeOut).timeout
		if isBushinOver == false:
			destroy_bushin(false)
	elif isHelpingRasegan == "regular_rasengan":
		helpingRegularRasengan()
		return
	elif  isHelpingRasegan == "odama_rasengan":
		helpingOdamaRasengan()
		return
		
func helpingRegularRasengan():
	anim.play("init")
	velocity = Vector2.ZERO
	await get_tree().create_timer(0.5).timeout
	anim.play("help_rasengan")
	await get_tree().create_timer(2.0).timeout
	destroy_bushin(true)
	
func helpingOdamaRasengan():
	anim.play("init")
	velocity = Vector2.ZERO
	await get_tree().create_timer(0.4).timeout
	anim.play("help_odama_rasengan")
	await get_tree().create_timer(2.0).timeout
	destroy_bushin(true)

func _physics_process(delta: float) -> void:
	if  !isBushinOver && !isAttacking && !isInitializing:
		if not is_on_floor():
			velocity += get_gravity() * delta

		velocity.x = speed * direction
		cloneInitializeMoves()
			
		if direction != 0 and is_on_floor():
			step_timer -= delta

			if step_timer <= 0:
				foot_step.play()
				step_timer = step_interval
		else:
			step_timer = 0.0	
		
		if ground_detector.is_colliding():
			var collider = ground_detector.get_collider()
			if collider.name.to_lower() == "lava":
				destroy_bushin(true)
		
		move_and_slide()
		
func cloneInitializeMoves():
	if velocity.y > 0.1:
		if not is_on_floor() && isInitializing:
			anim.play("init")
			await get_tree().create_timer(0.3).timeout
			anim.play("air_attack")
		else:
			anim.play("fall")
	else:
		anim.play("walk")
		if wall_detector.is_colliding():
			if not touching_wall:
				touching_wall = true
				wallInteraction()
		else:
			touching_wall = false;

func set_direction(dir: int) -> void:
	direction = dir
	if direction < 0:
		anim.flip_h = true
	else:
		anim.flip_h = false

# Quando a Hitbox do Clone entra na Hitbox/Area2D do Esqueleto
func _on_hitbox_area_entered(area: Area2D) -> void:
	print(area)
	_try_damage_entity(area)
	_try_damage_entity(area.get_parent())

# Quando o Clone colide com o corpo físico (CharacterBody2D) do Esqueleto"volume_db"
func _on_hitbox_body_entered(_body: Node2D) -> void:
	make_clone_jump()
	return

# Função auxiliar para aplicar o dano e eliminar o clone
func _try_damage_entity(node: Node) -> void:
	if node == null:
		isAttacking = false;
		return
	
	if node != null && node.name.length() > 0:
		beenHit(node.name)
	
	if node.has_method("is_dead") and node.is_dead():
		isAttacking = false;
		return
	
	if (node.has_method("take_damage") && !isBushinOver):
		damage_01.play()
		if velocity.y == 0:
			anim.play("attack_1")
		else:
			if not is_on_floor() && isInitializing:
				anim.play("init")
				await get_tree().create_timer(0.3).timeout
				anim.play("air_attack")
			else:
				anim.play("air_attack")
		
		node.take_damage(5)
		isAttacking = true;
		whatKindOfNodeCloneHit(node)		
		await get_tree().create_timer(0.7).timeout
		isAttacking = false;
		isBushinOver = true;
		destroy_bushin(true)
		
func make_clone_jump():
	if (velocity.y == 0):
		anim.play("jump")
		jump.play()
		velocity.y = JUMP_VELOCITY

func destroy_bushin(didSomething: bool):
	isBushinOver = true
	isHelpingRasegan = ""

	poof.play()
	if didSomething:
		anim.play("dead2")
	else:
		anim.play("dead")
	velocity = Vector2.ZERO

	if xpCloneGained > 0:
		bushin_destroyed.emit(xpCloneGained)

	await get_tree().create_timer(0.7).timeout
	xpCloneGained = 0
	queue_free()
	
func wallInteraction() -> void:
	direction *= -1
	wall_detector.target_position.x = abs(wall_detector.target_position.x) * direction
	anim.flip_h = direction < 0
	
func setup_direction(new_direction: int) -> void:
	direction = sign(new_direction)
	
	wall_detector.target_position.x = abs(wall_detector.target_position.x) * direction
	
	anim.flip_h = direction < 0
	
func isHelpingRasengan(isHelping: String):
	isHelpingRasegan = isHelping
	return
	
func beenHit(hitbox: String):
	match hitbox:
		"Shuriken":
			destroy_bushin(true)
			
func whatKindOfNodeCloneHit(node: Node) -> void:
	if not node.is_in_group("Enemies"):
		return

	if not node.has_method("xpGiveAway"):
		return

	var xp: int = node.xpGiveAway()
	xpCloneGained = xp
