extends Node2D

# ==================================
# CONFIGURAÇÕES
# ==================================

const PECAS := ["B", "V", "BV"]
const TOTAL_CASAS := 9
const TOTAL_DESAFIOS := 5
const TEMPO_DESTAQUE_ERRO := 2.0
const CENA_AVENTURA := "res://scenes/Aventura.tscn"

# Efeito de quebra (estilhaços)
const ESTILHACO_COLUNAS := 4
const ESTILHACO_LINHAS := 4
const GRAVIDADE_ESTILHACO := 1500.0

@onready var botao_voltar: TextureButton = find_child(
	"Voltar",
	true,
	false
) as TextureButton


# ==================================
# GABARITOS DOS DESAFIOS
# ==================================

const DESAFIOS_TIPOS: Array = [
	# DESAFIO 1
	[
		"BV", "B", "BV",
		"B", "V", "B",
		"BV", "B", "BV"
	],

	# DESAFIO 2
	[
		"BV", "BV", "BV",
		"BV", "BV", "BV",
		"BV", "BV", "BV"
	],

	# DESAFIO 3
	[
		"BV", "BV", "BV",
		"BV", "V", "BV",
		"BV", "BV", "BV"
	],

	# DESAFIO 4
	[
		"BV", "BV", "BV",
		"BV", "BV", "BV",
		"BV", "BV", "BV"
	],

	# DESAFIO 5
	[
		"BV", "BV", "BV",
		"BV", "BV", "BV",
		"BV", "BV", "BV"
	]
]

const DESAFIOS_ROTACOES: Array = [
	# DESAFIO 1
	[
		270, 0, 0,
		0, 0, 0,
		180, 0, 90
	],

	# DESAFIO 2
	[
		180, 270, 90,
		180, 0, 180,
		90, 270, 180
	],

	# DESAFIO 3
	[
		180, 270, 270,
		180, 0, 0,
		90, 90, 0
	],

	# DESAFIO 4
	[
		270, 90, 270,
		90, 270, 90,
		270, 90, 270
	],

	# DESAFIO 5
	[
		270, 180, 0,
		0, 90, 270,
		180, 270, 90
	]
]


# ==================================
# REFERÊNCIAS DOS NÓS
# ==================================

var grade: GridContainer
var botao_girar: TextureButton
var botao_desfazer: TextureButton
var botao_verificar: TextureButton

var botoes_inventario: Array[TextureButton] = []

var painel_referencias: TextureRect
var painel_inventario: TextureRect

var label_pontos: Label
var label_pip: Label
var label_tempo: Label
var label_tentativas: Label
var cronometro: Timer


# ==================================
# VARIÁVEIS DO JOGO
# ==================================

var casas: Array[Button] = []
var historico: Array[Dictionary] = []

var peca_selecionada: String = ""
var ultima_casa_selecionada: int = -1

var desafio_atual: int = 0

var verificacao_realizada: bool = false
var processando_conclusao: bool = false


# ==================================
# SISTEMA DE PONTUAÇÃO
# ==================================

var tentativas_desafio: int = 0
var desafios_acertados_primeira: int = 0
var pontos_acumulados: int = 0


# ==================================
# CRONÔMETRO
# ==================================

var segundos_decorridos: int = 0
var identificador_verificacao: int = 0


# ==================================
# EFEITOS VISUAIS
# ==================================

var posicao_original: Vector2
var tween_tremor: Tween


# ==================================
# INICIALIZAÇÃO
# ==================================

