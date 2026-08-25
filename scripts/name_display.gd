extends TextEdit

@export var target: CharacterBody2D

func _ready() -> void:
	if target:
		target.name_character.connect(name_update)
		name_update()

func name_update() -> void:
	text = target.nameDisplay
	print(text)
