extends Node2D

var icons = [preload("uid://bh2fl2jexuv11"),preload("uid://bigj6xlc0devs"),preload("uid://b01lqf5jf531"),
preload("uid://cm7m7l86ey38f"),preload("uid://dmhx8f5xybayy"),preload("uid://dromh00wukg7r"),
preload("uid://by34fmmkfdae3"),preload("uid://civ1gsrq8j33m"),preload("uid://du742y314x7w0")]

@onready var screen: Node2D = $Screen
@onready var code: Node2D = $Code
@onready var back: Button = $Actions/Back
@onready var close_button: TextureButton = $CloseButton


var current_index := 0
var input_code := "" 
var tous_les_codes := {} 
var mode_mine := false
var compteur_mines := 0
signal mine_terminee

func _ready():
	for node in code.get_children():
		if node is Button:
			node.pressed.connect(_on_key_pressed.bind(node))
	back.pressed.connect(_on_back_pressed)
	close_button.pressed.connect(_on_close_button_pressed)
	close_button.hide()

func mettre_a_jour_catalogue(cle: String, valeur):
	var clean_val = func(v): return str(int(float(v))) if typeof(v) in [TYPE_FLOAT, TYPE_INT] else str(v)
	if typeof(valeur) == TYPE_DICTIONARY:
		for id_key in valeur.keys():
			var data = valeur[id_key]
			if typeof(data) == TYPE_DICTIONARY:
				var est_dispo = data.get("disponible", true)
				if str(est_dispo) == "false": est_dispo = false
				if str(est_dispo) == "true": est_dispo = true
				tous_les_codes[id_key] = {
					"code": clean_val.call(data.get("code", "0")),
					"effet": data.get("effet", "Inconnu"),
					"categorie": data.get("categorie", "Inconnue"),
					"disponible": data.get("disponible", true)
				}
	print("[Keypad] Catalogue mis à jour.")

func _on_key_pressed(button: Button):
	if current_index > 3: return
	var keypressed = int(button.name)
	input_code += str(keypressed)
	screen.get_child(current_index).texture = icons[keypressed - 1]
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

# Appelé par le script de Don pour afficher la croix
func preparer_clavier_pour_don():
	self.show()
	close_button.show()
	print("[Keypad] Mode DON détecté : Bouton Close affiché.")

func _on_close_button_pressed():
	if DatabaseConfig.cible_don_id != "":
		print("[Keypad] Fermeture manuelle : Action consommée.")
		_consommer_action_et_quitter()
	else:
		_finaliser_utilisation_keypad()

func check_code():
	var carte_trouvee = null
	var id_a_desactiver = ""
	for id_name in tous_les_codes:
		if str(tous_les_codes[id_name]["code"]) == input_code:
			carte_trouvee = tous_les_codes[id_name]
			id_a_desactiver = id_name
			break

	if not carte_trouvee:
		DatabaseConfig.notifier_erreur("Vous vous êtes trompé de code")
		print("❌ ÉCHEC : Code inconnu.")
		reset_keypad()
		return
		
	if carte_trouvee.get("disponible", true) == false:
		DatabaseConfig.notifier_erreur("La carte a déjà été utilisé")
		print("🚫 ÉCHEC : Déjà utilisée.")
		_finaliser_utilisation_keypad()
		return
		
	
	if is_zone_valid(carte_trouvee["categorie"]):
		print("✅ SUCCÈS.")
		if mode_mine:
			# --- LOGIQUE MINE ---
			compteur_mines += 1
			DatabaseConfig.notifier_erreur("Première carte acceptée, rentrez la deuxième ")
			DatabaseConfig.disable_card(id_a_desactiver)
			reset_keypad()
			
			if compteur_mines >= 2:
				print("🎉 SURVIE : 2 cartes Mines données.")
				_finaliser_mine_reussie()
			return 
			
		else:
			# --- LOGIQUE NORMALE ---
			apply_card(carte_trouvee["categorie"], carte_trouvee["effet"], id_a_desactiver)
			DatabaseConfig.disable_card(id_a_desactiver)
			_consommer_action_et_quitter()
	else:
		DatabaseConfig.notifier_erreur("Mauvaise zone la carte ne fonctionne pas ici ")
		print("🚫 MAUVAISE ZONE : ", carte_trouvee["categorie"], " ne marche pas ici (", DatabaseConfig.zone, ")")
		reset_keypad()

	
func _consommer_action_et_quitter():
	DatabaseConfig.actions_faites += 1
	if DatabaseConfig.script_general:
		DatabaseConfig.script_general.verifier_limite_actions()
	_finaliser_utilisation_keypad()

func _finaliser_utilisation_keypad():
	# On stocke l'état avant de reset
	var etait_en_mine = mode_mine 
	
	# Reset standard
	mode_mine = false
	compteur_mines = 0
	DatabaseConfig.cible_don_id = "" 
	close_button.hide()
	reset_keypad()
	self.hide()

	if etait_en_mine:
		DatabaseConfig.zone = "mine" 
	else:
		DatabaseConfig.zone = "" 
		
	print("[Keypad] Clavier fermé. Zone actuelle : ", DatabaseConfig.zone)

func is_zone_valid(category: String) -> bool:
	var player_zone = DatabaseConfig.zone
	if mode_mine:
		return category == "Mine"
		
	if category in ["vie", "argent", "MiniJeux"]: 
		_consommer_action_et_quitter()
		return true
		
		
	match category:
		"Mine": return player_zone == "mine"
		"saloon": return player_zone == "saloon"
		"restaurant": return player_zone == "restaurant"
		"arme": return player_zone == "armurerie"
	return false

func apply_card(category: String, effet_valeur, id_carte: String):
	var id_joueur = DatabaseConfig.current_profil_id
	var effet = int(effet_valeur)
	var id_final = DatabaseConfig.cible_don_id if DatabaseConfig.cible_don_id != "" else id_joueur
	
	if DatabaseConfig.cible_don_id != "" and DatabaseConfig.cible_don_id != id_joueur:
		if DatabaseConfig.script_don_result:
			# On appelle la fonction de ton pop-up avec les bonnes références
			DatabaseConfig.script_don_result.afficher_don(id_joueur, id_final, effet, category)
	
	match category:
		"MiniJeux": 
			DatabaseConfig.play_minijeux(id_carte)
		"saloon": DatabaseConfig.get_drink(effet, id_final)
		"restaurant": DatabaseConfig.get_food(effet, id_final)
		"vie": DatabaseConfig.get_life(effet, id_final)
		"argent": DatabaseConfig.get_money(effet, id_final)
		"arme": DatabaseConfig.update_gun(effet, id_final)


func preparer_pour_mine():
	mode_mine = true
	compteur_mines = 0
	close_button.hide() # On ne peut pas fuir la mine !
	self.show()
	print("[Keypad] MODE MINE : Sacrifiez 2 cartes !")
	
func _finaliser_mine_reussie():
	mode_mine = false
	compteur_mines = 0
	mine_terminee.emit()
	_finaliser_utilisation_keypad()