func _ready() -> void:

	posicao_original = position

	grade = find_child("GridContainer", true, false) as GridContainer

	painel_inventario = find_child("TextureRect", true, false) as TextureRect
	painel_referencias = find_child("TextureRect2", true, false) as TextureRect

	botao_girar = find_child("b-g", true, false) as TextureButton
	botao_desfazer = find_child("b-d", true, false) as TextureButton
	botao_verificar = find_child("TextureButton", true, false) as TextureButton

	label_pip = $"Background/TextureRect5/Label"

	label_pontos = $"Background/barra-estrelas/pontos"

	cronometro = $"Background/TextureRect3/Timer"
	label_tempo = $"Background/TextureRect3/Label"

	var painel_tentativas := find_child("TextureRect4", true, false)

	if painel_tentativas != null:
		label_tentativas = painel_tentativas.get_node_or_null("Label") as Label

	if label_tentativas == null:
		push_warning("Label de tentativas não encontrado!")

	# CONECTAR BOTÃO VOLTAR AO MODO AVENTURA
	if botao_voltar != null:
		if not botao_voltar.pressed.is_connected(_voltar_aventura):
			botao_voltar.pressed.connect(_voltar_aventura)
	else:
		push_error("Botão Voltar não encontrado!")

	# VERIFICAR NÓS

	if grade == null:
		push_error("GridContainer não encontrado!")
		return

	if painel_inventario == null:
		push_error("Painel do inventário não encontrado!")
		return

	if painel_referencias == null:
		push_error("Painel das referências não encontrado!")
		return

	if botao_girar == null:
		push_error("Botão b-g não encontrado!")
		return

	if botao_desfazer == null:
		push_error("Botão b-d não encontrado!")
		return

	if botao_verificar == null:
		push_error("Botão Verificar não encontrado!")
		return

	if label_pip == null:
		push_error("Label do Pip não encontrado!")
		return

	if label_pontos == null:
		push_error("Label pontos não encontrado!")
		return

	if cronometro == null or label_tempo == null:
		push_error("Cronômetro ou Label do tempo não encontrado!")
		return

	label_pip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	_configurar_grade()
	_configurar_cronometro()

	_conectar_inventario()
	_conectar_botoes()

	criar_tabuleiro()
	_atualizar_imagem_referencia()
	_atualizar_tentativas()

	pontos_acumulados = 0

	label_pontos.text = "           0/15"

	_fala_pip(
		"Olá! Vamos resolver os desafios juntos? Observe a figura de referência!"
	)

	_iniciar_cronometro()

	print("Fase 2 inicializada!")


# ==================================
# ATALHOS DE TECLADO
# ==================================

func _unhandled_input(event: InputEvent) -> void:

	if event is InputEventKey and event.pressed and not event.echo:

		if event.keycode == KEY_R:
			_girar_ultima_peca()
			get_viewport().set_input_as_handled()


# ==================================
# CONFIGURAÇÃO DA GRADE
# ==================================

func _configurar_grade() -> void:

	grade.columns = 3

	grade.add_theme_constant_override("h_separation", 2)
	grade.add_theme_constant_override("v_separation", 2)


# ==================================
# CRONÔMETRO
# ==================================

func _configurar_cronometro() -> void:

	cronometro.wait_time = 1.0
	cronometro.one_shot = false

	if not cronometro.timeout.is_connected(_ao_passar_segundo):
		cronometro.timeout.connect(_ao_passar_segundo)


func _iniciar_cronometro() -> void:

	segundos_decorridos = 0

	_atualizar_tempo_visual()

	cronometro.stop()
	cronometro.start()


func _ao_passar_segundo() -> void:

	segundos_decorridos += 1

	_atualizar_tempo_visual()


func _atualizar_tempo_visual() -> void:

	var minutos: int = int(segundos_decorridos / 60)
	var segundos: int = segundos_decorridos % 60

	label_tempo.text = "%02d:%02d" % [minutos, segundos]


# ==================================
# FALAS DO PIP
# ==================================

func _fala_pip(mensagem: String) -> void:

	if label_pip != null:
		label_pip.text = mensagem


# ==================================
# TENTATIVAS
# ==================================

func _atualizar_tentativas() -> void:

	if label_tentativas != null:
		label_tentativas.text = str(tentativas_desafio)


func _obter_dica() -> String:

	match tentativas_desafio:

		1:
			return "Observe as diagonais e compare com a imagem de referência!"

		2:
			return "Confira a direção das peças. Algumas podem precisar de rotação."

		3:
			return "Observe principalmente os cantos e o centro do tabuleiro."

		_:
			return "Continue analisando cada posição. Você consegue!"


# ==================================
# CRIAÇÃO DAS CASAS
# ==================================

