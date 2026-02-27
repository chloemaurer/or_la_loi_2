extends Control

# --- UI Nodes ---
@onready var slots = [
	{"rect": $VBoxContainer/Joueurs/Joueurs/Joueur1, "label": $VBoxContainer/Joueurs/Joueurs/Joueur1/Nomjoueur1},
	{"rect": $VBoxContainer/Joueurs/Joueurs/Joueur2, "label": $VBoxContainer/Joueurs/Joueurs/Joueur2/Nomjoueur2},
	{"rect": $VBoxContainer/Joueurs/Joueurs/Joueur3, "label": $VBoxContainer/Joueurs/Joueurs/Joueur3/Nomjoueur3}
]
@onready var duel_start_sound: AudioStreamPlayer = $"../../Son/DuelStart"

# --- Logic Variables ---
var chosen_target_id : String = "" # cible_choisie_id

func fill_selection(all_profiles: Array, my_current_id: String) -> void:
	var slot_index = 0
	chosen_target_id = "" # Reset selection

	# 1. Hide all slots at start
	for s in slots:
		s.rect.hide()

	# 2. Loop through the 4 profiles
	for i in range(all_profiles.size()):
		var opponent_id = str(i)
		
		# Skip if it's the current player (can't fight yourself)
		if opponent_id == my_current_id:
			continue
		
		# Fill the 3 display slots
		if slot_index < slots.size():
			var current_slot = slots[slot_index]
			var profile_data = all_profiles[i] 
			
			# NAME: Taken from the profile label
			current_slot.label.text = profile_data.player_name.text
			
			# IMAGE: Taken from the profile's TextureRect
			if profile_data.player_icon and profile_data.player_icon.texture:
				current_slot.rect.texture = profile_data.player_icon.texture
			else:
				# Security fallback
				current_slot.rect.texture = profile_data.characters[i]["sprite"]

			# COLOR/LIFE: Match the profile's modulation (e.g., grey if dead)
			current_slot.rect.modulate = profile_data.modulate

			# SIGNAL: Clean and connect input signal
			if current_slot.rect.gui_input.is_connected(_on_opponent_clicked):
				current_slot.rect.gui_input.disconnect(_on_opponent_clicked)
			current_slot.rect.gui_input.connect(_on_opponent_clicked.bind(slot_index))
			
			# META & DISPLAY
			current_slot.rect.set_meta("player_id", opponent_id)
			current_slot.rect.show()
			
			slot_index += 1
		

func _on_opponent_clicked(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		var clicked_slot = slots[index]
		
		if clicked_slot.rect.modulate.a < 1.0: 
			DatabaseConfig.notify_error("impossible cet adversaire est mort")
			return
			
		if clicked_slot.rect.has_meta("player_id"):
			var new_target = str(clicked_slot.rect.get_meta("player_id"))
	
			# 1. RESET: Remove shader outline from everyone
			for slot in slots:
				var tr : TextureRect = slot.rect
				if tr.material is ShaderMaterial:
					tr.material.set("shader_parameter/thickness", 0.0)

			# 2. TOGGLE LOGIC: 
			if chosen_target_id == new_target:
				chosen_target_id = "" # Deselect
				print("[Duel] Selection canceled.")
			else:
				# Select new target and show outline
				chosen_target_id = new_target
				var texture_rect : TextureRect = clicked_slot.rect
				if texture_rect.material is ShaderMaterial:
					texture_rect.material.set("shader_parameter/thickness", 5.0)
		
			print("[Duel] Target chosen = ", chosen_target_id)
		else:
			print("[Duel] ERROR: Slot meta player_id missing!")

func _on_versus_pressed() -> void:
	if chosen_target_id == "":
		DatabaseConfig.notify_error("Aucun adversaire sélectionné")
		return
	
	var my_id = DatabaseConfig.current_profile_id
	duel_start_sound.play()
	
	# Start duel logic in Global
	DatabaseConfig.start_duel(my_id, chosen_target_id)
	
	# Increment action count
	DatabaseConfig.actions_done += 1
	
	# Check turn limit
	if DatabaseConfig.script_general:
		DatabaseConfig.script_general.check_action_limit()
		
	self.hide()
	chosen_target_id = ""
