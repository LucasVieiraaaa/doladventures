extends HBoxContainer

var slots: Array
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	slots = get_children()
	slots[0].change_key = str("Q")
	slots[1].change_key = str("E")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
