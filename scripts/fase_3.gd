extends Node2D

# ==================================================
# CONFIGURAÇÕES
# ==================================================

const TOTAL_DESAFIOS: int = 10
const TOTAL_ALTERNATIVAS: int = 6
const PONTOS_POR_ACERTO: int = 3

const GABARITO: Array[int] = [
	4, 3, 5, 3, 5, 5, 4, 5, 5, 1
]

const TEMPO_TRANSICAO: float = 0.65
const CENA_AVENTURA := "res://scenes/Aventura.tscn"

@onready var botao_voltar: TextureButton = find_child(
	"Voltar",
	true,
	false
) as TextureButton

# ==================================================
# NÓS
# ==================================================

var painel_alternativas: Control
var botoes: Array[TextureButton] = []
var referencias: Array[Control] = []

var botao_confirmar: TextureButton

var label_pip: Label
var label_pontos: Label
var label_estrelas: Label
var label_tempo: Label
var label_tentativas: Label

var cronometro: Timer

# ==================================================
# VARIÁVEIS DO JOGO
# ==================================================

var desafio_atual: int = 0
var alternativa_selecionada: int = -1

var pontos: int = 0
var acertos: int = 0
var total_tentativas: int = 0
var segundos: int = 0

var transicao_em_andamento: bool = false
var jogo_finalizado: bool = false

var escalas_originais: Array[Vector2] = []
var cores_originais: Array[Color] = []
var animacoes_botoes: Array = []

# ==================================================
# INICIALIZAÇÃO
# ==================================================

func _ready() -> void:

	await get_tree().process_frame

	# CONECTAR BOTÃO VOLTAR AO MODO AVENTURA.
	if botao_voltar != null:
		if not botao_voltar.pressed.is_connected(_voltar_aventura):
			botao_voltar.pressed.connect(_voltar_aventura)
	else:
		push_error("Botão Voltar não encontrado!")

	_localizar_nos()

	if not _validar_nos():
		return

	_configurar_pip()
	_conectar_botoes()
	_configurar_cronometro()

	_carregar_desafio()

	_atualizar_pontuacao()
	_atualizar_tempo()

	_fala_pip(
		"Olá! Vamos resolver os dez desafios das Matrizes do Enigma!"
	)

	cronometro.start()

	print("FASE 3 INICIALIZADA!")


# ==================================================
# LOCALIZAR NÓS
# ==================================================

func _localizar_nos() -> void:

	painel_alternativas = get_node_or_null(
		"Background/TextureRect"
	) as Control

	botao_confirmar = get_node_or_null(
		"Background/TextureButton"
	) as TextureButton

	label_pip = get_node_or_null(
		"Background/TextureRect5/Label"
	) as Label

	label_pontos = get_node_or_null(
		"Background/barra-estrelas/pontos"
	) as Label

	label_estrelas = get_node_or_null(
		"Background/Recompensas/estrela"
	) as Label

	label_tempo = get_node_or_null(
		"Background/TextureRect3/Label"
	) as Label

	label_tentativas = get_node_or_null(
		"Background/TextureRect4/Label"
	) as Label

	cronometro = get_node_or_null(
		"Background/TextureRect3/Timer"
	) as Timer

	botoes.clear()
	referencias.clear()

	if painel_alternativas == null:
		return

	# SEIS BOTÕES REUTILIZADOS NOS DEZ DESAFIOS.

	for i in range(1, TOTAL_ALTERNATIVAS + 1):

		var botao := painel_alternativas.get_node_or_null(
			"b-" + str(i)
		) as TextureButton

		if botao != null:
			botoes.append(botao)

	# REFERÊNCIAS I-1 ATÉ I-10.
	# I-1 É O PAI DAS OUTRAS IMAGENS.

	var primeira := painel_alternativas.get_node_or_null(
		"I-1"
	) as Control

	if primeira != null:

		referencias.append(primeira)

		for i in range(2, TOTAL_DESAFIOS + 1):

			var imagem := primeira.get_node_or_null(
				"I-" + str(i)
			) as Control

			if imagem != null:
				referencias.append(imagem)


# ==================================================
# VALIDAR NÓS
# ==================================================