func criar_tabuleiro() -> void:

	for filho in grade.get_children():
		filho.queue_free()

	casas.clear()

	for i in range(TOTAL_CASAS):

		var casa := Button.new()

		casa.name = "Casa" + str(i + 1)

		casa.custom_minimum_size = Vector2(0, 0)

		casa.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		casa.size_flags_vertical = Control.SIZE_EXPAND_FILL

		casa.flat = true
		casa.focus_mode = Control.FOCUS_NONE

		casa.pressed.connect(_ao_clicar_casa.bind(i))

		grade.add_child(casa)
		casas.append(casa)


# ==================================
# INVENTÁRIO
# ==================================

func _conectar_inventario() -> void:

	botoes_inventario = [
		painel_inventario.find_child("b-1", true, false) as TextureButton,
		painel_inventario.find_child("b-2", true, false) as TextureButton,
		painel_inventario.find_child("b-3", true, false) as TextureButton
	]

	for i in range(botoes_inventario.size()):

		if botoes_inventario[i] == null:
			push_error("Botão de inventário não encontrado: b-" + str(i + 1))
			continue

		botoes_inventario[i].pressed.connect(
			_selecionar_peca.bind(PECAS[i])
		)


func _selecionar_peca(tipo: String) -> void:

	if processando_conclusao:
		return

	peca_selecionada = tipo

	_atualizar_destaque_inventario()

	print("Peça selecionada: ", tipo)


func _atualizar_destaque_inventario() -> void:

	for i in range(botoes_inventario.size()):

		var botao := botoes_inventario[i]

		if botao == null:
			continue

		if peca_selecionada != "" and PECAS[i] == peca_selecionada:
			botao.modulate = Color(1.3, 1.3, 1.3)
		else:
			botao.modulate = Color.WHITE


# ==================================
# COLOCAÇÃO E SUBSTITUIÇÃO
# ==================================

func _ao_clicar_casa(indice: int) -> void:

	if processando_conclusao:
		return

	if peca_selecionada == "":
		print("Selecione uma peça primeiro.")
		return

	var peca_existente := _obter_peca(indice)

	if peca_existente != null:

		historico.append({
			"tipo": "substituir",
			"indice": indice,
			"face": peca_existente.face_atual,
			"rotacao": peca_existente.rotacao
		})

		peca_existente.definir_face(peca_selecionada)
		peca_existente.definir_rotacao(0)
		peca_existente.modulate = Color.WHITE

	else:

		_adicionar_peca(indice, peca_selecionada, 0)

	ultima_casa_selecionada = indice
	peca_selecionada = ""
	verificacao_realizada = false

	_atualizar_destaque_inventario()


func _adicionar_peca(
	indice: int,
	tipo: String,
	rotacao: int
) -> void:

	var peca := CuboFace.new()

	peca.configurar(indice, tipo, true)
	peca.definir_rotacao(rotacao)

	peca.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	peca.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	peca.size_flags_vertical = Control.SIZE_EXPAND_FILL

	peca.clicado.connect(_ao_clicar_peca)

	casas[indice].add_child(peca)

	historico.append({
		"tipo": "colocar",
		"indice": indice
	})


# ==================================
# CLIQUE DIRETO NA PEÇA
# ==================================

func _ao_clicar_peca(
	indice: int,
	botao_mouse: int
) -> void:

	if processando_conclusao:
		return

	var peca := _obter_peca(indice)

	if peca == null:
		return

	ultima_casa_selecionada = indice

	if peca_selecionada != "" and botao_mouse == MOUSE_BUTTON_LEFT:

		historico.append({
			"tipo": "substituir",
			"indice": indice,
			"face": peca.face_atual,
			"rotacao": peca.rotacao
		})

		peca.definir_face(peca_selecionada)
		peca.definir_rotacao(0)
		peca.modulate = Color.WHITE

		peca_selecionada = ""
		verificacao_realizada = false

		_atualizar_destaque_inventario()

		return

	if botao_mouse == MOUSE_BUTTON_LEFT:
		_rotacionar_peca(indice, 90)

	elif botao_mouse == MOUSE_BUTTON_RIGHT:
		_rotacionar_peca(indice, -90)


