extends CharacterBody2D

@export var speed: float = 100.0
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
const JUMP_VELOCITY = -320.0

#Clone Sounds
@onready var poof: AudioStreamPlayer = $Sounds/Poof


var direction: int = 1
var isBushinOver: bool = false
var isAttacking: bool = false
var isInitializing: bool = true

func _ready() -> void:
	anim.play("init")
	velocity = Vector2.ZERO
	await get_tree().create_timer(0.5).timeout
	isInitializing = false
	# Destrói o clone após 2 segundos se ele não atingir nada
	await get_tree().create_timer(2.2).timeout
	
	if isBushinOver == false:
		destroy_bushin(false)

func _physics_process(delta: float) -> void:
	if  !isBushinOver && !isAttacking && !isInitializing:
		if not is_on_floor():
			velocity += get_gravity() * delta

		velocity.x = speed * direction
		if velocity.y > 0.1:
			anim.play("fall")
		else:
			anim.play("walk")
		move_and_slide()

func set_direction(dir: int) -> void:
	direction = dir
	if direction < 0:
		anim.flip_h = true
	else:
		anim.flip_h = false

# Quando a Hitbox do Clone entra na Hitbox/Area2D do Esqueleto
func _on_hitbox_area_entered(area: Area2D) -> void:
	print("aqui2", area)
	_try_damage_entity(area)
	_try_damage_entity(area.get_parent())

# Quando o Clone colide com o corpo físico (CharacterBody2D) do Esqueleto
func _on_hitbox_body_entered(body: Node2D) -> void:
	print("aqui123", body)
	make_clone_jump()
	_try_damage_entity(body)

# Função auxiliar para aplicar o dano e eliminar o clone
func _try_damage_entity(node: Node) -> void:
	if node == null:
		print("aqui34")
		isAttacking = false;
		return
	
	if node.has_method("is_dead") and node.is_dead():
		isAttacking = false;
		return
	
	if (node.has_method("take_damage") && !isBushinOver):
		if velocity.y == 0:
			anim.play("attack_1")
		else:
			anim.play("air_attack")
			
		node.take_damage()
		isAttacking = true;
		await get_tree().create_timer(0.7).timeout
		isAttacking = false;
		isBushinOver = true;
		destroy_bushin(true)
		
func make_clone_jump():
	if (velocity.y == 0):
		anim.play("jump")
		velocity.y = JUMP_VELOCITY

func destroy_bushin(didSomething: bool):
	isBushinOver = true
	poof.play()
	
	if(didSomething):
		anim.play("dead2")
	else:
		anim.play("dead")
		
	velocity = Vector2.ZERO
	await get_tree().create_timer(0.7).timeout
	queue_free()
	