func _validar_nos() -> bool:

	if painel_alternativas == null:
		push_error("TextureRect das alternativas não encontrado!")
		return false

	if botoes.size() != TOTAL_ALTERNATIVAS:
		push_error("Não foram encontrados os seis botões!")
		return false

	if referencias.size() != TOTAL_DESAFIOS:
		push_error("Não foram encontradas as dez referências!")
		return false

	if botao_confirmar == null:
		push_error("Botão de confirmação não encontrado!")
		return false

	if cronometro == null:
		push_error("Timer não encontrado!")
		return false

	if label_pip == null:
		push_error("Label do Pip não encontrado!")
		return false

	if label_pontos == null:
		push_error("Label de pontos não encontrado!")
		return false

	if label_estrelas == null:
		push_error("Label de estrelas não encontrado!")
		return false

	return true


# ==================================================
# CONFIGURAR PIP
# ==================================================

func _configurar_pip() -> void:

	label_pip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label_pip.clip_text = false


func _fala_pip(mensagem: String) -> void:

	if label_pip != null:
		label_pip.text = mensagem


# ==================================================
# CONECTAR BOTÕES
# ==================================================

func _conectar_botoes() -> void:

	for i in range(botoes.size()):

		var botao := botoes[i]

		botao.pivot_offset = botao.size / 2.0

		escalas_originais.append(botao.scale)
		cores_originais.append(botao.modulate)
		animacoes_botoes.append(null)

		botao.pressed.connect(
			_selecionar_alternativa.bind(i)
		)

	if not botao_confirmar.pressed.is_connected(
		_confirmar_resposta
	):
		botao_confirmar.pressed.connect(
			_confirmar_resposta
		)

	botao_confirmar.disabled = true


# ==================================================
# CARREGAR DESAFIO
# ==================================================

func _carregar_desafio() -> void:

	alternativa_selecionada = -1

	_carregar_alternativas()
	_atualizar_referencia()

	for i in range(botoes.size()):

		var botao := botoes[i]

		botao.disabled = false
		botao.visible = true
		botao.scale = escalas_originais[i]
		botao.modulate = cores_originais[i]

	botao_confirmar.disabled = true

	_atualizar_pontuacao()
	_atualizar_tentativas()


# ==================================================
# CARREGAR AS SEIS ALTERNATIVAS
# ==================================================

func _carregar_alternativas() -> void:

	var numero_fase: int = desafio_atual + 1

	print("\n========== DESAFIO ", numero_fase, " ==========")

	for i in range(TOTAL_ALTERNATIVAS):

		var caminho: String = (
			"res://Assets/TELA-%d/Fase-%d_%d.png"
			% [
				numero_fase,
				numero_fase,
				i + 1
			]
		)

		if not ResourceLoader.exists(caminho):
			push_error("IMAGEM NÃO ENCONTRADA: " + caminho)
			continue

		var textura: Texture2D = load(caminho) as Texture2D

		if textura == null:
			push_error("FALHA AO CARREGAR: " + caminho)
			continue

		botoes[i].texture_normal = textura
		botoes[i].texture_hover = textura
		botoes[i].texture_pressed = textura
		botoes[i].texture_focused = textura
		botoes[i].texture_disabled = textura

		print("OK: b-", i + 1, " recebeu ", caminho)


# ==================================================
# ATUALIZAR IMAGEM DE REFERÊNCIA
# ==================================================

func _atualizar_referencia() -> void:

	# I-1 é pai. Não escondemos o pai inteiro,
	# pois isso esconderia também as imagens filhas.

	for i in range(referencias.size()):

		var imagem := referencias[i]

		if i == 0:

			imagem.visible = true

			if desafio_atual == 0:
				imagem.self_modulate = Color.WHITE
			else:
				imagem.self_modulate = Color(1, 1, 1, 0)

		else:

			imagem.visible = (i == desafio_atual)
			imagem.self_modulate = Color.WHITE

		imagem.pivot_offset = imagem.size / 2.0


func _obter_referencia_atual() -> Control:

	if desafio_atual < 0:
		return null

	if desafio_atual >= referencias.size():
		return null

	return referencias[desafio_atual]


# ==================================================
# ANIMAÇÕES DOS BOTÕES
# ==================================================

func _animar_botao(
	indice: int,
	nova_escala: Vector2,
	nova_cor: Color,
	duracao: float
) -> void:

	var anterior = animacoes_botoes[indice]

	if anterior != null and anterior.is_running():
		anterior.kill()

	var tween := create_tween()

	animacoes_botoes[indice] = tween

	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(
		botoes[indice],
		"scale",
		nova_escala,
		duracao
	)

	tween.tween_property(
		botoes[indice],
		"modulate",
		nova_cor,
		duracao
	)


