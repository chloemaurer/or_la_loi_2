extends Control

# --- Noeuds UI et Vidéos ---
@onready var bg_music: AudioStreamPlayer = $"../BgMusic"
@onready var sand_tempest: VideoStreamPlayer = $"../Map/SandTempest"
@onready var story: VideoStreamPlayer = $"../Animations/Story"
@onready var rules: VideoStreamPlayer = $"../Animations/Rules"
@onready var video_settings: Control = $"../Animations/VideoSettings"
@onready var stop_play: TextureRect = $"../Animations/VideoSettings/Panel2/StopPlay"


func _ready() -> void:
	# Empêche les clics de traverser les vidéos pour ne pas interagir avec la map derrière
	story.mouse_filter = Control.MOUSE_FILTER_STOP
	rules.mouse_filter = Control.MOUSE_FILTER_STOP

# Lance la cinématique d'introduction quand on appuie sur Start
func _on_start_game_pressed() -> void:
	self.hide()
	_jouer_video(story)

# Enchaîne sur la vidéo des règles une fois l'histoire terminée
func _on_story_finished() -> void:
	story.hide()
	_jouer_video(rules)

# Active la musique et cache les réglages vidéo une fois l'init terminée
func _on_rules_finished() -> void:
	rules.hide()
	bg_music.play()
	video_settings.hide()

# --- SYSTÈME DE PAUSE ---
# Gère la mise en pause de n'importe quelle vidéo active et change l'icône du bouton
func _on_stop_play_pressed() -> void:
	var video_actuelle : VideoStreamPlayer = null
	
	# Identifie quelle vidéo est actuellement à l'écran
	if story.visible: video_actuelle = story
	elif rules.visible: video_actuelle = rules
	elif sand_tempest.visible: video_actuelle = sand_tempest

	if video_actuelle:
		# Alterne l'état de pause
		video_actuelle.paused = !video_actuelle.paused
		
		# Change l'icône : Play si en pause, Pause si en lecture
		stop_play.texture = preload("uid://bip4ub8jn6dd3") if video_actuelle.paused else preload("uid://u74vh4xmeega")
	else:
		print("Erreur : Aucune vidéo active trouvée")

# --- AFFICHAGE DES RÉGLAGES ---
# Affiche ou cache la barre de réglages (Pause/Skip) lors d'un clic sur la vidéo
func _on_video_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		video_settings.visible = !video_settings.visible

# Relie les entrées tactiles/souris des vidéos au système de réglages
func _on_rules_gui_input(event: InputEvent) -> void:
	_on_video_input(event)

func _on_story_gui_input(event: InputEvent) -> void:
	_on_video_input(event)

# --- OUTILS ---
# Fonction générique pour lancer une vidéo proprement
func _jouer_video(video: VideoStreamPlayer):
	video.show()
	video.paused = false
	video.play()

func _on_sand_tempest_finished() -> void:
	sand_tempest.hide()

# Permet de passer la vidéo actuelle et déclenche automatiquement la suite via le signal "finished"
func _on_skip_pressed() -> void:
	var video_actuelle : VideoStreamPlayer = null
	if story.visible: video_actuelle = story
	elif rules.visible: video_actuelle = rules
	elif sand_tempest.visible: video_actuelle = sand_tempest

	if video_actuelle:
		video_actuelle.stop()
		video_actuelle.emit_signal("finished")
