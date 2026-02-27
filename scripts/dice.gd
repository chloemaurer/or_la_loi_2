extends BaseButton

# --- Noeuds d'Animation ---
# Récupère les lecteurs d'animation pour lancer le mouvement visuel des dés
@onready var roll_anim_1: AnimationPlayer = $"../SubViewportContainer/SubViewport/Node3D/RollDiceAnimation"
@onready var roll_anim_2: AnimationPlayer = $"../SubViewportContainer/SubViewport/Node3D2/RollDiceAnimation2"

# --- Noeuds des Dés (3D) ---
const DiceScript = preload("uid://fd3fwqw0llor")
@onready var dice_6_sides: DiceScript = $"../SubViewportContainer/SubViewport/Node3D/D6"
@onready var dice_2_sides: DiceScript = $"../SubViewportContainer/SubViewport/Node3D2/D2"

# --- Noeuds UI ---
@onready var dice_result_label: Label = $"../DiceResultLabel"
@onready var places_container: Node2D = $"../../Places"

# --- Boutons des Lieux de la Map ---
@onready var saloon_btn: Button = $"../../Places/Saloon"
@onready var mine_btn: Button = $"../../Places/Mine"
@onready var restaurant_btn: Button = $"../../Places/Restaurant"
@onready var armory_btn: Button = $"../../Places/Armory"
@onready var bank_btn: Button = $"../../Places/Bank"
@onready var duel_btn: Button = $"../../Places/Duel"
@onready var roll_dice_button: Button = $"."

# --- Variables de Logique ---
var total_dice_value := 0 # Stocke la somme des deux dés

# Lance le processus de lancer de dés
func roll_dice():
	# On commence par cacher tous les lieux pour faire "place nette"
	_hide_all_places()
	
	# Donne une rotation de départ aléatoire pour que le mouvement paraisse naturel
	_randomize_rotation(dice_6_sides)
	_randomize_rotation(dice_2_sides)
	
	# Joue les animations de lancer (D6 et D2)
	roll_anim_1.play("dice_6")
	roll_anim_2.play("dice_2")
	
	# Calcule le total immédiatement (la valeur est prédéterminée par le script du dé)
	total_dice_value = dice_6_sides.get_number() + dice_2_sides.get_number()
	
	# Désactive le bouton pour éviter de lancer plusieurs fois pendant l'animation
	roll_dice_button.disabled = true

# Utilitaire pour faire pivoter les dés sur des angles de 90 degrés au hasard
func _randomize_rotation(dice_node):
	dice_node.rotate_x(deg_to_rad(randi_range(0, 5) * 90))
	dice_node.rotate_z(deg_to_rad(randi_range(0, 5) * 90))
	dice_node.rotate_y(deg_to_rad(randi_range(0, 5) * 90))

# Affiche le chiffre final sur le label UI
func display_result(value: int):
	dice_result_label.text = str(value)

# Cache tous les boutons d'accès aux lieux de la carte
func _hide_all_places() -> void:
	bank_btn.hide()
	saloon_btn.hide()
	mine_btn.hide()
	restaurant_btn.hide()
	duel_btn.hide()
	armory_btn.hide()

# --- LOGIQUE DE PROBABILITÉ : Débloque les lieux selon le total des dés ---
func enable_available_places():
	var current_round = DatabaseConfig.current_round
	
	# Utilisation d'un Match (équivalent du Switch) pour définir quels lieux ouvrir
	match total_dice_value:
		2:
			bank_btn.show()
			duel_btn.show()
			if current_round >= 6: mine_btn.show() # La mine ne s'ouvre qu'après la moitié du jeu
		3:
			bank_btn.show()
			duel_btn.show()
		4:
			duel_btn.show()
			restaurant_btn.show()
		5:
			duel_btn.show()
			restaurant_btn.show()
			saloon_btn.show()
		6:
			duel_btn.show()
			restaurant_btn.show()
			saloon_btn.show()
		7:
			saloon_btn.show()
			restaurant_btn.show()
		8:
			saloon_btn.show()
			restaurant_btn.show()
			armory_btn.show()
		9:
			saloon_btn.show()
			armory_btn.show()
		10:
			armory_btn.show()
		11:
			armory_btn.show()
			bank_btn.show()
		12:
			armory_btn.show()
			bank_btn.show()
			if current_round >= 6: mine_btn.show()
		_:
			print("Erreur : Somme de dés inconnue ", total_dice_value)

# Se déclenche automatiquement quand l'animation de lancer est finie
func _on_roll_dice_animation_animation_finished(_anim_name: StringName) -> void:
	# Affiche le conteneur des lieux, le chiffre final et active les boutons autorisés
	places_container.show()
	display_result(total_dice_value)	
	enable_available_places()