func _restaurar_botao(indice: int) -> void:

	_animar_botao(
		indice,
		escalas_originais[indice],
		cores_originais[indice],
		0.15
	)


# ==================================================
# SELECIONAR ALTERNATIVA
# ==================================================

func _selecionar_alternativa(indice: int) -> void:

	if transicao_em_andamento or jogo_finalizado:
		return

	if alternativa_selecionada == indice:
		return

	if alternativa_selecionada != -1:
		_restaurar_botao(alternativa_selecionada)

	alternativa_selecionada = indice

	_animar_botao(
		indice,
		escalas_originais[indice] * 1.06,
		Color("#FFD45A"),
		0.18
	)

	botao_confirmar.disabled = false


# ==================================================
# CONFIRMAR RESPOSTA
# ==================================================

func _confirmar_resposta() -> void:

	if transicao_em_andamento or jogo_finalizado:
		return

	if alternativa_selecionada == -1:
		return

	transicao_em_andamento = true
	total_tentativas += 1

	botao_confirmar.disabled = true

	var resposta_correta: bool = (
		alternativa_selecionada + 1
		== GABARITO[desafio_atual]
	)

	# RESPOSTA CORRETA.

	if resposta_correta:

		Audio.tocar_acerto()

		acertos += 1
		pontos += PONTOS_POR_ACERTO

		_fala_pip(
			"Excelente! Você encontrou a resposta correta!"
		)

		_animar_botao(
			alternativa_selecionada,
			escalas_originais[alternativa_selecionada] * 1.08,
			Color("#75FF85"),
			0.25
		)

		# COMEMORAÇÃO COM CONFETES NA RESPOSTA CORRETA.
		await _efeito_confetes()

	# RESPOSTA ERRADA.

	else:

		Audio.tocar_erro()

		_fala_pip(
			"Não foi dessa vez! Vamos observar o próximo enigma!"
		)

		_animar_botao(
			alternativa_selecionada,
			escalas_originais[alternativa_selecionada] * 1.08,
			Color("#FF3333"),
			0.30
		)

		# DESTAQUE VERMELHO E TREMOR NA RESPOSTA ERRADA.
		await _efeito_visual_erro(alternativa_selecionada)

	_atualizar_pontuacao()
	_atualizar_tentativas()

	# Mantém a cor verde ou vermelha visível brevemente.
	await get_tree().create_timer(0.40).timeout

	await _animar_saida_desafio()

	if desafio_atual < TOTAL_DESAFIOS - 1:

		desafio_atual += 1

		_carregar_desafio()

		await _animar_entrada_desafio()

		_fala_pip(
			"Vamos para o desafio "
			+ str(desafio_atual + 1)
			+ "!"
		)

		transicao_em_andamento = false

	else:

		await _finalizar_fase()


# ==================================================
# ANIMAÇÃO DE SAÍDA
# ==================================================

