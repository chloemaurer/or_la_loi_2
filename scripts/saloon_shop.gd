extends Control

# --- Assets ---
var drink_textures = [
	preload("uid://bmbrqc2cdl5cj"), preload("uid://duq0qpxicvgwe"),
	preload("uid://dbk7n00v8a0jk"), preload("uid://defnlcal2s16u"),
	preload("uid://yntx2g58parc"), preload("uid://djpm3liihmd0r")
]

# --- UI Nodes ---
@onready var saloon_menu: Control = $"../Saloon" # saloon
@onready var drink_roller: TextureRect = $VBoxContainer/DrinkRoller
@onready var drink_name_label: Label = $VBoxContainer/DrinkName # drink_name
@onready var drink_desc_label: Label = $VBoxContainer/DrinkDescription # drink_description
@onready var money_sound: AudioStreamPlayer = $"../../Son/Money" # money_song

# --- Logic Variables ---
var drink_catalog = {} # catalogue
var current_drink_id = 0 # current_id

func _ready() -> void:
	randomize_drink()

# Updated by DatabaseConfig Dispatcher
func update_catalog(key: String, value):
	if key == "saloon" and typeof(value) == TYPE_DICTIONARY:
		drink_catalog = value
	else:
		drink_catalog[key] = value
	
	print("Saloon catalog updated for: ", key)
	refresh_interface()

func randomize_drink() -> void:
	current_drink_id = randi() % drink_textures.size()
	drink_roller.texture = drink_textures[current_drink_id]
	refresh_interface()

func refresh_interface() -> void:
	var key = "ID" + str(current_drink_id)
	if drink_catalog.has(key):
		var data = drink_catalog[key]
		drink_name_label.text = str(data.get("nom", "Unknown"))
		drink_desc_label.text = "Effect: +" + str(data.get("effet", 0)) + " Drink"

func process_drink_purchase():
	var key = "ID" + str(current_drink_id)
	if drink_catalog.has(key):
		var data = drink_catalog[key] 
		var drink_effect = data.get("effet", 0)
		var player_id = DatabaseConfig.current_profile_id
		
		# Price is fixed at 1 gold
		var drink_price = 1
		
		print("Saloon: Attempting purchase for Profile ", player_id)
		
		# 1. Ask Singleton to spend money
		var success = DatabaseConfig.spend_money(drink_price, player_id)
		
		if success:
			money_sound.play()
			print("Saloon: Purchase validated. Applying effect: ", drink_effect)
			# 2. Give drink to the player
			DatabaseConfig.get_drink(drink_effect, player_id)
		else:
			DatabaseConfig.notify_error("Achat échoué ! Vous n'avez pas assez d'argent")

func _on_drink_buy_card_pressed() -> void:
	process_drink_purchase()

func _on_get_drink_receive_pressed() -> void:
	# Increment global action counter
	DatabaseConfig.actions_done += 1
	self.hide()
	
	# Prepare next drink
	randomize_drink()
	
	# Check turn limit
	if DatabaseConfig.script_general:
		DatabaseConfig.script_general.check_action_limit()
	
	# If actions are still available, show the main saloon menu
	if DatabaseConfig.actions_done < 2:
		saloon_menu.show()