# ==================================
# ROTAÇÃO
# ==================================

func _rotacionar_peca(
	indice: int,
	graus: int
) -> void:

	if processando_conclusao:
		return

	var peca := _obter_peca(indice)

	if peca == null:
		return

	# Peças inteiras (B e V) não mudam visualmente ao girar,
	# então não rotacionam nem entram no histórico do desfazer
	if peca.face_atual == "B" or peca.face_atual == "V":
		return

	historico.append({
		"tipo": "rotacionar",
		"indice": indice,
		"rotacao": peca.rotacao
	})

	peca.rotacionar(graus)

	# Remove o destaque vermelho de erro ao mexer na peça
	peca.modulate = Color.WHITE

	ultima_casa_selecionada = indice
	verificacao_realizada = false


# ==================================
# LOCALIZAR PEÇA
# ==================================

func _obter_peca(indice: int) -> CuboFace:

	if indice < 0 or indice >= casas.size():
		return null

	var casa := casas[indice]

	for filho in casa.get_children():

		if filho is CuboFace:
			return filho

	return null


# ==================================
# BOTÕES
# ==================================

func _conectar_botoes() -> void:

	botao_girar.pressed.connect(_girar_ultima_peca)
	botao_desfazer.pressed.connect(desfazer)
	botao_verificar.pressed.connect(verificar_tabuleiro)


func _girar_ultima_peca() -> void:

	if processando_conclusao:
		return

	if ultima_casa_selecionada >= 0:

		_rotacionar_peca(
			ultima_casa_selecionada,
			90
		)

	else:

		print("Nenhuma peça selecionada.")


# ==================================
# DESFAZER
# ==================================

func desfazer() -> void:

	if processando_conclusao:
		return

	if historico.is_empty():
		print("Não há jogadas para desfazer.")
		return

	var acao: Dictionary = historico.pop_back()
	var indice: int = acao["indice"]

	match acao["tipo"]:

		"colocar":

			var peca := _obter_peca(indice)

			if peca != null:
				peca.queue_free()

		"substituir":

			var peca := _obter_peca(indice)

			if peca != null:

				peca.definir_face(acao["face"])
				peca.definir_rotacao(acao["rotacao"])
				peca.modulate = Color.WHITE

		"rotacionar":

			var peca := _obter_peca(indice)

			if peca != null:
				peca.definir_rotacao(acao["rotacao"])

	verificacao_realizada = false
	ultima_casa_selecionada = -1


# ==================================
# VERIFICAR TABULEIRO
# ==================================

func verificar_tabuleiro() -> void:

	if processando_conclusao:
		return

	for i in range(TOTAL_CASAS):

		if _obter_peca(i) == null:
			_fala_pip("Ainda faltam peças! Complete o tabuleiro primeiro.")
			return

	var solucao_tipos: Array = DESAFIOS_TIPOS[desafio_atual]
	var solucao_rotacoes: Array = DESAFIOS_ROTACOES[desafio_atual]

	if solucao_tipos.size() != TOTAL_CASAS or solucao_rotacoes.size() != TOTAL_CASAS:
		push_error("Gabarito incompleto!")
		return

	tentativas_desafio += 1
	_atualizar_tentativas()

	var erros := 0
	var pecas_com_erro: Array[CuboFace] = []

	for i in range(TOTAL_CASAS):

		var peca := _obter_peca(i)

		var tipo_correto: bool = (
			peca.face_atual == solucao_tipos[i]
		)

		var rotacao_correta: bool

		if peca.face_atual == "B" or peca.face_atual == "V":
			# Peças inteiras são iguais em qualquer rotação
			rotacao_correta = true
		else:
			# posmod normaliza valores como -90 para 270
			rotacao_correta = (
				posmod(peca.rotacao, 360) == solucao_rotacoes[i]
			)

		if tipo_correto and rotacao_correta:

			peca.modulate = Color.WHITE

		else:

			peca.modulate = Color("#FF3333")
			pecas_com_erro.append(peca)
			erros += 1

	verificacao_realizada = true

	# ==================================
	# ACERTO
	# ==================================

	if erros == 0:

		# SOM DE ACERTO
		Audio.tocar_acerto()

		var pontos_desafio: int = maxi(
			0,
			3 - (tentativas_desafio - 1)
		)

		pontos_acumulados += pontos_desafio

		if tentativas_desafio == 1:
			desafios_acertados_primeira += 1

		_atualizar_pontuacao()

		_fala_pip(
			"Excelente! Você conseguiu! Ganhou "
			+ str(pontos_desafio)
			+ " pontos neste desafio!"
		)

		await _animar_conclusao()
		return

	# ==================================
	# ERRO
	# ==================================

	# SOM DE ERRO
	Audio.tocar_erro()

	_fala_pip(
		"Ops! "
		+ str(erros)
		+ (" peça precisa" if erros == 1 else " peças precisam")
		+ " de ajuste! "
		+ _obter_dica()
	)

	identificador_verificacao += 1

	var verificacao_atual: int = identificador_verificacao

	await _efeito_visual_erro(pecas_com_erro)

	await get_tree().create_timer(TEMPO_DESTAQUE_ERRO).timeout

	if verificacao_atual == identificador_verificacao:
		limpar_destaques()


