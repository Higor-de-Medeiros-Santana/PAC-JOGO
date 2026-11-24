extends Node2D

const CENA_AVENTURA := "res://scenes/Aventura.tscn"

@onready var botao_aventura: BaseButton = $Aventura
@onready var botao_som: TextureButton = $Som
@onready var icone_sem_som: TextureButton = $"Som/Sem-som"

# Botão Sair (procurado pelo nome, em qualquer lugar da cena).
@onready var botao_sair: BaseButton = find_child(
	"Sair",
	true,
	false
) as BaseButton

# Dados originais de cada botão animado.
var dados_botoes: Dictionary = {}
var tweens_botoes: Dictionary = {}

var animando: bool = false

var som_ativo: bool = true


# ==================================================
# INICIALIZAÇÃO
# ==================================================

func _ready() -> void:

	Audio.tocar_menu()

	# BOTÃO AVENTURA.
	_configurar_botao(botao_aventura)
	botao_aventura.pressed.connect(_on_aventura_pressed)

	# BOTÃO SAIR.
	if botao_sair != null:
		_configurar_botao(botao_sair)
		botao_sair.pressed.connect(_on_sair_pressed)
	else:
		push_error("Botão Sair não encontrado!")

	# Botão de som.
	botao_som.pressed.connect(_alternar_som)

	# O ícone não pode bloquear o botão.
	icone_sem_som.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Sincroniza o botão com o estado global do áudio.
	som_ativo = Audio.som_ativado
	icone_sem_som.visible = not som_ativo


# ==================================================
# CONFIGURAR BOTÃO ANIMADO
# ==================================================

func _configurar_botao(botao: BaseButton) -> void:

	botao.pivot_offset = botao.size / 2.0

	dados_botoes[botao] = {
		"escala": botao.scale,
		"cor": botao.modulate,
		"rotacao": botao.rotation
	}

	tweens_botoes[botao] = null

	botao.mouse_entered.connect(_ao_passar_mouse.bind(botao))
	botao.mouse_exited.connect(_ao_sair_mouse.bind(botao))


# ==================================================
# ALTERNAR SOM
# ==================================================

func _alternar_som() -> void:

	som_ativo = not som_ativo

	# Alterna música e efeitos sonoros.
	Audio.alternar_som()

	# Atualiza o ícone.
	icone_sem_som.visible = not som_ativo

	print("Som ligado: ", som_ativo)


# ==================================================
# INTERROMPER ANIMAÇÃO ANTERIOR
# ==================================================

func _parar_tween(botao: BaseButton) -> void:

	var anterior = tweens_botoes[botao]

	if anterior != null and anterior.is_running():
		anterior.kill()


# ==================================================
# EFEITO AO PASSAR O MOUSE
# ==================================================

func _ao_passar_mouse(botao: BaseButton) -> void:

	if animando:
		return

	_parar_tween(botao)

	var escala_original: Vector2 = dados_botoes[botao]["escala"]

	var tween := create_tween()
	tweens_botoes[botao] = tween

	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(
		botao,
		"scale",
		escala_original * 1.04,
		0.22
	)

	tween.tween_property(
		botao,
		"modulate",
		Color(1.0, 0.92, 0.76),
		0.22
	)


# ==================================================
# EFEITO AO RETIRAR O MOUSE
# ==================================================

func _ao_sair_mouse(botao: BaseButton) -> void:

	if animando:
		return

	_parar_tween(botao)

	var escala_original: Vector2 = dados_botoes[botao]["escala"]
	var cor_original: Color = dados_botoes[botao]["cor"]

	var tween := create_tween()
	tweens_botoes[botao] = tween

	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(
		botao,
		"scale",
		escala_original,
		0.20
	)

	tween.tween_property(
		botao,
		"modulate",
		cor_original,
		0.20
	)


# ==================================================
# ANIMAÇÃO DE CLIQUE (USADA PELOS DOIS BOTÕES)
# ==================================================

func _animar_clique(botao: BaseButton) -> void:

	_parar_tween(botao)

	var escala_original: Vector2 = dados_botoes[botao]["escala"]
	var cor_original: Color = dados_botoes[botao]["cor"]
	var rotacao_original: float = dados_botoes[botao]["rotacao"]

	var tween := create_tween()
	tweens_botoes[botao] = tween

	# Primeira etapa: botão pressionado.
	tween.tween_property(
		botao,
		"scale",
		escala_original * 0.90,
		0.10
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	tween.parallel().tween_property(
		botao,
		"rotation",
		rotacao_original + deg_to_rad(-3.0),
		0.10
	)

	# Segunda etapa: pequeno salto.
	tween.tween_property(
		botao,
		"scale",
		escala_original * 1.10,
		0.22
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	tween.parallel().tween_property(
		botao,
		"rotation",
		rotacao_original + deg_to_rad(2.0),
		0.22
	)

	tween.parallel().tween_property(
		botao,
		"modulate",
		Color(1.0, 0.88, 0.60),
		0.22
	)

	# Terceira etapa: retorno ao tamanho original.
	tween.tween_property(
		botao,
		"scale",
		escala_original,
		0.18
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	tween.parallel().tween_property(
		botao,
		"rotation",
		rotacao_original,
		0.18
	)

	tween.parallel().tween_property(
		botao,
		"modulate",
		cor_original,
		0.18
	)

	await tween.finished

	# Pequena pausa antes da transição.
	await get_tree().create_timer(0.10).timeout


# ==================================================
# CLIQUE NO BOTÃO AVENTURA
# ==================================================

func _on_aventura_pressed() -> void:

	if animando:
		return

	# Som de clique do botão Aventura.
	Audio.tocar_click()

	animando = true
	botao_aventura.disabled = true

	if botao_sair != null:
		botao_sair.disabled = true

	await _animar_clique(botao_aventura)

	_iniciar_transicao()


# ==================================================
# CLIQUE NO BOTÃO SAIR
# ==================================================

func _on_sair_pressed() -> void:

	if animando:
		return

	# Som de clique do botão Sair.
	Audio.tocar_click()

	animando = true
	botao_sair.disabled = true
	botao_aventura.disabled = true

	await _animar_clique(botao_sair)

	await _fade_para_preto()

	# Fecha o jogo.
	get_tree().quit()


# ==================================================
# FADE PARA PRETO
# ==================================================

func _fade_para_preto() -> void:

	var camada := CanvasLayer.new()
	camada.layer = 100
	add_child(camada)

	var fade := ColorRect.new()
	camada.add_child(fade)

	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.color = Color.BLACK
	fade.modulate.a = 0.0
	fade.mouse_filter = Control.MOUSE_FILTER_STOP

	var transicao := create_tween()
	transicao.set_trans(Tween.TRANS_SINE)
	transicao.set_ease(Tween.EASE_IN_OUT)

	transicao.tween_property(
		fade,
		"modulate:a",
		1.0,
		0.7
	)

	await transicao.finished


# ==================================================
# TRANSIÇÃO DE TELA
# ==================================================

func _iniciar_transicao() -> void:

	# Inicia a música da aventura.
	Audio.tocar_aventura()

	await _fade_para_preto()

	var erro := get_tree().change_scene_to_file(CENA_AVENTURA)

	if erro != OK:
		push_error("Não foi possível abrir Aventura.tscn")
