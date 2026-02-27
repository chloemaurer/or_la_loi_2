extends Node2D

# --- Assets ---
# Icônes de chiffres (symboles) qui s'affichent sur l'écran du keypad
var icons = [
	preload("uid://bh2fl2jexuv11"), preload("uid://bigj6xlc0devs"), preload("uid://b01lqf5jf531"),
	preload("uid://cm7m7l86ey38f"), preload("uid://dmhx8f5xybayy"), preload("uid://dromh00wukg7r"),
	preload("uid://by34fmmkfdae3"), preload("uid://civ1gsrq8j33m"), preload("uid://du742y314x7w0")
]

# --- Noeuds UI ---
@onready var screen: Node2D = $Screen
@onready var code_buttons: Node2D = $Code
@onready var back_button: Button = $Actions/Back
@onready var close_button: TextureButton = $CloseButton
@onready var money_sound: AudioStreamPlayer = $"../../../Son/Money"
@onready var get_resources: AudioStreamPlayer = $"../../../Son/GetResources"
@onready var minijeux: AudioStreamPlayer = $"../../../Son/Minijeux"
@onready var bg_music: AudioStreamPlayer = $"../../../BgMusic"

# --- Variables de Logique ---
var current_index := 0            # Position actuelle du curseur (0 à 3)
var input_code := ""              # Code tapé par le joueur (ex: "1234")
var all_codes_catalog := {}       # Copie locale du catalogue de cartes de Firebase
var is_mine_mode := false         # Si vrai, le joueur doit donner 2 cartes pour survivre à la mine
var mine_cards_counter := 0       # Compte combien de cartes ont été données dans la mine

signal mine_completed # Émis quand le joueur a réussi à donner ses 2 cartes d'équipement

func _ready():
	# Connecte automatiquement tous les boutons numérotés
	for node in code_buttons.get_children():
		if node is Button:
			node.pressed.connect(_on_key_pressed.bind(node))
	
	back_button.pressed.connect(_on_back_pressed)
	close_button.pressed.connect(_on_close_button_pressed)
	close_button.hide()

# Mis à jour par DatabaseConfig : synchronise le catalogue des cartes avec Firebase
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

# Gère l'appui sur un chiffre
func _on_key_pressed(button: Button):
	if current_index > 3: return # Max 4 chiffres
	var key_pressed = int(button.name)
	input_code += str(key_pressed)
	# Affiche l'icône correspondante sur l'écran
	screen.get_child(current_index).texture = icons[key_pressed - 1]
	current_index += 1

# Efface le dernier chiffre tapé
func _on_back_pressed():
	if current_index <= 0: return
	current_index -= 1
	input_code = input_code.substr(0, input_code.length() - 1)
	screen.get_child(current_index).texture = null

# Remet le clavier à zéro
func reset_keypad():
	while current_index > 0:
		_on_back_pressed()
	input_code = ""

func _on_check_pressed() -> void:
	check_code()

# Prépare le clavier pour le mode "Don de carte" (permet de fermer manuellement)
func prepare_keypad_for_gift():
	self.show()
	close_button.show()

func _on_close_button_pressed():
	# Si on ferme manuellement pendant un don, cela compte quand même comme une action
	if DatabaseConfig.gift_target_id != "":
		_consume_action_and_quit()
	else:
		_finalize_keypad_usage()

# Logique principale : vérifie si le code existe et si la zone est correcte
func check_code():
	var found_card = null
	var id_to_disable = ""
	
	# Recherche le code dans le catalogue
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
		
	# Vérifie si la carte est utilisée dans la bonne zone de la carte
	if is_zone_valid(found_card["category"]):
		if is_mine_mode:
			# --- LOGIQUE MINE : il faut sacrifier 2 cartes ---
			mine_cards_counter += 1
			if mine_cards_counter == 1:
				DatabaseConfig.notify_error("Première carte acceptée, veuillez entrer la deuxième")
			DatabaseConfig.disable_card(id_to_disable)
			reset_keypad()
			
			if mine_cards_counter >= 2:
				_finalize_successful_mine()
			return 
			
		else:
			# --- LOGIQUE NORMALE : applique l'effet et consomme l'action ---
			apply_card(found_card["category"], found_card["effect"], id_to_disable)
			DatabaseConfig.disable_card(id_to_disable)
			_consume_action_and_quit()
	else:
		DatabaseConfig.notify_error("Mauvaise zone ! Vous ne pouvez pas utiliser cette carte ici")
		reset_keypad()

# Enregistre la fin de l'action et ferme le clavier
func _consume_action_and_quit():
	DatabaseConfig.actions_done += 1
	if DatabaseConfig.script_general:
		DatabaseConfig.script_general.check_action_limit()
	_finalize_keypad_usage()

# Nettoyage final du clavier après utilisation
func _finalize_keypad_usage():
	var was_in_mine = is_mine_mode 
	is_mine_mode = false
	mine_cards_counter = 0
	DatabaseConfig.gift_target_id = "" 
	close_button.hide()
	reset_keypad()
	self.hide()

	# Gère le retour à la zone normale ou mine
	if was_in_mine:
		DatabaseConfig.current_zone = "mine" 
	else:
		DatabaseConfig.current_zone = "" 

# Vérifie si le type de carte correspond au lieu où se trouve le joueur
func is_zone_valid(category: String) -> bool:
	var player_zone = DatabaseConfig.current_zone
	if is_mine_mode:
		return category == "Mine" # En mode mine, seules les cartes "Mine" fonctionnent
		
	# Ces catégories fonctionnent n'importe où
	if category in ["vie", "argent", "MiniJeux"]: 
		return true
		
	match category:
		"Mine": return player_zone == "mine"
		"saloon": return player_zone == "saloon"
		"restaurant": return player_zone == "restaurant"
		"arme": return player_zone == "armurerie"
	return false

# Applique concrètement les changements (PV, Argent, etc.) au joueur ou à sa cible
func apply_card(category: String, effect_value, card_id: String):
	var player_id = DatabaseConfig.current_profile_id
	var effect = int(effect_value)
	
	# Si gift_target_id est rempli, l'effet va à l'autre joueur (Don)
	var final_id = DatabaseConfig.gift_target_id if DatabaseConfig.gift_target_id != "" else player_id
	
	# Affiche le pop-up de don si nécessaire
	if DatabaseConfig.gift_target_id != "" and DatabaseConfig.gift_target_id != player_id:
		if DatabaseConfig.script_don_result:
			DatabaseConfig.script_don_result.show_gift_effect(player_id, final_id, effect, category)
	
	# Dispatcher d'effets selon la catégorie
	match category:
		"MiniJeux": 
			DatabaseConfig.play_minigame(card_id)
			bg_music.stop()
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

# Active le mode spécial "Mine"
func prepare_for_mine():
	is_mine_mode = true
	mine_cards_counter = 0
	close_button.hide() # Impossible de quitter la mine sans payer !
	self.show()
	
func _finalize_successful_mine():
	is_mine_mode = false
	mine_cards_counter = 0
	mine_completed.emit()
	_finalize_keypad_usage()