# ==================================
# CALCULAR ESTRELAS
# ==================================

func _calcular_estrelas() -> int:

	if desafios_acertados_primeira == 5:
		return 3

	if desafios_acertados_primeira >= 4:
		return 2

	if desafios_acertados_primeira >= 3:
		return 1

	return 0


# ==================================
# ATUALIZAR PONTUAÇÃO
# ==================================

func _atualizar_pontuacao() -> void:

	pontos_acumulados = clampi(pontos_acumulados, 0, 15)

	label_pontos.text = "           " + str(pontos_acumulados) + "/15"


# ==================================
# ANIMAÇÃO DE CONCLUSÃO
# ==================================

func _animar_conclusao() -> void:

	processando_conclusao = true
	botao_verificar.disabled = true

	# O tempo para durante a comemoração
	cronometro.stop()

	# COMEMORAÇÃO

	_fala_pip("🎉 PARABÉNS! VOCÊ CONSEGUIU! 🎉")

	_criar_confetes()
	_vibrar_dispositivo()

	# Remove o destaque vermelho antes da quebra
	limpar_destaques()

	# SACUDIDA DA TELA

	await _sacudir_tela()

	await get_tree().create_timer(0.15).timeout

	# QUEBRA REALISTA

	await _estilhacar_pecas()

	await get_tree().create_timer(1.0).timeout

	# Se a cena mudou durante a animação, para por aqui
	if not is_inside_tree():
		return

	# LIMPAR TABULEIRO

	for casa in casas:

		for filho in casa.get_children():
			filho.queue_free()

	historico.clear()

	peca_selecionada = ""
	ultima_casa_selecionada = -1
	verificacao_realizada = false

	_atualizar_destaque_inventario()

	# PRÓXIMO DESAFIO

	if desafio_atual < TOTAL_DESAFIOS - 1:

		desafio_atual += 1
		tentativas_desafio = 0
		_atualizar_tentativas()

		_atualizar_imagem_referencia()
		_iniciar_cronometro()

		_fala_pip(
			"Parabéns! Vamos para o desafio "
			+ str(desafio_atual + 1)
			+ "!"
		)

		botao_verificar.disabled = false
		processando_conclusao = false

	else:

		await _finalizar_fase()


# ==================================
# FINALIZAR FASE
# ==================================

func _finalizar_fase() -> void:

	cronometro.stop()

	var estrelas_finais: int = _calcular_estrelas()

	Gerenciador.salvar_estrelas_fase_2(estrelas_finais)

	_fala_pip(
		"Você concluiu os cinco desafios! "
		+ "Conquistou "
		+ str(pontos_acumulados)
		+ " de 15 pontos!"
	)

	print("=================================")
	print("FASE 2 CONCLUÍDA!")
	print("Pontos: ", pontos_acumulados, "/15")
	print("Acertos de primeira: ", desafios_acertados_primeira)
	print("Estrelas finais: ", estrelas_finais)
	print("=================================")

	await get_tree().create_timer(3.0).timeout

	# Evita trocar de cena duas vezes (ex.: jogador clicou em Voltar)
	if not is_inside_tree():
		return

	Transicao.voltar_aventura()

