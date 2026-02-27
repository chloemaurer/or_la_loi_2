extends Control

@onready var bg_music: AudioStreamPlayer = $"../BgMusic"
@onready var sand_tempest: VideoStreamPlayer = $"../Map/SandTempest"
@onready var story: VideoStreamPlayer = $"../Animations/Story"
@onready var rules: VideoStreamPlayer = $"../Animations/Rules"
@onready var video_settings: Control = $"../Animations/VideoSettings"
@onready var stop_play: TextureRect = $"../Animations/VideoSettings/Panel2/StopPlay"


func _ready() -> void:
	story.mouse_filter = Control.MOUSE_FILTER_STOP
	rules.mouse_filter = Control.MOUSE_FILTER_STOP

func _on_start_game_pressed() -> void:
	
	self.hide()
	_jouer_video(story)

func _on_story_finished() -> void:
	story.hide()
	_jouer_video(rules)

func _on_rules_finished() -> void:
	rules.hide()
	bg_music.play()
	video_settings.hide()

# --- SYSTÈME DE PAUSE (L'ACTION DU BOUTON) ---
func _on_stop_play_pressed() -> void:
	print("bouton pause cliquer")
	# On identifie la vidéo active
	var video_actuelle : VideoStreamPlayer = null
	if story.visible: video_actuelle = story
	elif rules.visible: video_actuelle = rules
	elif sand_tempest.visible: video_actuelle = sand_tempest

	if video_actuelle:
		# On bascule l'état de pause
		video_actuelle.paused = !video_actuelle.paused
		
		# Mise à jour de l'icône
		# Si en pause : icône Play (bip4...), sinon icône Pause (u74...)
		stop_play.texture = preload("uid://bip4ub8jn6dd3") if video_actuelle.paused else preload("uid://u74vh4xmeega")
		
		print("Vidéo ", video_actuelle.name, " en pause : ", video_actuelle.paused)
	else:
		print("Erreur : Aucune vidéo active trouvée")

# --- AFFICHAGE DES RÉGLAGES ---
func _on_video_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		video_settings.visible = !video_settings.visible

func _on_rules_gui_input(event: InputEvent) -> void:
	_on_video_input(event)

func _on_story_gui_input(event: InputEvent) -> void:
	_on_video_input(event)

# --- OUTILS ---
func _jouer_video(video: VideoStreamPlayer):
	video.show()
	video.paused = false
	video.play()

func _on_sand_tempest_finished() -> void:
	sand_tempest.hide()


func _on_skip_pressed() -> void:
	var video_actuelle : VideoStreamPlayer = null
	if story.visible: video_actuelle = story
	elif rules.visible: video_actuelle = rules
	elif sand_tempest.visible: video_actuelle = sand_tempest

	if video_actuelle:
		video_actuelle.stop()
		video_actuelle.emit_signal("finished")
