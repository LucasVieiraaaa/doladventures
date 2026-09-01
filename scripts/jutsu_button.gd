extends TextureButton

@onready var cooldown: TextureProgressBar = $Cooldown
@onready var key: Label = $Key
@onready var time: Label = $Time
@onready var timer: Timer = $Timer

var jutsu = null

var change_key := "":
	set(value):
		change_key = value
		key.text = value


func _ready():
	tooltip_text = ""
	shortcut = null

	change_key = "Q"
	cooldown.max_value = timer.wait_time
	set_process(false)

func _process(_delta: float):
	time.text = "%3.1f" % timer.time_left
	cooldown.value = timer.time_left

func recieve_signal(key: Key, timeOut: float):

	if key == KEY_Q:
		timer.wait_time = timeOut
		cooldown.max_value = timeOut

		if not disabled:
			_on_pressed()


func _on_pressed() -> void:
	#if jutsu != null:
		#jutsu.
	timer.start()
	disabled = true
	set_process(true)


func _on_timer_timeout() -> void:
	disabled = false
	cooldown.value = 0
	set_process(false)
