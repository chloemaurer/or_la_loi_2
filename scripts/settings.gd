extends Control

# --- UI Nodes ---
@onready var settings_panel: Panel = $Panel2 # panel_settings
@onready var rules_panel: Panel = $Panel3 # panel_3
@onready var bg_music: AudioStreamPlayer = $"../../BgMusic"
@onready var volume_slider: HSlider = $Panel2/VBoxContainer/Control/Volume # volume
@onready var rules_video: VideoStreamPlayer = $"../../Animations/Rules" # rules

# --- Logic Variables ---
var stop_at_time : float = 0.0
var is_playing_section : bool = false

func _ready() -> void:
	settings_panel.hide()
	rules_panel.hide()

func _on_button_pressed() -> void:
	settings_panel.visible = !settings_panel.visible
	rules_panel.hide()

func _on_reset_pressed() -> void:
	# Calls the global reset in the Singleton
	DatabaseConfig.reset_game()

func _on_volume_value_changed(value: float) -> void:
	# Adjust background music volume (db)
	bg_music.set_volume_db(value)

func _on_video_pressed() -> void:
	rules_panel.visible = !rules_panel.visible

func _process(_delta):
	# Monitor video playback to stop at the specific timestamp
	if is_playing_section and rules_video.stream_position >= stop_at_time:
		rules_video.stop()
		rules_video.hide() # We hide the player when the section is over
		is_playing_section = false
		print("Section finished at: ", rules_video.stream_position)

# Generic function to play a specific video segment
func play_section(start: float, end: float):
	bg_music.stop()
	print("Video section started: ", start, "s to ", end, "s")
	rules_video.stream_position = start
	stop_at_time = end
	is_playing_section = true
	rules_video.show()
	rules_video.play()

# --- RULE SECTION BUTTONS ---
# Using the specific timestamps provided in your edit

func _on_vidéo_1_pressed():
	play_section(0.0, 33.0)
	bg_music.play()

func _on_vidéo_2_pressed():
	play_section(33.0, 43.0)
	bg_music.play()

func _on_vidéo_3_pressed():
	play_section(43.0, 80.0) # 01:20
	bg_music.play()

func _on_vidéo_4_pressed():
	play_section(80.0, 108.0) # 01:48
	bg_music.play()

func _on_vidéo_5_pressed():
	play_section(108.0, 200.0) # 03:20
	bg_music.play()

func _on_vidéo_6_pressed():
	play_section(200.0, 246.0) # 04:06
	bg_music.play()

func _on_vidéo_7_pressed():
	play_section(246.0, 260.0) # 04:20
	bg_music.play()

func _on_vidéo_8_pressed():
	play_section(260.0, 275.0) # 04:35
	bg_music.play()

func _on_vidéo_9_pressed():
	# Play from 04:35 until the end
	play_section(275.0, 9999.0)
	bg_music.play()
