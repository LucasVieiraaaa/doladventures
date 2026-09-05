extends TextureProgressBar

@export var target: CharacterBody2D

@onready var level_label: Label = $Label


func _ready() -> void:
	target.stats.experience_changed.connect(update_xp_bar)

	update_xp_bar()


func update_xp_bar() -> void:
	var stats = target.stats

	var current_xp: int = stats.get_xp_in_current_level()
	var xp_needed: int = stats.get_xp_needed_for_current_level()

	min_value = 0
	max_value = xp_needed
	value = current_xp

	level_label.text = str(stats.level)
