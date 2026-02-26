extends Node2D

# --- Assets ---
var icons = [
	preload("uid://bh2fl2jexuv11"), preload("uid://bigj6xlc0devs"), preload("uid://b01lqf5jf531"),
	preload("uid://cm7m7l86ey38f"), preload("uid://dmhx8f5xybayy"), preload("uid://dromh00wukg7r"),
	preload("uid://by34fmmkfdae3"), preload("uid://civ1gsrq8j33m"), preload("uid://du742y314x7w0")
]

# --- UI Nodes ---
@onready var screen: Node2D = $Screen
@onready var code_buttons: Node2D = $Code # code
@onready var back_button: Button = $Actions/Back # back
@onready var close_button: TextureButton = $CloseButton
@onready var money_sound: AudioStreamPlayer = $"../../../Son/Money" # money_song
@onready var get_resources: AudioStreamPlayer = $"../../../Son/GetResources"
@onready var minijeux: AudioStreamPlayer = $"../../../Son/Minijeux"

# --- Logic Variables ---
var current_index := 0
var input_code := "" 
var all_codes_catalog := {} # tous_les_codes
var is_mine_mode := false # mode_mine
var mine_cards_counter := 0 # compteur_mines

signal mine_completed # mine_terminee

func _ready():
	# Connect all number buttons
	for node in code_buttons.get_children():
		if node is Button:
			node.pressed.connect(_on_key_pressed.bind(node))
	
	back_button.pressed.connect(_on_back_pressed)
	close_button.pressed.connect(_on_close_button_pressed)
	close_button.hide()

# Updated by DatabaseConfig when Firebase data changes
func update_catalog(_key: String, value):
	var clean_val = func(v): return str(int(float(v))) if typeof(v) in [TYPE_FLOAT, TYPE_INT] else str(v)
	
	if typeof(value) == TYPE_DICTIONARY:
		for id_key in value.keys():
			var data = value[id_key]
			if typeof(data) == TYPE_DICTIONARY:
				all_codes_catalog[id_key] = {
					"code": clean_val.call(data.get("code", "0")),
					"effect": data.get("effet", "Unknown"),
					"category": data.get("categorie", "Unknown"),
					"is_available": data.get("disponible", true)
				}
	print("[Keypad] Catalog updated.")

func _on_key_pressed(button: Button):
	if current_index > 3: return
	var key_pressed = int(button.name)
	input_code += str(key_pressed)
	screen.get_child(current_index).texture = icons[key_pressed - 1]
	current_index += 1

func _on_back_pressed():
	if current_index <= 0: return
	current_index -= 1
	input_code = input_code.substr(0, input_code.length() - 1)
	screen.get_child(current_index).texture = null

func reset_keypad():
	while current_index > 0:
		_on_back_pressed()
	input_code = ""

func _on_check_pressed() -> void:
	check_code()

# Called by GiveCard script to allow manual closing
func prepare_keypad_for_gift():
	self.show()
	close_button.show()
	print("[Keypad] GIFT mode detected: Close button enabled.")

func _on_close_button_pressed():
	if DatabaseConfig.gift_target_id != "":
		print("[Keypad] Manual close: Action consumed.")
		_consume_action_and_quit()
	else:
		_finalize_keypad_usage()

func check_code():
	var found_card = null
	var id_to_disable = ""
	
	for id_name in all_codes_catalog:
		if str(all_codes_catalog[id_name]["code"]) == input_code:
			found_card = all_codes_catalog[id_name]
			id_to_disable = id_name
			break

	if not found_card:
		DatabaseConfig.notify_error("Le code rentré n'est pas bon")
		reset_keypad()
		return
		
	if found_card.get("is_available", true) == false:
		DatabaseConfig.notify_error("Cette carte a déjà été utilisé")
		_finalize_keypad_usage()
		return
		
	if is_zone_valid(found_card["category"]):
		print("✅ SUCCESS.")
		if is_mine_mode:
			# --- MINE LOGIC ---
			mine_cards_counter += 1
			if mine_cards_counter == 1:
				DatabaseConfig.notify_error("Première carte équipement acceptée, veillez rentrer la deuxième")
			DatabaseConfig.disable_card(id_to_disable)
			reset_keypad()
			
			if mine_cards_counter >= 2:
				print("🎉 SURVIVAL: 2 Mine cards provided.")
				_finalize_successful_mine()
			return 
			
		else:
			# --- NORMAL LOGIC ---
			apply_card(found_card["category"], found_card["effect"], id_to_disable)
			DatabaseConfig.disable_card(id_to_disable)
			_consume_action_and_quit()
	else:
		DatabaseConfig.notify_error("Mauvaise zone ! Vous ne pouvez pas utiliser cette carte ici")
		reset_keypad()

func _consume_action_and_quit():
	DatabaseConfig.actions_done += 1
	if DatabaseConfig.script_general:
		DatabaseConfig.script_general.check_action_limit()
	_finalize_keypad_usage()

func _finalize_keypad_usage():
	var was_in_mine = is_mine_mode 
	
	# Standard Reset
	is_mine_mode = false
	mine_cards_counter = 0
	DatabaseConfig.gift_target_id = "" 
	close_button.hide()
	reset_keypad()
	self.hide()

	if was_in_mine:
		DatabaseConfig.current_zone = "mine" 
	else:
		DatabaseConfig.current_zone = "" 
		
	print("[Keypad] Keypad closed. Current zone: ", DatabaseConfig.current_zone)

func is_zone_valid(category: String) -> bool:
	var player_zone = DatabaseConfig.current_zone
	if is_mine_mode:
		return category == "Mine"
		
	# Categories that work everywhere
	if category in ["vie", "argent", "MiniJeux"]: 
		return true
		
	match category:
		"Mine": return player_zone == "mine"
		"saloon": return player_zone == "saloon"
		"restaurant": return player_zone == "restaurant"
		"arme": return player_zone == "armurerie"
	return false

func apply_card(category: String, effect_value, card_id: String):
	var player_id = DatabaseConfig.current_profile_id
	var effect = int(effect_value)
	
	# If gift_target_id is set, the effect goes to the target
	var final_id = DatabaseConfig.gift_target_id if DatabaseConfig.gift_target_id != "" else player_id
	
	# Show the gift popup if it's a donation to someone else
	if DatabaseConfig.gift_target_id != "" and DatabaseConfig.gift_target_id != player_id:
		if DatabaseConfig.script_don_result:
			DatabaseConfig.script_don_result.show_gift_effect(player_id, final_id, effect, category)
	
	match category:
		"MiniJeux": 
			DatabaseConfig.play_minigame(card_id)
			minijeux.play()
		"saloon": 
			DatabaseConfig.get_drink(effect, final_id)
			get_resources.play()
		"restaurant": 
			DatabaseConfig.get_food(effect, final_id)
			get_resources.play()
		"vie": 
			DatabaseConfig.get_life(effect, final_id)
			get_resources.play()
		"argent": 
			DatabaseConfig.get_money(effect, final_id)
			money_sound.play()
		"arme": 
			DatabaseConfig.update_gun(effect, final_id)

func prepare_for_mine():
	is_mine_mode = true
	mine_cards_counter = 0
	close_button.hide() # Cannot escape the mine!
	self.show()
	print("[Keypad] MINE MODE: Sacrifice 2 cards!")
	
func _finalize_successful_mine():
	is_mine_mode = false
	mine_cards_counter = 0
	mine_completed.emit()
	_finalize_keypad_usage()
