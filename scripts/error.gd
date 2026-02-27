extends Control

# --- Noeuds UI ---
# Récupère le texte de l'erreur et le minuteur pour gérer la disparition
@onready var error_label: Label = $ErrorText
@onready var display_timer: Timer = $Timer

func _ready():
	# On s'abonne au signal global du Singleton. 
	# Dès qu'une erreur survient n'importe où, cette fonction s'exécutera.
	DatabaseConfig.error_display_requested.connect(_show_message)

# Affiche la notification avec une petite animation
func _show_message():
	# Récupère le message d'erreur stocké dans le Singleton
	error_label.text = DatabaseConfig.error_message
	
	self.show()
	display_timer.start()
	
	# Animation d'apparition (Fade-in)
	# On met l'opacité à 0 puis on l'augmente jusqu'à 1 en 0.2 seconde
	self.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2)
	
# Se déclenche quand le temps d'affichage est écoulé
func _on_timer_timeout():
	# Animation de disparition (Fade-out)
	# On réduit l'opacité à 0 avant de cacher complètement le noeud
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	
	# On attend la fin de l'animation avant de cacher le menu
	await tween.finished
	self.hide()