# ==================================
# ATUALIZAR IMAGEM DE REFERÊNCIA
# ==================================

func _atualizar_imagem_referencia() -> void:

	for i in range(TOTAL_DESAFIOS):

		var nome: String = "I-" + str(i + 1)

		var imagem := painel_referencias.get_node_or_null(nome)

		if imagem != null:

			imagem.visible = (i == desafio_atual)

		else:

			push_warning("Imagem não encontrada: " + nome)


# ==================================
# LIMPAR DESTAQUES
# ==================================

func limpar_destaques() -> void:

	for i in range(TOTAL_CASAS):

		var peca := _obter_peca(i)

		if peca != null:
			peca.modulate = Color.WHITE


# ==================================
# CONFETES DA COMEMORAÇÃO
# ==================================

func _criar_confetes() -> void:

	var camada := Node2D.new()
	camada.name = "Confetes"
	add_child(camada)

	var tamanho_tela := get_viewport_rect().size

	var cores: Array[Color] = [
		Color("#FFD700"),
		Color("#FF4D6D"),
		Color("#55E6A5"),
		Color("#54B8FF"),
		Color("#C77DFF"),
		Color.WHITE
	]

	for i in range(55):

		var confete := ColorRect.new()

		confete.size = Vector2(
			randf_range(7.0, 13.0),
			randf_range(10.0, 19.0)
		)

		confete.color = cores[randi_range(0, cores.size() - 1)]

		confete.position = Vector2(
			randf_range(0.0, tamanho_tela.x),
			randf_range(-150.0, -20.0)
		)

		camada.add_child(confete)

		var destino := Vector2(
			confete.position.x + randf_range(-150.0, 150.0),
			tamanho_tela.y + 100.0
		)

		var duracao := randf_range(1.2, 2.2)

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
			randf_range(-8.0, 8.0),
			duracao
		)

		tween.tween_property(
			confete,
			"modulate:a",
			0.0,
			duracao
		).set_delay(0.7)

	await get_tree().create_timer(2.5).timeout

	if is_instance_valid(camada):
		camada.queue_free()


# ==================================
# SACUDIDA DA TELA NO ACERTO
# ==================================

func _sacudir_tela() -> void:

	if tween_tremor != null and tween_tremor.is_running():
		tween_tremor.kill()

	position = posicao_original

	tween_tremor = create_tween()

	var intensidade := 9.0

	for i in range(7):

		var deslocamento := Vector2(
			randf_range(-intensidade, intensidade),
			randf_range(-intensidade, intensidade)
		)

		tween_tremor.tween_property(
			self,
			"position",
			posicao_original + deslocamento,
			0.035
		)

	tween_tremor.tween_property(
		self,
		"position",
		posicao_original,
		0.10
	)

	await tween_tremor.finished


# ==================================
# QUEBRA REALISTA (ESTILHAÇOS)
# ==================================

func _estilhacar_pecas() -> void:

	var pecas: Array[CuboFace] = []

	for i in range(TOTAL_CASAS):

		var peca := _obter_peca(i)

		if peca != null:
			peca.modulate = Color.WHITE
			pecas.append(peca)

	if pecas.is_empty():
		return

	# Espera o frame ser desenhado para capturar a imagem real das peças
	await RenderingServer.frame_post_draw

	var imagem: Image = get_viewport().get_texture().get_image()
	var escala: Vector2 = Vector2(imagem.get_size()) / get_viewport_rect().size

	var camada := CanvasLayer.new()
	camada.layer = 10
	add_child(camada)

	for peca in pecas:

		var retangulo := _retangulo_na_tela(peca)
		var retangulo_px := Rect2i(
			Vector2i(retangulo.position * escala),
			Vector2i(retangulo.size * escala)
		)

		# Se a peça estiver fora da imagem capturada, apenas some
		if not Rect2i(Vector2i.ZERO, imagem.get_size()).encloses(retangulo_px):
			peca.visible = false
			continue

		var textura := ImageTexture.create_from_image(
			imagem.get_region(retangulo_px)
		)

		_criar_estilhacos(retangulo, escala, textura, camada)
		_criar_poeira(retangulo.get_center(), camada)

		peca.visible = false

	# Remove a camada depois que tudo terminou
	get_tree().create_timer(3.0).timeout.connect(camada.queue_free)


