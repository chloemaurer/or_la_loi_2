extends Control

@onready var panel_settings: Panel = $Panel2
@onready var bg_music: AudioStreamPlayer = $"../../BgMusic"
@onready var volume: HSlider = $Panel2/VBoxContainer/Control/Volume





func _on_button_pressed() -> void:
	panel_settings.visible = !panel_settings.visible


func _on_reset_pressed() -> void:
	DatabaseConfig.reset_game_start()


func _on_volume_value_changed(value: float) -> void:
	
	bg_music.set_volume_db(value)
