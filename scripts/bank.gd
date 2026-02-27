extends Control

# --- Noeuds UI ---
@onready var minus_button: Button = $VBoxContainer/Control/HBoxContainer/moins
@onready var count_label: Label = $VBoxContainer/Control/HBoxContainer/Count
@onready var plus_button: Button = $VBoxContainer/Control/HBoxContainer/plus
@onready var price_label: Label = $VBoxContainer/Control/HBoxContainer/Prix
@onready var buy_card_menu: Control = $"../BuyCard"
@onready var money_sound: AudioStreamPlayer = $"../../Son/Money"
@onready var get_resources: AudioStreamPlayer = $"../../Son/GetResources"

# --- Variables de Logique ---
var current_quantity := 1
var total_price := 2
var drawing_price := 3
var life_multiplication
var card_draw

func _ready() -> void:
	_update_labels()

# Gère la réduction de la quantité et du prix (minimum 1)
func _on_moins_pressed() -> void:
	price_label.modulate = Color(1.0, 0.647, 0.0) 
	if current_quantity >= 2:
		current_quantity -= 1
		total_price -= 1
		_update_labels()

# Gère l'augmentation de la quantité selon l'argent disponible (maximum 3)
func _on_plus_pressed() -> void:
	if current_quantity <= 2 && total_price < DatabaseConfig.local_money:
		price_label.modulate = Color(1.0, 0.647, 0.0) 
		current_quantity += 1
		total_price += 1
		_update_labels()
	else:
		price_label.modulate = Color.RED

# Met à jour les textes affichés à l'écran
func _update_labels() -> void:
	count_label.text = str(current_quantity)
	price_label.text = str(total_price)

# Logique d'achat de points de vie
func _on_bank_buy_card_pressed() -> void:
	var player_id = DatabaseConfig.current_profile_id
	
	# Tentative de paiement via le Singleton
	var success = DatabaseConfig.spend_money(total_price, player_id)

	if success:
		money_sound.play()
		# Ajout des points de vie et déclenchement de l'action de tour
		DatabaseConfig.get_life(current_quantity, player_id)
		get_resources.play()
		DatabaseConfig.actions_done += 1
		
		# Vérification automatique de la limite de 2 actions
		if DatabaseConfig.script_general:
			DatabaseConfig.script_general.check_action_limit()
	else:
		DatabaseConfig.notify_error("Achat échoué ! Vous n'avez pas assez d'argent")
		price_label.modulate = Color.RED

# Logique pour acheter/piocher une carte de jeu
func _on_get_card_pressed() -> void:
	var player_id = DatabaseConfig.current_profile_id
	buy_card_menu.show()
	
	# Déduction du prix de la pioche et enregistrement de l'action
	card_draw = DatabaseConfig.spend_money(drawing_price, player_id)
	money_sound.play()
	DatabaseConfig.actions_done += 1
	
	if DatabaseConfig.script_general:
		DatabaseConfig.script_general.check_action_limit()

func _on_close_pressed() -> void:
	buy_card_menu.hide()

func update_interface():
	_update_labels()
