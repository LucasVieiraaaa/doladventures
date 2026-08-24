extends Node2D

@onready var animation_player: AnimationPlayer = $Control/AnimationPlayer

func _ready() -> void:
	# Fade-in da tela
	animation_player.play("Fade In")
	await animation_player.animation_finished
	
	# Mantém a logo na tela por 6 segundos
	await get_tree().create_timer(6.0).timeout
	
	# Fade-out da tela
	animation_player.play("Fade Out")
	await animation_player.animation_finished
	
	# Troca para o menu
	get_tree().change_scene_to_file("res://scene/title_screen.tscn")
