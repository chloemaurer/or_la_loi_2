extends Control

# --- UI Nodes ---
@onready var slots = [
	{"rect": $VBoxContainer/Joueurs/Joueurs/Joueur1, "label": $VBoxContainer/Joueurs/Joueurs/Joueur1/Nomjoueur1},
	{"rect": $VBoxContainer/Joueurs/Joueurs/Joueur2, "label": $VBoxContainer/Joueurs/Joueurs/Joueur2/Nomjoueur2},
	{"rect": $VBoxContainer/Joueurs/Joueurs/Joueur3, "label": $VBoxContainer/Joueurs/Joueurs/Joueur3/Nomjoueur3}
]

# --- Logic Variables ---
var chosen_target_id : String = "" # cible_choisie_id


func fill_selection(all_profiles: Array, my_current_id: String) -> void:
	var slot_index = 0
	chosen_target_id = "" # Reset previous selection

	# 1. Hide all slots initially
	for s in slots:
		s.rect.hide()

	# 2. Loop through the profiles
	for i in range(all_profiles.size()):
		var opponent_id = str(i)
		
		# Skip self
		if opponent_id == my_current_id:
			continue
		
		if slot_index < slots.size():
			var current_slot = slots[slot_index]
			var profile_data = all_profiles[i]
			
			# --- SET PLAYER NAME ---
			current_slot.label.text = profile_data.player_name.text
			
			# --- SET PLAYER ICON ---
			if profile_data.player_icon and profile_data.player_icon.texture:
				current_slot.rect.texture = profile_data.player_icon.texture
			else:
				# Security fallback
				current_slot.rect.texture = profile_data.characters[i]["sprite"]

			# --- INPUT HANDLING ---
			if current_slot.rect.gui_input.is_connected(_on_opponent_clicked):
				current_slot.rect.gui_input.disconnect(_on_opponent_clicked)
			current_slot.rect.gui_input.connect(_on_opponent_clicked.bind(slot_index))
			
			# --- METADATA AND VISUALS ---
			current_slot.rect.set_meta("player_id", opponent_id)
			
			# Match profile modulation (transparency if dead)
			current_slot.rect.modulate = profile_data.modulate
			current_slot.rect.show()
			slot_index += 1

func _on_opponent_clicked(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		var clicked_slot = slots[index]
		
		if clicked_slot.rect.has_meta("player_id"):
			var new_target = str(clicked_slot.rect.get_meta("player_id"))
	
			# 1. RESET: Remove shader outline from all slots
			for slot in slots:
				var tr : TextureRect = slot.rect
				if tr.material is ShaderMaterial:
					tr.material.set("shader_parameter/thickness", 0.0)

			# 2. TOGGLE LOGIC
			if chosen_target_id == new_target:
				chosen_target_id = "" # Deselect
				print("[GiveCard] Selection canceled.")
			else:
				# Select and show outline
				chosen_target_id = new_target
				var texture_rect : TextureRect = clicked_slot.rect
				if texture_rect.material is ShaderMaterial:
					texture_rect.material.set("shader_parameter/thickness", 5.0)
		
			print("[GiveCard] Target chosen = ", chosen_target_id)

func _on_give_card_pressed() -> void:
	if chosen_target_id == "":
		DatabaseConfig.notify_error("Selectionner un adversaire d'abord")
		return
	
	# Verify if target is still alive
	var target_idx = int(chosen_target_id)
	if DatabaseConfig.script_general.profile_nodes[target_idx].get_life() <= 0:
		DatabaseConfig.notify_error("Ce joueur est mort vous ne pouvez pas l'affronter")
		return

	# 1. Register ID in Singleton
	DatabaseConfig.gift_target_id = chosen_target_id
	print("[GiveCard] Target registered: ", DatabaseConfig.gift_target_id)
	
	# 2. Close menu and open Keypad
	self.hide()
	
	var main_script = DatabaseConfig.script_general
	main_script._open_current_keypad() 

	# 3. Prepare keypad for giving mode
	var player_id = int(DatabaseConfig.current_profile_id)
	if main_script.keypads.size() > player_id:
		main_script.keypads[player_id].prepare_keypad_for_gift()
	
	# 4. RESET visuals for next time
	_reset_selection_visuals()

func _reset_selection_visuals():
	chosen_target_id = ""
	for slot in slots:
		var tr : TextureRect = slot.rect
		if tr.material is ShaderMaterial:
			tr.material.set("shader_parameter/thickness", 0.0)
