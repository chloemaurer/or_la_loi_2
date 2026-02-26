extends Control

# --- UI Nodes ---
@onready var error_label: Label = $ErrorText # error_text
@onready var display_timer: Timer = $Timer # timer

func _ready():
	# Connect to the global error signal from DatabaseConfig
	DatabaseConfig.error_display_requested.connect(_show_message)

func _show_message():
	# Set the text from the global error message variable
	error_label.text = DatabaseConfig.error_message
	
	self.show()
	display_timer.start()
	
	# Fade-in Animation
	self.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2)
	
func _on_timer_timeout():
	# Fade-out Animation
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished
	self.hide()
