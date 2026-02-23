extends Control

@onready var rules: VideoStreamPlayer = $"../Rules"
@onready var bg_music: AudioStreamPlayer = $"../BgMusic"


func _on_start_game_pressed() -> void:
	self.hide()
	rules.show()
	rules.play()
	


func _on_rules_finished() -> void:
	rules.hide()
	#bg_music.play()
