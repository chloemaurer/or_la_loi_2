extends Control

# --- UI Nodes ---
@onready var end_minigame_sound: AudioStreamPlayer = $"../../Son/FinMiniJeux" # fin_mini_jeux
@onready var minigame_sound: AudioStreamPlayer = $"../../Son/Minijeux"

@onready var winner_icons = [
	$"Control/VBoxContainer/1er/Icon", 
	$"Control/VBoxContainer/2eme/Icon", 
	$"Control/VBoxContainer/3eme/Icon", 
	$"Control/VBoxContainer/4eme/Icon"
]

@onready var winner_times = [
	$"Control/VBoxContainer/1er/Time", 
	$"Control/VBoxContainer/2eme/Time", 
	$"Control/VBoxContainer/3eme/Time", 
	$"Control/VBoxContainer/4eme/Time"
]

func _ready() -> void:
	self.hide()

# This function is called by the Minigame Controller once all scores are in
func show_results(raw_scores: Array): # afficher_resultats
	minigame_sound.stop()
	end_minigame_sound.play()
	
	# 1. Safety check
	if raw_scores.is_empty(): 
		return
	
	# 2. Sort scores (from lowest time to highest)
	# Using "time" key from the dictionaries sent by DatabaseConfig
	raw_scores.sort_custom(func(a, b): return float(a["temps"]) < float(b["temps"]))
	
	# 3. Update the display nodes
	for i in range(winner_icons.size()):
		if i < raw_scores.size():
			var data = raw_scores[i]
			
			var player_id = int(data["id"])
			var player_time = float(data["temps"])
			
			# Display time formatted to 2 decimals
			winner_times[i].text = "%.2f" % player_time + "s"
			
			# Fetch the player's icon from main profile nodes
			var profile_nodes = DatabaseConfig.script_general.profile_nodes
			if player_id < profile_nodes.size():
				var source_profile = profile_nodes[player_id]
				
				if is_instance_valid(source_profile):
					# Look for the sprite in the player's profile node
					var sprite = source_profile.get_node_or_null("PlayerIcon/Personnage")
					if sprite:
						winner_icons[i].texture = sprite.texture
			
			winner_icons[i].get_parent().show()
		else:
			winner_icons[i].get_parent().hide()

	self.show()

func _on_fin_mini_jeu_pressed() -> void:
	# Emit the global reward signal with the final score data
	DatabaseConfig.rewards_received.emit(DatabaseConfig.scores_data)
	self.hide()
