extends Control

# --- UI Nodes ---
@onready var minus_button: Button = $VBoxContainer/Control/HBoxContainer/moins
@onready var count_label: Label = $VBoxContainer/Control/HBoxContainer/Count
@onready var plus_button: Button = $VBoxContainer/Control/HBoxContainer/plus
@onready var price_label: Label = $VBoxContainer/Control/HBoxContainer/Prix
@onready var buy_card_menu: Control = $"../BuyCard"
@onready var money_sound: AudioStreamPlayer = $"../../Son/Money"

# --- Logic Variables ---
var current_quantity := 1
var total_price := 2
var drawing_price := 3
var life_multiplication # life_multiply
var card_draw # pioche

func _ready() -> void:
	_update_labels()

func _on_moins_pressed() -> void:
	price_label.modulate = Color(1.0, 0.647, 0.0) # Orange
	if current_quantity >= 2:
		current_quantity -= 1
		total_price -= 1
		_update_labels()

func _on_plus_pressed() -> void:
	# Check if player has enough money via Global
	if current_quantity <= 2 && total_price < DatabaseConfig.local_money:
		price_label.modulate = Color(1.0, 0.647, 0.0) 
		current_quantity += 1
		total_price += 1
		_update_labels()
	else:
		price_label.modulate = Color.RED

func _update_labels() -> void:
	count_label.text = str(current_quantity)
	price_label.text = str(total_price)

func _on_bank_buy_card_pressed() -> void:
	var player_id = DatabaseConfig.current_profile_id
	print("Bank: Attempting purchase of ", current_quantity, " health for ", total_price, " gold by Profile ", player_id)
	
	var success = DatabaseConfig.spend_money(total_price, player_id)

	if success:
		money_sound.play()
		print("Bank: Purchase validated for profile ", player_id)
		# Add life points
		DatabaseConfig.get_life(current_quantity, player_id)
		
		# Record turn action
		DatabaseConfig.actions_done += 1
		
		# Check turn limit
		if DatabaseConfig.script_general:
			DatabaseConfig.script_general.check_action_limit()
	else:
		DatabaseConfig.notify_error("Achat échoué ! Vous n'avez pas assez d'argent")
		price_label.modulate = Color.RED

func _on_get_card_pressed() -> void:
	var player_id = DatabaseConfig.current_profile_id
	buy_card_menu.show()
	
	# Attempt to spend money for drawing a card
	card_draw = DatabaseConfig.spend_money(drawing_price, player_id)
	money_sound.play()
	
	# Record turn action
	DatabaseConfig.actions_done += 1
	
	# Check turn limit
	if DatabaseConfig.script_general:
		DatabaseConfig.script_general.check_action_limit()

func _on_close_pressed() -> void:
	buy_card_menu.hide()

# --- Interface update for DatabaseConfig ---
func update_interface():
	_update_labels()