func _retangulo_na_tela(peca: Control) -> Rect2:

	var t := peca.get_global_transform_with_canvas()

	var retangulo := Rect2(t * Vector2.ZERO, Vector2.ZERO)
	retangulo = retangulo.expand(t * Vector2(peca.size.x, 0))
	retangulo = retangulo.expand(t * Vector2(0, peca.size.y))
	retangulo = retangulo.expand(t * peca.size)

	return retangulo


func _criar_estilhacos(
	retangulo: Rect2,
	escala: Vector2,
	textura: Texture2D,
	camada: CanvasLayer
) -> void:

	var tam := retangulo.size
	var pontos: Array[Vector2] = []

	# Grade irregular: só os pontos internos são deslocados
	for l in range(ESTILHACO_LINHAS + 1):
		for c in range(ESTILHACO_COLUNAS + 1):

			var p := Vector2(
				tam.x * c / float(ESTILHACO_COLUNAS),
				tam.y * l / float(ESTILHACO_LINHAS)
			)

			if c > 0 and c < ESTILHACO_COLUNAS and l > 0 and l < ESTILHACO_LINHAS:
				p += Vector2(
					randf_range(-0.38, 0.38) * tam.x / ESTILHACO_COLUNAS,
					randf_range(-0.38, 0.38) * tam.y / ESTILHACO_LINHAS
				)

			pontos.append(p)

	var colunas := ESTILHACO_COLUNAS + 1

	for l in range(ESTILHACO_LINHAS):
		for c in range(ESTILHACO_COLUNAS):

			var a: Vector2 = pontos[l * colunas + c]
			var b: Vector2 = pontos[l * colunas + c + 1]
			var d: Vector2 = pontos[(l + 1) * colunas + c]
			var e: Vector2 = pontos[(l + 1) * colunas + c + 1]

			# Diagonal aleatória para parecer mais natural
			if randf() < 0.5:
				_criar_caco([a, b, e], retangulo, escala, textura, camada)
				_criar_caco([a, e, d], retangulo, escala, textura, camada)
			else:
				_criar_caco([a, b, d], retangulo, escala, textura, camada)
				_criar_caco([b, e, d], retangulo, escala, textura, camada)


func _criar_caco(
	triangulo: Array,
	retangulo: Rect2,
	escala: Vector2,
	textura: Texture2D,
	camada: CanvasLayer
) -> void:

	var centro_caco: Vector2 = (triangulo[0] + triangulo[1] + triangulo[2]) / 3.0

	var poligono := PackedVector2Array()
	var uv := PackedVector2Array()

	for p in triangulo:
		poligono.append(p - centro_caco)
		uv.append(p * escala)

	var caco := Polygon2D.new()
	caco.texture = textura
	caco.polygon = poligono
	caco.uv = uv

	var inicio: Vector2 = retangulo.position + centro_caco
	caco.position = inicio

	camada.add_child(caco)

	# Cacos mais afastados do centro saem para fora
	var direcao: Vector2 = (centro_caco - retangulo.size * 0.5).normalized()

	if direcao == Vector2.ZERO:
		direcao = Vector2.from_angle(randf() * TAU)

	var velocidade: Vector2 = direcao * randf_range(120.0, 380.0)
	velocidade.y -= randf_range(120.0, 340.0)

	var giro: float = randf_range(-6.0, 6.0)
	var duracao: float = randf_range(0.9, 1.4)

	var tween := caco.create_tween()
	tween.set_parallel(true)

	tween.tween_method(
		_mover_caco.bind(caco, inicio, velocidade, giro),
		0.0,
		duracao,
		duracao
	)

	tween.tween_property(
		caco, "modulate:a", 0.0, duracao * 0.4
	).set_delay(duracao * 0.6)

	tween.chain().tween_callback(caco.queue_free)


