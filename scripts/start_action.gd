extends Control

# --- Noeuds UI ---
@onready var dés: Control = $"../Dés"
@onready var places: Node2D = $"../Places"
@onready var roll_dice_button: Button = $"../Dés/RollDiceButton"

# Appelé au lancement pour s'assurer que l'interface est propre
func _ready() -> void:
	# On cache le système de dés au démarrage
	dés.hide()

# --- GESTION DES BOUTONS ---

# Appelé quand le joueur choisit de "Piocher" (Action de début de tour)
func _on_piocher_pressed() -> void:
	# On cache simplement ce menu pour laisser le joueur piocher sa carte
	self.hide()

# Appelé quand le joueur choisit de lancer les dés pour se déplacer
func _on_lancer_les_dé_pressed() -> void:
	# 1. On cache le menu de sélection d'action
	self.hide()
	
	# 2. On réactive le bouton de lancer de dés (au cas où il était désactivé)
	roll_dice_button.disabled = false
	
	# 3. Si le script des dés possède une fonction de réinitialisation (rerolled), on l'appelle
	if dés.has_method("rerolled"):
		dés.rerolled()
	
	# 4. On affiche l'interface des dés à l'écran
	dés.show()
