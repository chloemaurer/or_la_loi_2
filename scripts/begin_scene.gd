extends Control

@onready var rules: VideoStreamPlayer = $"../Rules"


func _on_start_game_pressed() -> void:
	self.hide()
	rules.show()
	rules.play()
	


func _on_rules_finished() -> void:
	rules.hide()
