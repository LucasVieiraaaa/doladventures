extends Control

@onready var animation_player: AnimationPlayer = $AnimationPlayer
var music = preload("res://audios/疾風伝_spotdown.org.mp3")

func _ready() -> void:
	AudioManager.play_music(music)
	# Fade-in da tela
	animation_player.play("Fade In")
	await animation_player.animation_finished
	await get_tree().create_timer(0.5).timeout
	
	# Fade-out da tela
	animation_player.play("Fade Out")
	await animation_player.animation_finished
	
	# Troca para o menu
	get_tree().change_scene_to_file("res://scene/title_screen.tscn")
