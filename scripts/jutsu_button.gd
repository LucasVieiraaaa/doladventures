extends TextureButton

@onready var cooldown: TextureProgressBar = $Cooldown
@onready var key: Label = $Key
@onready var time: Label = $Time
@onready var timer: Timer = $Timer
	
var jutsu = null
	
var change_key = "":
	set(value):
		change_key =  value
		key.text = value
		shortcut = Shortcut.new()
		var input_key = InputEventKey.new()
		input_key.keycode = value	.unicode_at(0)
		
		shortcut.events = [input_key]
		
func _ready():
	change_key = "Q"
	cooldown.max_value = timer.wait_time
	set_process(false)
	
func _process(_delta: float):
		time.text = "%3.1f" % timer.time_left
		cooldown.value = timer.time_left


func _on_pressed() -> void:
	#if jutsu != null:
		#jutsu.
	timer.start()
	disabled = true
	set_process(true)


func _on_timer_timeout() -> void:
	disabled = false
	time.text = ""
	cooldown.value = 0
	set_process(false)
