extends Control

# --- Assets ---
var food_textures = [
	preload("uid://uquodl1cy3my"), preload("uid://03gr4lta6i66"),
	preload("uid://fcengsh4b1qa"), preload("uid://qiism03hwew0"), 
	preload("uid://b3wf0jsr51id"), preload("uid://wvsewo06pnvq")
]

# --- UI Nodes ---
@onready var food_roller: TextureRect = $VBoxContainer/FoodRoller
@onready var food_name_label: Label = $VBoxContainer/FoodName # food_name
@onready var food_desc_label: Label = $VBoxContainer/FoodDescription # food_description
@onready var restaurant_menu: Control = $"../Restaurant" # restaurant
@onready var money_sound: AudioStreamPlayer = $"../../Son/Money" # money_song
@onready var get_resources: AudioStreamPlayer = $"../../Son/GetResources"


# --- Logic Variables ---
var food_catalog = {} # catalogue
var current_food_id = 0 # current_id

func _ready() -> void:
	randomize_food()

# Updated by DatabaseConfig Dispatcher
func update_catalog(key: String, value):
	if key == "restaurant" and typeof(value) == TYPE_DICTIONARY:
		food_catalog = value
	else:
		food_catalog[key] = value
	
	print("Restaurant catalog updated for: ", key)
	refresh_interface()

func randomize_food() -> void:
	current_food_id = randi() % food_textures.size()
	food_roller.texture = food_textures[current_food_id]
	refresh_interface()

func refresh_interface() -> void:
	var key = "ID" + str(current_food_id)
	if food_catalog.has(key):
		var data = food_catalog[key]
		food_name_label.text = str(data.get("nom", "Unknown"))
		food_desc_label.text = "Effect: " + str(int(data.get("effet", 0)))

func process_food_purchase():
	var key = "ID" + str(current_food_id)
	if food_catalog.has(key):
		var data = food_catalog[key] 
		var food_effect = data.get("effet", 0)
		var player_id = DatabaseConfig.current_profile_id
		
		# Price is fixed at 1 gold
		var food_price = 1
		
		print("Restaurant: Attempting purchase for Profile ", player_id)
		
		# 1. Ask Singleton to spend money
		var success = DatabaseConfig.spend_money(food_price, player_id)

		if success:
			money_sound.play()
			print("Restaurant: Purchase validated. Applying effect: ", food_effect)
			# 2. Give food to the player
			DatabaseConfig.get_food(food_effect, player_id)
			get_resources.play()
		else:
			DatabaseConfig.notify_error("Achat échoué ! Vous n'avez pas assez d'argent")

func _on_food_buy_card_pressed() -> void:
	process_food_purchase()

func _on_get_food_receive_pressed() -> void:
	# Increment global action counter
	DatabaseConfig.actions_done += 1
	self.hide()
	
	# Prepare next food for the next time the shop opens
	randomize_food()
	
	# Check turn limit
	if DatabaseConfig.script_general:
		DatabaseConfig.script_general.check_action_limit()
	
	# If actions are still available (less than 2), show the main restaurant menu
	if DatabaseConfig.actions_done < 2:
		restaurant_menu.show()
