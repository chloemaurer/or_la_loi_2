extends Control

# --- Noeuds de l'Interface Utilisateur (UI) ---
# Récupération des boutons, labels et sons nécessaires au fonctionnement de l'armurerie
@onready var minus_button: Button = $VBoxContainer/HBoxContainer/moins
@onready var count_label: Label = $VBoxContainer/HBoxContainer/Count
@onready var plus_button: Button = $VBoxContainer/HBoxContainer/plus
@onready var price_label: Label = $VBoxContainer/HBoxContainer/Prix
@onready var money_sound: AudioStreamPlayer = $"../../Son/Money"

# --- Variables de Logique ---
var current_quantity := 1      # Quantité de munitions sélectionnée par défaut
var total_price := 2           # Prix total (commence à 2$ pour une munition)
var drawing_price := 3         # Prix d'un tirage (non utilisé pour l'instant mais conservé)
var ammo_count                 # Variable pour stocker le compte des munitions

# Initialisation au lancement du script
func _ready() -> void:
	_update_labels() # Met à jour l'affichage dès l'ouverture de l'armurerie

# Gestion du clic sur le bouton "Moins"
func _on_moins_pressed() -> void:
	# Change la couleur du prix en orange pendant la modification
	price_label.modulate = Color(1.0, 0.647, 0.0) 
	# On ne descend pas en dessous de 1 munition
	if current_quantity >= 2:
		current_quantity -= 1
		total_price -= 1 # Chaque munition en moins réduit le prix de 1$
		_update_labels()

# Gestion du clic sur le bouton "Plus"
func _on_plus_pressed() -> void:
	# Limite l'achat à 3 munitions max par transaction et vérifie si le joueur a assez d'argent
	if current_quantity <= 2 && total_price < DatabaseConfig.local_money:
		price_label.modulate = Color(1.0, 0.647, 0.0) 
		current_quantity += 1
		total_price += 1 # Chaque munition en plus coûte 1$ de plus
		_update_labels()

# Fonction interne pour rafraîchir le texte des labels à l'écran
func _update_labels() -> void:
	count_label.text = str(current_quantity)
	price_label.text = str(total_price)

# Fonction déclenchée lors de la confirmation finale de l'achat
func _on_armory_buy_card_pressed() -> void:
	var current_id = DatabaseConfig.current_profile_id
	print("Armurerie : Tentative d'achat pour le Profil ", current_id)
	
	# Appel au Singleton pour retirer l'argent de la base de données
	var success = DatabaseConfig.spend_money(total_price, current_id)
	
	if success:
		# Si l'argent a été débité avec succès
		money_sound.play()
		print("Armurerie : Achat validé pour le profil ", current_id)
		
		# On ajoute les munitions au joueur dans la base de données
		DatabaseConfig.get_munition(current_quantity, current_id)
		
		# On comptabilise l'action effectuée pour le tour actuel
		DatabaseConfig.actions_done += 1
		
		# Si le script général est présent, on vérifie si le joueur a atteint sa limite de 2 actions
		if DatabaseConfig.script_general:
			DatabaseConfig.script_general.check_action_limit()
	else :
		# Si le joueur n'a pas assez d'argent, on affiche un message d'erreur
		DatabaseConfig.notify_error("Achat échoué ! Vous n'avez pas assez d'argent")

# Fonction de mise à jour appelée par le DatabaseConfig si nécessaire
func update_interface():
	# Permet de rafraîchir l'affichage si les données globales changent
	_update_labels()