func _mover_caco(
	t: float,
	caco: Polygon2D,
	inicio: Vector2,
	velocidade: Vector2,
	giro: float
) -> void:

	if not is_instance_valid(caco):
		return

	caco.position = (
		inicio
		+ velocidade * t
		+ Vector2(0, 0.5 * GRAVIDADE_ESTILHACO * t * t)
	)

	caco.rotation = giro * t


func _criar_poeira(posicao_poeira: Vector2, camada: CanvasLayer) -> void:

	var poeira := CPUParticles2D.new()
	poeira.position = posicao_poeira
	poeira.amount = 16
	poeira.lifetime = 0.8
	poeira.one_shot = true
	poeira.explosiveness = 1.0
	poeira.spread = 180.0
	poeira.initial_velocity_min = 40.0
	poeira.initial_velocity_max = 170.0
	poeira.gravity = Vector2(0, 160)
	poeira.scale_amount_min = 2.0
	poeira.scale_amount_max = 5.0

	var gradiente := Gradient.new()
	gradiente.set_color(0, Color(0.9, 0.9, 0.9, 0.7))
	gradiente.set_color(1, Color(0.9, 0.9, 0.9, 0.0))
	poeira.color_ramp = gradiente

	camada.add_child(poeira)
	poeira.emitting = true


# ==================================
# VIBRAÇÃO DOS DISPOSITIVOS
# ==================================

func _vibrar_dispositivo() -> void:

	if OS.has_feature("mobile"):
		Input.vibrate_handheld(150)

	for dispositivo in Input.get_connected_joypads():

		Input.start_joy_vibration(
			dispositivo,
			0.4,
			0.8,
			0.25
		)


# ==================================
# EFEITO VISUAL DE ERRO
# ==================================

func _efeito_visual_erro(pecas_com_erro: Array[CuboFace]) -> void:

	for peca in pecas_com_erro:

		if not is_instance_valid(peca):
			continue

		peca.modulate = Color("#FF3333")

		# Escala a partir do centro da peça
		peca.pivot_offset = peca.size / 2.0

		var escala_original := peca.scale
		var tween := create_tween()

		tween.set_parallel(true)

		# AUMENTA A PEÇA

		tween.tween_property(
			peca,
			"scale",
			escala_original * 1.15,
			0.12
		).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

		# PULSA EM VERMELHO

		tween.tween_property(
			peca,
			"modulate",
			Color("#FF9999"),
			0.12
		)

		# VOLTA AO TAMANHO ORIGINAL E AO VERMELHO DE ERRO

		tween.chain()

		tween.tween_property(
			peca,
			"scale",
			escala_original,
			0.15
		).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

		tween.parallel().tween_property(
			peca,
			"modulate",
			Color("#FF3333"),
			0.15
		)

	# SACUDIDA DA TELA

	await _sacudir_tela_erro()


# ==================================
# SACUDIDA DA TELA AO ERRAR
# ==================================

func _sacudir_tela_erro() -> void:

	if tween_tremor != null and tween_tremor.is_running():
		tween_tremor.kill()

	position = posicao_original

	tween_tremor = create_tween()

	var intensidade := 4.0

	for i in range(5):

		var deslocamento := Vector2(
			randf_range(-intensidade, intensidade),
			randf_range(-intensidade, intensidade)
		)

		tween_tremor.tween_property(
			self,
			"position",
			posicao_original + deslocamento,
			0.035
		)

	tween_tremor.tween_property(
		self,
		"position",
		posicao_original,
		0.08
	)

	await tween_tremor.finished


# ==================================
# BOTÃO VOLTAR AO MODO AVENTURA
# ==================================

func _voltar_aventura() -> void:

	# Som de clique.
	Audio.tocar_click()

	# Para o cronômetro e qualquer tremor em andamento.
	cronometro.stop()

	if tween_tremor != null:
		tween_tremor.kill()

	position = posicao_original

	# Retornar ao mapa da aventura com explosão de fumaça.
	Transicao.voltar_aventura()
