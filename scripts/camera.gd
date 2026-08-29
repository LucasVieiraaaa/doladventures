extends Camera2D

var target = Node2D

var shake_offset := Vector2.ZERO
var shake_intensity := 0.0
var shake_duration := 0.0
var shake_timer := 0.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_target()


# Called every frame.
func _process(delta: float) -> void:
	if target:
		# Posição normal da câmera + deslocamento da tremida
		position = target.position + shake_offset

	update_camera_shake(delta)


func get_target():
	var nodes = get_tree().get_nodes_in_group("Player")

	if nodes.size() == 0:
		push_error("Player not found")
		return

	target = nodes[0]


func camera_shake(intensity: float, duration: float):
	shake_intensity = intensity
	shake_duration = duration
	shake_timer = duration


func update_camera_shake(delta: float):
	if shake_timer > 0:
		shake_timer -= delta

		shake_offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
	else:
		shake_offset = Vector2.ZERO
