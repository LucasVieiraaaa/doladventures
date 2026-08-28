extends TextureProgressBar

@export var target: CharacterBody2D

func _ready() -> void:
	target.health_change.connect(health_update)
	health_update()

func health_update():
	value = target.stats.health
