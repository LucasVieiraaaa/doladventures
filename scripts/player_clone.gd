extends CharacterBody2D

@export var speed: float = 100.0
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var direction: int = 1

func _ready() -> void:
	anim.play("walk")
	# Destrói o clone após 2 segundos se ele não atingir nada
	await get_tree().create_timer(2.0).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	# Aplica a gravidade nativa caso não esteja no chão
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Aplica velocidade de movimento no eixo X
	velocity.x = speed * direction

	# Executa o movimento e calcula colisão com o terreno
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
	print("aqui", body)
	_try_damage_entity(body)

# Função auxiliar para aplicar o dano e eliminar o clone
func _try_damage_entity(node: Node) -> void:
	if node == null:
		return
	
	if node.has_method("is_dead") and node.is_dead():
		return
	
	if node.has_method("take_damage"):
		node.take_damage()
		queue_free()
