extends Node2D

@export var itemType= ""
@export var itemName = ""
@export var itemEffect = ""
@export var itemTexture: Texture

@onready var iconSprite = $Sprite2D

var schenePath: String = "res://scene/inventory_item.tscn"
var isPLayerInRange: bool = false
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not Engine.is_editor_hint():
		iconSprite.texture = itemTexture


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		iconSprite.texture = itemTexture
	
	if isPLayerInRange && Input.is_action_just_pressed("ui_add"):
		audio_stream_player.play()
		await get_tree().create_timer(0.3).timeout
		pickup_item()	
	
func pickup_item():
	var item = {
		"quantity": 1,
		"type": itemType,
		"name": itemName,
		"texture": itemTexture,
		"effect": itemEffect,
		"scene_path": schenePath
	}
	
	if Global.player:
		Global.add_item(item)
		self.queue_free()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		isPLayerInRange = true
		body.interactUiNode.visible = true


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		isPLayerInRange = false
		body.interactUiNode.visible = false
		
func set_item_data(data):
	itemType = data["type"]
	itemName = data["name"]
	itemEffect = data["effect"]
	itemTexture = data["texture"]
