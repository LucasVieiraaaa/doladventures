extends AudioStreamPlayer2D

func play_music(new_stream: AudioStream) -> void:
	if stream == new_stream and playing:
		return # Se já estiver tocando a mesma música, não reinicia
		
	stream = new_stream
	play()

func stop_music() -> void:
	stop()
