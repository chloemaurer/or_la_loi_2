extends Control

# --- UI Nodes ---
@onready var minus_button: Button = $VBoxContainer/HBoxContainer/moins
@onready var count_label: Label = $VBoxContainer/HBoxContainer/Count
@onready var plus_button: Button = $VBoxContainer/HBoxContainer/plus
@onready var price_label: Label = $VBoxContainer/HBoxContainer/Prix
@onready var money_sound: AudioStreamPlayer = $"../../Son/Money"

# --- Logic Variables ---
var current_quantity := 1
var total_price := 2
var drawing_price := 3 # Unused for now but kept for logic
var ammo_count # munition

func _ready() -> void:
	_update_labels()

func _on_moins_pressed() -> void:
	price_label.modulate = Color(1.0, 0.647, 0.0) # Orange color
	if current_quantity >= 2:
		current_quantity -= 1
		total_price -= 1
		_update_labels()

func _on_plus_pressed() -> void:
	# Check if the active player has enough money via Global config
	if current_quantity <= 2 && total_price < DatabaseConfig.local_money:
		price_label.modulate = Color(1.0, 0.647, 0.0) 
		current_quantity += 1
		total_price += 1
		_update_labels()

func _update_labels() -> void:
	count_label.text = str(current_quantity)
	price_label.text = str(total_price)

func _on_armory_buy_card_pressed() -> void:
	var current_id = DatabaseConfig.current_profile_id
	print("Armory: Attempting purchase for Profile ", current_id)
	
	# Try to spend money through Global
	var success = DatabaseConfig.spend_money(total_price, current_id)
	
	if success:
		money_sound.play()
		print("Armory: Purchase validated for profile ", current_id)
		
		# Give ammo to the player
		DatabaseConfig.get_munition(current_quantity, current_id)
		
		# Increment action count
		DatabaseConfig.actions_done += 1
		
		# Check if the turn should end (limit of 2 actions)
		if DatabaseConfig.script_general:
			DatabaseConfig.script_general.check_action_limit()
	else :
		DatabaseConfig.notify_error("Achat échoué ! Vous n'avez pas assez d'argent")

# --- Interface update for DatabaseConfig ---
func update_interface():
	# Useful if we need to refresh the display when the DB updates
	_update_labels()
