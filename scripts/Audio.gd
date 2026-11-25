
extends Node

# ==========================================
# NEUROMIND - GERENCIADOR DE ÁUDIO
# ==========================================

const MUSICA_MENU: AudioStream = preload("res://Assets/Musica/Menu.mp3")
const MUSICA_AVENTURA: AudioStream = preload("res://Assets/Musica/Aventura.mp3")

const SOM_ACERTO: AudioStream = preload("res://Assets/Musica/Acerto.mp3")
const SOM_ERRO: AudioStream = preload("res://Assets/Musica/Erro.mp3")
const SOM_CLICK: AudioStream = preload("res://Assets/Musica/Click.mp3")

# Volume baixo para as músicas.
const VOLUME_MENU := -26.0
const VOLUME_AVENTURA := -24.0

var music_player: AudioStreamPlayer
var musica_atual: AudioStream = null
var som_ativado: bool = true


func _ready() -> void:

	# Player exclusivo para músicas de fundo.
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.volume_db = VOLUME_MENU

	add_child(music_player)

	# Reiniciar música quando terminar.
	music_player.finished.connect(_repetir_musica)


# ==========================================
# MÚSICAS DE FUNDO
# ==========================================

func tocar_menu() -> void:

	music_player.volume_db = VOLUME_MENU

	tocar_musica(MUSICA_MENU)


func tocar_aventura() -> void:

	music_player.volume_db = VOLUME_AVENTURA

	tocar_musica(MUSICA_AVENTURA)


func tocar_musica(musica: AudioStream) -> void:

	if musica_atual == musica and music_player.playing:
		return

	musica_atual = musica
	music_player.stream = musica

	# Só reproduz se o som estiver ativado.
	if som_ativado:
		music_player.play()
	else:
		music_player.stop()


func parar_musica() -> void:

	music_player.stop()
	musica_atual = null


func _repetir_musica() -> void:

	if musica_atual != null and som_ativado:
		music_player.play()


# ==========================================
# EFEITOS SONOROS
# ==========================================

func tocar_acerto() -> void:

	tocar_efeito(SOM_ACERTO)


func tocar_erro() -> void:

	tocar_efeito(SOM_ERRO)


func tocar_click() -> void:

	tocar_efeito(SOM_CLICK)


func tocar_efeito(som: AudioStream) -> void:

	if not som_ativado:
		return

	var player := AudioStreamPlayer.new()

	player.stream = som
	player.volume_db = -8.0

	add_child(player)

	player.finished.connect(func():
		player.queue_free()
	)

	player.play()


# ==========================================
# CONTROLE DE SOM
# ==========================================

func alternar_som() -> void:

	som_ativado = not som_ativado

	if som_ativado:

		if musica_atual != null:
			music_player.play()

	else:

		music_player.stop()


func definir_volume_musica(volume: float) -> void:

	music_player.volume_db = linear_to_db(
		clampf(volume, 0.001, 1.0)
	)
