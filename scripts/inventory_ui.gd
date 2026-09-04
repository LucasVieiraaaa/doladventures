extends Control
class_name Inventory

const SCROLL_DISTANCE := 45.0
const OPEN_TIME := 0.5
const CLOSE_TIME := 0.3

@onready var grid_container = $GridContainer
@onready var left_scroll: Sprite2D = $Sprite2D
@onready var right_scroll: Sprite2D = $Sprite2D2

var _left_closed: float
var _right_closed: float
var _tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_left_closed = left_scroll.position.x
	_right_closed = right_scroll.position.x

	visibility_changed.connect(_on_visibility_changed)

	if is_visible_in_tree():
		open()
	else:
		_snap_closed()

	Global.inventory_updated.connect(_on_inventory_updated)
	_on_inventory_updated()


func open() -> void:
	_kill_tween()
	_snap_closed()   # sempre parte do fechado, mesmo reabrindo no meio da animação
	_tween = create_tween().set_parallel(true)
	_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_tween.tween_property(left_scroll,  "position:x", _left_closed  - SCROLL_DISTANCE, OPEN_TIME)
	_tween.tween_property(right_scroll, "position:x", _right_closed + SCROLL_DISTANCE, OPEN_TIME)

func close() -> void:
	_kill_tween()
	_tween = create_tween().set_parallel(true)
	_tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	_tween.tween_property(left_scroll,  "position:x", _left_closed,  CLOSE_TIME)
	_tween.tween_property(right_scroll, "position:x", _right_closed, CLOSE_TIME)
	await _tween.finished
	hide()

func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		open()
	else:
		_snap_closed()

func _snap_closed() -> void:
	left_scroll.position.x = _left_closed
	right_scroll.position.x = _right_closed


func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()

func _on_inventory_updated():
	clear_grid_container()
	for item in Global.inventory:
		var slot = Global.inventory_slot_scene.instantiate()
		grid_container.add_child(slot)
		if item != null:
			slot.set_item(item)
		else:
			slot.set_empty_slot();

func clear_grid_container():
	while grid_container.get_child_count() > 0:
		var child = grid_container.get_child(0)
		grid_container.remove_child(child)
		child.queue_free()
