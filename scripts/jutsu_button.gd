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


func _input(event: InputEvent):
	if event is InputEventKey:
		if event.pressed and not event.echo:
			if event.keycode == change_key.unicode_at(0):
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
	time.text = ""
	cooldown.value = 0
	set_process(false)
