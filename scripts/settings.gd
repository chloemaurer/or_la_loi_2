extends Control

# --- Noeuds UI ---
@onready var settings_panel: Panel = $Panel2 # Menu des paramètres
@onready var rules_panel: Panel = $Panel3   # Menu de sélection des chapitres de règles
@onready var bg_music: AudioStreamPlayer = $"../../BgMusic"
@onready var volume_slider: HSlider = $Panel2/VBoxContainer/Control/Volume
@onready var rules_video: VideoStreamPlayer = $"../../Animations/Rules"

# --- Variables de Logique ---
var stop_at_time : float = 0.0      # Timestamp auquel la vidéo doit s'arrêter
var is_playing_section : bool = false # État de lecture d'un segment spécifique

func _ready() -> void:
	# On s'assure que les menus sont cachés au lancement
	settings_panel.hide()
	rules_panel.hide()

# Bascule l'affichage du menu des paramètres
func _on_button_pressed() -> void:
	settings_panel.visible = !settings_panel.visible
	rules_panel.hide() # Ferme les règles si on ouvre les paramètres

# Déclenche une réinitialisation complète de la base de données via le Singleton
func _on_reset_pressed() -> void:
	DatabaseConfig.reset_game()

# Ajuste le volume de la musique (en décibels)
func _on_volume_value_changed(value: float) -> void:
	bg_music.set_volume_db(value)

# Affiche/Cache le menu de sélection des vidéos de règles
func _on_video_pressed() -> void:
	rules_panel.visible = !rules_panel.visible

func _process(_delta):
	# Surveille la position de lecture pour arrêter la vidéo au bon moment
	if is_playing_section and rules_video.stream_position >= stop_at_time:
		rules_video.stop()
		rules_video.hide() 
		is_playing_section = false
		print("Segment terminé à : ", rules_video.stream_position)

# Fonction générique pour lire une portion spécifique de la vidéo tutorielle
func play_section(start: float, end: float):
	bg_music.stop() # Coupe la musique pour mieux entendre les explications
	print("Lecture segment : ", start, "s jusqu'à ", end, "s")
	
	rules_video.stream_position = start
	stop_at_time = end
	is_playing_section = true
	
	rules_video.show()
	rules_video.play()

# --- BOUTONS DES SECTIONS DE RÈGLES ---
# Chaque bouton correspond à un chapitre spécifique de ton tutoriel vidéo

func _on_vidéo_1_pressed():
	play_section(0.0, 33.0) # Introduction

func _on_vidéo_2_pressed():
	play_section(33.0, 43.0) # Concept de base

func _on_vidéo_3_pressed():
	play_section(43.0, 80.0) # Phase de déplacement

func _on_vidéo_4_pressed():
	play_section(80.0, 108.0) # Utilisation des ressources

func _on_vidéo_5_pressed():
	play_section(108.0, 200.0) # Mécaniques de combat / Duel

func _on_vidéo_6_pressed():
	play_section(200.0, 246.0) # Gestion de l'inventaire

func _on_vidéo_7_pressed():
	play_section(246.0, 260.0) # Le Saloon / Le Restaurant

func _on_vidéo_8_pressed():
	play_section(260.0, 275.0) # La Banque

func _on_vidéo_9_pressed():
	# Lecture du dernier segment jusqu'à la fin
	play_section(275.0, 9999.0)
