extends Control
# Menu.gd
# Tela inicial do jogo.

@onready var _play_btn: Button  = $VBox/PlayButton
@onready var _quit_btn: Button  = $VBox/QuitButton
@onready var _title: Label      = $TitleLabel
@onready var _subtitle: Label   = $SubtitleLabel



func _ready() -> void:
	Gerenciador.reset_game()
	# Animação de entrada
	_title.modulate.a = 0
	_subtitle.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(_title, "modulate:a", 1.0, 0.8)
	tween.tween_property(_subtitle, "modulate:a", 1.0, 0.6)


func _tocar_som(player: AudioStreamPlayer) -> void:
	if player and player.stream:
		player.pitch_scale = randf_range(0.95, 1.05)
		player.play()


func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/CenaJogo.tscn")


func _on_adventure_button_pressed() -> void:
	RunManager.start_new_run()
	get_tree().change_scene_to_file("res://scenes/Mapa.tscn")


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_tutorial_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Tutorial.tscn")