func _animar_saida_desafio() -> void:

	for botao in botoes:

		var tween := create_tween()
		tween.set_parallel(true)

		tween.tween_property(
			botao,
			"scale",
			Vector2.ZERO,
			TEMPO_TRANSICAO
		).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

		tween.tween_property(
			botao,
			"modulate",
			Color(1.0, 0.75, 0.2, 0.0),
			TEMPO_TRANSICAO
		)

		_criar_particulas_douradas(botao)

	var referencia := _obter_referencia_atual()

	if referencia != null:

		var tween_ref := create_tween()
		tween_ref.set_parallel(true)

		tween_ref.tween_property(
			referencia,
			"scale",
			Vector2(1.12, 1.12),
			TEMPO_TRANSICAO
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

		tween_ref.tween_property(
			referencia,
			"self_modulate",
			Color(1.0, 0.85, 0.4, 0.0),
			TEMPO_TRANSICAO
		)

	await get_tree().create_timer(TEMPO_TRANSICAO).timeout

	if referencia != null:

		if desafio_atual == 0:
			referencia.self_modulate = Color(1, 1, 1, 0)
		else:
			referencia.visible = false

	await get_tree().create_timer(0.15).timeout


# ==================================================
# ANIMAÇÃO DE ENTRADA
# ==================================================

func _animar_entrada_desafio() -> void:

	var referencia := _obter_referencia_atual()

	if referencia != null:

		referencia.scale = Vector2(0.90, 0.90)
		referencia.self_modulate = Color(1, 1, 1, 0)

		var tween_ref := create_tween()
		tween_ref.set_parallel(true)

		tween_ref.tween_property(
			referencia,
			"scale",
			Vector2.ONE,
			0.55
		).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

		tween_ref.tween_property(
			referencia,
			"self_modulate",
			Color.WHITE,
			0.55
		)

	for botao in botoes:

		botao.scale = Vector2.ZERO
		botao.modulate = Color(1, 1, 1, 0)
		botao.disabled = false

		var tween := create_tween()
		tween.set_parallel(true)

		tween.tween_property(
			botao,
			"scale",
			Vector2.ONE,
			0.30
		).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

		tween.tween_property(
			botao,
			"modulate",
			Color.WHITE,
			0.30
		)

		await get_tree().create_timer(0.07).timeout

	await get_tree().create_timer(0.35).timeout


# ==================================================
# PARTÍCULAS DOURADAS
# ==================================================

func _criar_particulas_douradas(alvo: Control) -> void:

	var particulas := Node2D.new()

	particulas.global_position = (
		alvo.global_position + alvo.size / 2.0
	)

	add_child(particulas)

	for i in range(9):

		var brilho := Label.new()

		brilho.text = "✦"
		brilho.modulate = Color("#FFD45A")
		brilho.add_theme_font_size_override("font_size", 22)
		brilho.size = Vector2(40, 40)

		brilho.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		brilho.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

		particulas.add_child(brilho)

		var angulo: float = TAU * float(i) / 9.0
		var distancia: float = randf_range(35.0, 85.0)

		var destino := Vector2(
			cos(angulo) * distancia,
			sin(angulo) * distancia
		)

		var tween := create_tween()
		tween.set_parallel(true)

		tween.tween_property(
			brilho,
			"position",
			destino,
			0.65
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

		tween.tween_property(
			brilho,
			"modulate:a",
			0.0,
			0.65
		)

		tween.tween_property(
			brilho,
			"scale",
			Vector2.ZERO,
			0.65
		)

	await get_tree().create_timer(0.8).timeout

	particulas.queue_free()


# ==================================================
# CRONÔMETRO
# ==================================================

func _configurar_cronometro() -> void:

	cronometro.wait_time = 1.0
	cronometro.one_shot = false

	if not cronometro.timeout.is_connected(
		_ao_passar_segundo
	):
		cronometro.timeout.connect(
			_ao_passar_segundo
		)


func _ao_passar_segundo() -> void:

	if jogo_finalizado:
		return

	segundos += 1
	_atualizar_tempo()


func _atualizar_tempo() -> void:

	if label_tempo == null:
		return

	var minutos: int = int(segundos / 60)
	var segundos_restantes: int = segundos % 60

	label_tempo.text = "%02d:%02d" % [
		minutos,
		segundos_restantes
	]


# ==================================================
# PONTUAÇÃO E ESTRELAS
# ==================================================

func _calcular_estrelas() -> int:

	if acertos >= 8:
		return 3

	if acertos >= 5:
		return 2

	if acertos >= 1:
		return 1

	return 0


func _atualizar_pontuacao() -> void:

	pontos = clampi(pontos, 0, 30)

	if label_pontos != null:
		label_pontos.text = "           " + str(pontos) + "/30"

	if label_estrelas != null:
		label_estrelas.text = (
			str(_calcular_estrelas()) + "/3 ⭐"
		)


func _atualizar_tentativas() -> void:

	if label_tentativas != null:
		label_tentativas.text = str(total_tentativas)


# ==================================================
# FINALIZAR FASE
# ==================================================

func _finalizar_fase() -> void:

	jogo_finalizado = true
	transicao_em_andamento = true

	cronometro.stop()

	var estrelas_finais: int = _calcular_estrelas()

	_atualizar_pontuacao()

	_fala_pip(
		"Parabéns! Você concluiu os dez desafios e conquistou "
		+ str(pontos)
		+ " de 30 pontos e "
		+ str(estrelas_finais)
		+ " estrelas!"
	)

	# SALVAR AS ESTRELAS NO GERENCIADOR.

	if Gerenciador.has_method("salvar_estrelas_fase_3"):

		Gerenciador.salvar_estrelas_fase_3(
			estrelas_finais
		)

	else:

		push_warning(
			"Gerenciador não possui salvar_estrelas_fase_3()."
		)

	print("==============================")
	print("FASE 3 CONCLUÍDA!")
	print("Pontos: ", pontos, "/30")
	print("Acertos: ", acertos, "/10")
	print("Estrelas: ", estrelas_finais, "/3")
	print("Tempo: ", segundos, " segundos")
	print("==============================")

	await get_tree().create_timer(3.0).timeout

	# Evita trocar de cena se o jogador já clicou em Voltar.
	if not is_inside_tree():
		return

	Transicao.voltar_aventura()

# ==================================================
# EFEITO DE CONFETES - RESPOSTA CORRETA
# ==================================================

func _efeito_confetes() -> void:

	var camada_confetes := Node2D.new()
	camada_confetes.name = "CamadaConfetes"
	add_child(camada_confetes)

	var tamanho_tela: Vector2 = get_viewport_rect().size

	var cores: Array[Color] = [
		Color("#FFD45A"),
		Color("#FF5C8A"),
		Color("#65E6A5"),
		Color("#55C7FF"),
		Color("#B58AFF"),
		Color("#FFFFFF")
	]

	for i in range(45):

		var confete := ColorRect.new()

		confete.size = Vector2(
			randf_range(6.0, 11.0),
			randf_range(10.0, 18.0)
		)

		confete.position = Vector2(
			randf_range(0.0, tamanho_tela.x),
			randf_range(-180.0, -20.0)
		)

		confete.color = cores[randi() % cores.size()]
		confete.rotation = randf_range(-0.5, 0.5)

		camada_confetes.add_child(confete)

		var destino := Vector2(
			confete.position.x + randf_range(-100.0, 100.0),
			tamanho_tela.y + randf_range(40.0, 180.0)
		)

		var duracao := randf_range(0.75, 1.15)

		var tween := create_tween()
		tween.set_parallel(true)

		tween.tween_property(
			confete,
			"position",
			destino,
			duracao
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

		tween.tween_property(
			confete,
			"rotation",
			confete.rotation + randf_range(-4.0, 4.0),
			duracao
		)

		tween.tween_property(
			confete,
			"modulate:a",
			0.0,
			duracao
		)

	await get_tree().create_timer(0.85).timeout

	camada_confetes.queue_free()


# ==================================================
# EFEITO DE ERRO - PISCAR E TREMER
# ==================================================

func _efeito_visual_erro(indice: int) -> void:

	if indice < 0 or indice >= botoes.size():
		return

	var botao := botoes[indice]

	var posicao_original: Vector2 = botao.position
	var cor_original: Color = botao.modulate

	# PISCAR EM VERMELHO.
	var tween_cor := create_tween()

	for i in range(3):

		tween_cor.tween_property(
			botao,
			"modulate",
			Color("#FF7777"),
			0.08
		)

		tween_cor.tween_property(
			botao,
			"modulate",
			Color("#FF2222"),
			0.08
		)

	# TREMER RAPIDAMENTE.
	var tween_tremor := create_tween()

	tween_tremor.tween_property(
		botao,
		"position",
		posicao_original + Vector2(-7, 0),
		0.045
	)

	tween_tremor.tween_property(
		botao,
		"position",
		posicao_original + Vector2(7, 0),
		0.045
	)

	tween_tremor.tween_property(
		botao,
		"position",
		posicao_original + Vector2(-5, 0),
		0.045
	)

	tween_tremor.tween_property(
		botao,
		"position",
		posicao_original + Vector2(5, 0),
		0.045
	)

	tween_tremor.tween_property(
		botao,
		"position",
		posicao_original,
		0.045
	)

	await tween_tremor.finished

	# GARANTE QUE O BOTÃO VOLTE À POSIÇÃO E À COR ORIGINAIS.
	botao.position = posicao_original
	botao.modulate = cor_original


# ==================================================
# BOTÃO VOLTAR AO MODO AVENTURA
# ==================================================

func _voltar_aventura() -> void:

	Audio.tocar_click()

	# Retornar ao mapa da aventura com explosão de fumaça.
	Transicao.voltar_aventura()
