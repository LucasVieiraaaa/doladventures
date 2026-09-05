extends AnimatedSprite2D


func play_particle(animation_name: String) -> void:
	animation_finished.connect(_on_animation_finished, CONNECT_ONE_SHOT)
	await get_tree().create_timer(5.0).timeout
	play(animation_name)


func _on_animation_finished() -> void:
	queue_free()
