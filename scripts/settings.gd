extends Control

@onready var panel_settings: Panel = $Panel2
@onready var bg_music: AudioStreamPlayer = $"../../BgMusic"
@onready var volume: HSlider = $Panel2/VBoxContainer/Control/Volume
@onready var panel_3: Panel = $Panel3
@onready var rules: VideoStreamPlayer = $"../../Animations/Rules"

var stop_at_time : float = 0.0
var is_playing_section : bool = false


func _on_button_pressed() -> void:
	panel_settings.visible = !panel_settings.visible


func _on_reset_pressed() -> void:
	DatabaseConfig.reset_game_start()


func _on_volume_value_changed(value: float) -> void:
	bg_music.set_volume_db(value)


func _on_video_pressed() -> void:
	panel_3.visible = !panel_3.visible


func _process(_delta):
	# Si on joue une section et qu'on dépasse le temps imparti
	if is_playing_section and rules.stream_position >= stop_at_time:
		rules.stop()
		is_playing_section = false
		print("Section terminée à : ", rules.stream_position)

# Fonction générique pour lancer une section
func play_section(start: float, end: float):
	rules.stream_position = start
	stop_at_time = end
	is_playing_section = true
	rules.show()
	rules.play()

# ---  BOUTONS ---

func _on_vidéo_1_pressed():
	play_section(0.0, 33.0)

func _on_vidéo_2_pressed():
	play_section(33.0, 43.0)

func _on_vidéo_3_pressed():
	play_section(43.0, 80.0) # 01:20 = 80s

func _on_vidéo_4_pressed():
	play_section(80.0, 108.0) # 01:48 = 108s

func _on_vidéo_5_pressed():
	play_section(108.0, 200.0) # 03:20 = 200s

func _on_vidéo_6_pressed():
	play_section(200.0, 246.0) # 04:06 = 246s

func _on_vidéo_7_pressed():
	play_section(246.0, 260.0) # 04:20 = 260s

func _on_vidéo_8_pressed():
	play_section(260.0, 275.0) # 04:35 = 275s

func _on_vidéo_9_pressed():
	# Joue de 04:35 jusqu'à la fin (on met un temps très long)
	play_section(275.0, 9999.0)
	
	
