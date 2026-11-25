extends Node2D

# ==================================================
# CONFIGURAÇÕES
# ==================================================

const TOTAL_DESAFIOS := 3
const TOTAL_CARTAS := 3
const PONTOS_POR_DESAFIO := 3

const PASTA_CARTAS := "res://Assets/FASES/"
const CENA_AVENTURA := "res://scenes/Aventura.tscn"

@onready var botao_voltar: TextureButton = find_child(
	"Voltar",
	true,
	false
) as TextureButton

# Ordem correta das imagens em cada desafio.
# 1º painel = imagem 3
# 2º painel = imagem 2
# 3º painel = imagem 1

const GABARITOS := [
	[3, 2, 1],
	[3, 2, 1],
	[3, 2, 1]
]

# ==================================================
# NÓS
# ==================================================

var cartas: Array[TextureRect] = []
var paineis: Array[Panel] = []

var botao_verificar: TextureButton

var painel_pip: Control
var label_pip: Label
var label_pontos: Label
var label_estrelas: Label
var label_tentativas: Label

# CRONÔMETRO
var label_tempo: Label
var segundos_decorridos: int = 0
var acumulador_tempo: float = 0.0
var cronometro_ativo: bool = false

# ==================================================
# ESTADO DO JOGO
# ==================================================

var desafio_atual: int = 0
var tentativas_desafio: int = 0
var total_tentativas: int = 0

var pontos: int = 0
var acertos_primeira: int = 0

var jogo_finalizado: bool = false
var processando: bool = false

var ids_cartas: Array[int] = [1, 2, 3]

var carta_no_painel: Array[int] = [-1, -1, -1]
var painel_da_carta: Array[int] = [-1, -1, -1]

var posicoes_originais: Array[Vector2] = []
var posicoes_slots: Array[Vector2] = []

var carta_arrastada: int = -1
var deslocamento_mouse: Vector2 = Vector2.ZERO

# ==================================================
# INICIALIZAÇÃO
# ==================================================

func _ready() -> void:

	randomize()

	# Garante que nenhum nó decorativo bloqueie o clique nos botões.
	_ignorar_mouse_nos_decorativos(self)

	# CONECTAR BOTÃO VOLTAR AO MODO AVENTURA.
	if botao_voltar != null:

		# Traz o botão para a frente de tudo.
		botao_voltar.z_index = 100
		botao_voltar.move_to_front()

		if not botao_voltar.pressed.is_connected(_voltar_aventura):
			botao_voltar.pressed.connect(_voltar_aventura)
	else:
		push_error("Botão Voltar não encontrado!")

	_localizar_nos()

	if cartas.size() != TOTAL_CARTAS:
		push_error("As três cartas B-1, B-2 e B-3 não foram encontradas!")
		return

	if paineis.size() != TOTAL_CARTAS:
		push_error("Os três painéis P-1, P-2 e P-3 não foram encontrados!")
		return

	_guardar_posicoes_originais()

	_deixar_paineis_transparentes()

	if not _validar_nos():
		return

	_configurar_painel_pip()

	_conectar_botao()

	_atualizar_pontuacao()
	_atualizar_tentativas()

	_fala_pip(
		"Olá! Organize as três cartas na sequência correta!"
	)

	# O cronômetro começa junto com a primeira animação de embaralhar.
	_iniciar_cronometro()

	await _carregar_desafio()

	print("FASE 4 INICIALIZADA!")


# ==================================================
# IGNORAR MOUSE EM NÓS DECORATIVOS
# ==================================================

func _ignorar_mouse_nos_decorativos(no: Node) -> void:

	for filho in no.get_children():

		if filho is Control and not (filho is BaseButton):
			(filho as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE

		_ignorar_mouse_nos_decorativos(filho)


# ==================================================
# LOCALIZAR NÓS
# ==================================================

func _localizar_nos() -> void:

	cartas.clear()
	paineis.clear()

	for i in range(1, TOTAL_CARTAS + 1):

		var carta := find_child(
			"B-" + str(i),
			true,
			false
		) as TextureRect

		var painel := find_child(
			"P-" + str(i),
			true,
			false
		) as Panel

		if carta != null:
			cartas.append(carta)
		else:
			push_error("Carta B-" + str(i) + " não encontrada!")

		if painel != null:
			paineis.append(painel)
		else:
			push_error("Painel P-" + str(i) + " não encontrado!")

	botao_verificar = get_node_or_null(
		"Background/TextureButton"
	) as TextureButton

	if botao_verificar == null:
		push_error("TextureButton de confirmar não encontrado em Background!")

	# O contador usa _process(delta), portanto não depende de um nó Timer.
	label_tempo = get_node_or_null(
		"Background/TextureRect3/Label"
	) as Label

	if label_tempo == null:
		push_error("Label do cronômetro não encontrado!")

	# LABEL DE TENTATIVAS
	label_tentativas = get_node_or_null(
		"Background/TextureRect4/Label"
	) as Label

	if label_tentativas == null:
		push_warning(
			"Label de tentativas não encontrado em Background/TextureRect4/Label!"
		)

	# LABELS DE PONTOS E ESTRELAS (nomes em minúsculas na cena)
	label_pontos = find_child(
		"pontos",
		true,
		false
	) as Label

	if label_pontos == null:
		push_warning("Label 'pontos' não encontrado!")

	label_estrelas = find_child(
		"estrela",
		true,
		false
	) as Label

	if label_estrelas == null:
		push_warning("Label 'estrela' não encontrado!")


# ==================================================
# VALIDAR NÓS
# ==================================================

func _validar_nos() -> bool:

	if botao_verificar == null:
		return false

	if cartas.size() != TOTAL_CARTAS:
		return false

	if paineis.size() != TOTAL_CARTAS:
		return false

	if label_tempo == null:
		return false

	return true


# ==================================================
# CONECTAR BOTÃO VERIFICAR
# ==================================================

func _conectar_botao() -> void:

	if botao_verificar != null:

		if not botao_verificar.pressed.is_connected(_verificar_resposta):
			botao_verificar.pressed.connect(_verificar_resposta)


# ==================================================
# CONFIGURAR PAINEL DO PIP
# ==================================================

func _configurar_painel_pip() -> void:

	painel_pip = find_child(
		"TextureRect5",
		true,
		false
	) as Control

	if painel_pip == null:
		push_warning("Painel do Pip não encontrado!")
		return

	label_pip = painel_pip.find_child(
		"Label",
		true,
		false
	) as Label

	if label_pip == null:
		push_warning("Label do Pip não encontrado!")
		return

	label_pip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


# ==================================================
# FALA DO PIP
# ==================================================

func _fala_pip(texto: String) -> void:

	if label_pip == null:
		return

	label_pip.text = texto


# ==================================================
# GUARDAR POSIÇÕES ORIGINAIS
# ==================================================

func _guardar_posicoes_originais() -> void:

	posicoes_originais.clear()
	posicoes_slots.clear()

	for carta in cartas:
		posicoes_originais.append(carta.position)

	for painel in paineis:
		posicoes_slots.append(painel.position)


# ==================================================
# DEIXAR PAINÉIS TRANSPARENTES
# ==================================================

func _deixar_paineis_transparentes() -> void:

	for painel in paineis:

		var estilo := StyleBoxFlat.new()

		estilo.bg_color = Color(0, 0, 0, 0)
		estilo.border_width_left = 0
		estilo.border_width_right = 0
		estilo.border_width_top = 0
		estilo.border_width_bottom = 0

		painel.add_theme_stylebox_override(
			"panel",
			estilo
		)


# ==================================================
# CRONÔMETRO
# ==================================================

func _iniciar_cronometro() -> void:

	segundos_decorridos = 0
	acumulador_tempo = 0.0
	cronometro_ativo = true
	_atualizar_tempo_visual()


func _ao_passar_segundo() -> void:

	segundos_decorridos += 1
	_atualizar_tempo_visual()


func _atualizar_tempo_visual() -> void:

	if label_tempo == null:
		return

	var minutos: int = int(segundos_decorridos / 60)
	var segundos: int = segundos_decorridos % 60

	label_tempo.text = "%02d:%02d" % [
		minutos,
		segundos
	]


func _parar_cronometro() -> void:

	cronometro_ativo = false


# ==================================================
# CARREGAR DESAFIO
# ==================================================

func _carregar_desafio() -> void:

	processando = true

	carta_arrastada = -1

	carta_no_painel = [-1, -1, -1]
	painel_da_carta = [-1, -1, -1]

	ids_cartas = [1, 2, 3]

	embaralhar_cartas()

	await get_tree().process_frame

	for i in range(TOTAL_CARTAS):

		var carta := cartas[i]

		carta.z_index = 0
		carta.visible = true

		var caminho := _obter_caminho_carta(ids_cartas[i])

		if ResourceLoader.exists(caminho):

			var textura := load(caminho) as Texture2D

			if textura != null:
				carta.texture = textura
			else:
				push_error("Não foi possível carregar: " + caminho)

		else:
			push_error("Imagem não encontrada: " + caminho)

	# ANIMAÇÃO DAS CARTAS SE EMBARALHANDO.
	await _animar_embaralhar()

	processando = false

	_atualizar_pontuacao()


# ==================================================
# ANIMAÇÃO DE EMBARALHAR
# ==================================================

func _animar_embaralhar() -> void:

	var centro: Vector2 = posicoes_originais[1]

	for i in range(TOTAL_CARTAS):
		cartas[i].pivot_offset = cartas[i].size / 2.0
		cartas[i].rotation = 0.0
		cartas[i].scale = Vector2.ONE
		cartas[i].z_index = i + 1

	# 1) JUNTAR AS CARTAS NO CENTRO.
	var juntar := create_tween()
	juntar.set_parallel(true)
	juntar.set_trans(Tween.TRANS_QUAD)
	juntar.set_ease(Tween.EASE_OUT)

	for i in range(TOTAL_CARTAS):
		juntar.tween_property(
			cartas[i],
			"position",
			centro + Vector2(i * 6.0, i * -4.0),
			0.35
		)

	await juntar.finished

	# 2) EMBARALHAR: AS CARTAS TROCAM DE LUGAR VÁRIAS VEZES.
	for rodada in range(5):

		var misturar := create_tween()
		misturar.set_parallel(true)
		misturar.set_trans(Tween.TRANS_SINE)
		misturar.set_ease(Tween.EASE_IN_OUT)

		for i in range(TOTAL_CARTAS):

			var desvio := Vector2(
				randf_range(-90.0, 90.0),
				randf_range(-30.0, 30.0)
			)

			misturar.tween_property(
				cartas[i],
				"position",
				centro + desvio,
				0.16
			)

			misturar.tween_property(
				cartas[i],
				"rotation",
				randf_range(-0.30, 0.30),
				0.16
			)

		# Troca a ordem de empilhamento para parecer que se misturam.
		var ordem: Array = [1, 2, 3]
		ordem.shuffle()

		for i in range(TOTAL_CARTAS):
			cartas[i].z_index = ordem[i]

		await misturar.finished

	# 3) ESPALHAR AS CARTAS NAS POSIÇÕES FINAIS, UMA DE CADA VEZ.
	var espalhar := create_tween()
	espalhar.set_parallel(true)
	espalhar.set_trans(Tween.TRANS_BACK)
	espalhar.set_ease(Tween.EASE_OUT)

	for i in range(TOTAL_CARTAS):

		espalhar.tween_property(
			cartas[i],
			"position",
			posicoes_originais[i],
			0.45
		).set_delay(i * 0.12)

		espalhar.tween_property(
			cartas[i],
			"rotation",
			0.0,
			0.45
		).set_delay(i * 0.12)

	await espalhar.finished

	for i in range(TOTAL_CARTAS):
		cartas[i].z_index = 0
		cartas[i].position = posicoes_originais[i]
		cartas[i].rotation = 0.0


# ==================================================
# EMBARALHAR CARTAS
# ==================================================

func embaralhar_cartas() -> void:

	ids_cartas.shuffle()


# ==================================================
# CAMINHO DAS CARTAS
# ==================================================

func _obter_caminho_carta(id: int) -> String:

	return PASTA_CARTAS + "Fase-" + str(desafio_atual + 1) + "-" + str(id) + ".png"


# ==================================================
# ENTRADA DO MOUSE
# ==================================================

# A soltura do mouse é tratada aqui para que a carta
# nunca fique "grudada", mesmo que outro nó consuma o evento.
func _input(event: InputEvent) -> void:

	if event is InputEventMouseButton:

		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_finalizar_arraste()


# O clique inicial só chega aqui se nenhum botão o consumiu.
func _unhandled_input(event: InputEvent) -> void:

	if jogo_finalizado or processando:
		return

	if event is InputEventMouseButton:

		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_iniciar_arraste()


# ==================================================
# INICIAR ARRASTE
# ==================================================

func _iniciar_arraste() -> void:

	var mouse := get_global_mouse_position()

	for i in range(cartas.size()):

		var carta := cartas[i]

		if not carta.visible:
			continue

		if carta.get_global_rect().has_point(mouse):

			carta_arrastada = i

			deslocamento_mouse = carta.global_position - mouse

			carta.z_index = 10

			return


# ==================================================
# PROCESSAMENTO (CRONÔMETRO E ARRASTE)
# ==================================================

func _process(delta: float) -> void:

	# Atualiza o tempo independentemente de estar arrastando uma carta.
	if cronometro_ativo and not jogo_finalizado:
		acumulador_tempo += delta

		while acumulador_tempo >= 1.0:
			acumulador_tempo -= 1.0
			_ao_passar_segundo()

	# A parte abaixo controla somente o arraste das cartas.
	if carta_arrastada == -1:
		return

	if processando:
		return

	var carta := cartas[carta_arrastada]

	carta.global_position = get_global_mouse_position() + deslocamento_mouse


# ==================================================
# FINALIZAR ARRASTE
# ==================================================

func _finalizar_arraste() -> void:

	if carta_arrastada == -1:
		return

	var carta := cartas[carta_arrastada]

	carta.z_index = 0

	var mouse := get_global_mouse_position()

	var painel_encontrado := -1

	for i in range(paineis.size()):

		if paineis[i].get_global_rect().has_point(mouse):

			painel_encontrado = i
			break

	if painel_encontrado != -1:

		_colocar_carta_no_painel(
			carta_arrastada,
			painel_encontrado
		)

	else:

		_devolver_carta(
			carta_arrastada
		)

	carta_arrastada = -1


# ==================================================
# COLOCAR CARTA NO PAINEL
# ==================================================

func _colocar_carta_no_painel(
	indice_carta: int,
	indice_painel: int
) -> void:

	var carta := cartas[indice_carta]
	var painel := paineis[indice_painel]

	# Se a carta já estava em outro painel, libera o painel antigo.
	var painel_anterior: int = painel_da_carta[indice_carta]

	if painel_anterior != -1:
		carta_no_painel[painel_anterior] = -1

	# Se o painel de destino já tem outra carta, devolve ela.
	if carta_no_painel[indice_painel] != -1:

		var carta_antiga: int = carta_no_painel[indice_painel]

		if carta_antiga != indice_carta:
			_devolver_carta(carta_antiga)

	carta_no_painel[indice_painel] = indice_carta
	painel_da_carta[indice_carta] = indice_painel

	carta.global_position = painel.global_position + (
		painel.size - carta.size
	) / 2.0

	carta.z_index = 1


# ==================================================
# DEVOLVER CARTA
# ==================================================

func _devolver_carta(indice_carta: int) -> void:

	if indice_carta < 0 or indice_carta >= cartas.size():
		return

	var painel_atual: int = painel_da_carta[indice_carta]

	if painel_atual != -1:

		carta_no_painel[painel_atual] = -1

	painel_da_carta[indice_carta] = -1

	cartas[indice_carta].position = posicoes_originais[indice_carta]


# ==================================================
# VERIFICAR RESPOSTA
# ==================================================

func _verificar_resposta() -> void:

	if jogo_finalizado:
		return

	if processando:
		return

	if carta_no_painel.has(-1):

		_fala_pip(
			"Você precisa colocar todas as cartas nos painéis antes de verificar!"
		)

		Audio.tocar_erro()

		return

	processando = true

	# CONTAR TENTATIVA
	total_tentativas += 1
	_atualizar_tentativas()

	var resposta_correta := true

	for i in range(TOTAL_CARTAS):

		var indice_carta: int = carta_no_painel[i]

		var id_carta: int = ids_cartas[indice_carta]

		if id_carta != GABARITOS[desafio_atual][i]:

			resposta_correta = false
			break

	# O await garante que "processando" só volte a false
	# depois que as animações e esperas terminarem.
	if resposta_correta:
		await _tratar_acerto()
	else:
		await _tratar_erro()

	if not jogo_finalizado:
		processando = false


# ==================================================
# TRATAR ACERTO
# ==================================================

func _tratar_acerto() -> void:

	Audio.tocar_acerto()

	if tentativas_desafio == 0:

		acertos_primeira += 1

		pontos += PONTOS_POR_DESAFIO

		_fala_pip(
			"Excelente! Você organizou todas as cartas corretamente!"
		)

	else:

		pontos += 1

		_fala_pip(
			"Muito bem! Você conseguiu completar o desafio!"
		)

	_atualizar_pontuacao()

	# EFEITO VISUAL DE COMEMORAÇÃO.
	await _efeito_acerto()

	await _avancar_desafio()


# ==================================================
# EFEITO VISUAL DE ACERTO
# ==================================================

func _efeito_acerto() -> void:

	# 1) AS CARTAS PULAM E BRILHAM EM VERDE, EM ONDA.
	for i in range(TOTAL_CARTAS):

		var carta := cartas[i]

		carta.pivot_offset = carta.size / 2.0

		var tween := create_tween()
		tween.set_trans(Tween.TRANS_BACK)
		tween.set_ease(Tween.EASE_OUT)

		tween.tween_interval(i * 0.12)

		tween.tween_property(
			carta,
			"scale",
			Vector2(1.15, 1.15),
			0.20
		)

		tween.parallel().tween_property(
			carta,
			"modulate",
			Color("#9DFFB0"),
			0.20
		)

		tween.tween_property(
			carta,
			"scale",
			Vector2.ONE,
			0.20
		)

		_criar_brilhos(carta, i * 0.12)

	# 2) CONFETES CAINDO.
	_criar_confetes()

	# 3) MENSAGEM GRANDE NO CENTRO DA TELA.
	_mostrar_mensagem_acerto()

	await get_tree().create_timer(1.6).timeout

	# 4) VOLTAR AS CARTAS AO NORMAL.
	for carta in cartas:
		carta.modulate = Color.WHITE
		carta.scale = Vector2.ONE


# ==================================================
# BRILHOS EM VOLTA DA CARTA
# ==================================================

func _criar_brilhos(alvo: Control, atraso: float) -> void:

	var brilhos := Node2D.new()
	brilhos.z_index = 50
	brilhos.global_position = alvo.global_position + alvo.size / 2.0

	add_child(brilhos)

	for i in range(8):

		var brilho := Label.new()

		brilho.text = "✦"
		brilho.modulate = Color("#FFD45A")
		brilho.modulate.a = 0.0
		brilho.add_theme_font_size_override("font_size", 26)
		brilho.size = Vector2(40, 40)
		brilho.pivot_offset = Vector2(20, 20)
		brilho.mouse_filter = Control.MOUSE_FILTER_IGNORE

		brilhos.add_child(brilho)

		var angulo: float = TAU * float(i) / 8.0
		var distancia: float = randf_range(70.0, 130.0)

		var destino := Vector2(
			cos(angulo) * distancia,
			sin(angulo) * distancia
		) - Vector2(20, 20)

		brilho.position = Vector2(-20, -20)

		var tween := create_tween()
		tween.tween_interval(atraso)
		tween.tween_property(brilho, "modulate:a", 1.0, 0.05)
		tween.set_parallel(true)

		tween.tween_property(
			brilho,
			"position",
			destino,
			0.7
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

		tween.tween_property(
			brilho,
			"modulate:a",
			0.0,
			0.7
		).set_delay(0.25)

		tween.tween_property(
			brilho,
			"rotation",
			randf_range(-3.0, 3.0),
			0.7
		)

	await get_tree().create_timer(atraso + 1.0).timeout

	brilhos.queue_free()


# ==================================================
# CONFETES
# ==================================================

func _criar_confetes() -> void:

	var camada := Node2D.new()
	camada.z_index = 60
	add_child(camada)

	var tamanho_tela: Vector2 = get_viewport_rect().size

	var cores: Array[Color] = [
		Color("#FFD45A"),
		Color("#FF5C8A"),
		Color("#65E6A5"),
		Color("#55C7FF"),
		Color("#B58AFF"),
		Color("#FFFFFF")
	]

	for i in range(50):

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
		confete.mouse_filter = Control.MOUSE_FILTER_IGNORE

		camada.add_child(confete)

		var destino := Vector2(
			confete.position.x + randf_range(-100.0, 100.0),
			tamanho_tela.y + randf_range(40.0, 180.0)
		)

		var duracao: float = randf_range(0.9, 1.4)

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

	await get_tree().create_timer(1.6).timeout

	camada.queue_free()


# ==================================================
# MENSAGEM GRANDE DE ACERTO
# ==================================================

func _mostrar_mensagem_acerto() -> void:

	var mensagem := Label.new()

	mensagem.text = "⭐ Acertou! ⭐"
	mensagem.z_index = 70
	mensagem.add_theme_font_size_override("font_size", 72)
	mensagem.add_theme_color_override("font_color", Color("#FFD45A"))
	mensagem.add_theme_color_override("font_outline_color", Color("#7A3E00"))
	mensagem.add_theme_constant_override("outline_size", 14)
	mensagem.mouse_filter = Control.MOUSE_FILTER_IGNORE

	add_child(mensagem)

	var tamanho_tela: Vector2 = get_viewport_rect().size

	await get_tree().process_frame

	mensagem.pivot_offset = mensagem.size / 2.0
	mensagem.position = (tamanho_tela - mensagem.size) / 2.0
	mensagem.scale = Vector2.ZERO
	mensagem.modulate.a = 1.0

	var tween := create_tween()

	tween.tween_property(
		mensagem,
		"scale",
		Vector2.ONE,
		0.35
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	tween.tween_interval(0.7)

	tween.tween_property(
		mensagem,
		"modulate:a",
		0.0,
		0.35
	)

	await tween.finished

	mensagem.queue_free()


# ==================================================
# TRATAR ERRO
# ==================================================

func _tratar_erro() -> void:

	Audio.tocar_erro()

	tentativas_desafio += 1

	_fala_pip(
		"Quase lá! Observe as imagens e tente novamente."
	)

	await get_tree().create_timer(1.0).timeout

	_reiniciar_cartas()


# ==================================================
# REINICIAR CARTAS
# ==================================================

func _reiniciar_cartas() -> void:

	carta_no_painel = [-1, -1, -1]
	painel_da_carta = [-1, -1, -1]

	for i in range(TOTAL_CARTAS):

		cartas[i].position = posicoes_originais[i]
		cartas[i].z_index = 0


# ==================================================
# AVANÇAR DESAFIO
# ==================================================

func _avancar_desafio() -> void:

	desafio_atual += 1

	tentativas_desafio = 0

	if desafio_atual >= TOTAL_DESAFIOS:

		await _finalizar_jogo()

		return

	_fala_pip(
		"Novo desafio! Vou embaralhar as cartas, observe!"
	)

	await _carregar_desafio()

	_fala_pip(
		"Agora organize a sequência correta!"
	)


# ==================================================
# ESTRELAS
# ==================================================

func _calcular_estrelas() -> int:

	if pontos >= 9:
		return 3

	if pontos >= 6:
		return 2

	if pontos >= 3:
		return 1

	return 0


# ==================================================
# ATUALIZAR PONTUAÇÃO
# ==================================================

func _atualizar_pontuacao() -> void:

	if label_pontos != null:

		label_pontos.text = "           " + str(pontos) + "/9"

	if label_estrelas != null:

		label_estrelas.text = str(_calcular_estrelas()) + "/3 ⭐"


# ==================================================
# ATUALIZAR TENTATIVAS
# ==================================================

func _atualizar_tentativas() -> void:

	if label_tentativas != null:

		label_tentativas.text = str(total_tentativas)


# ==================================================
# FINALIZAR JOGO
# ==================================================

func _finalizar_jogo() -> void:

	jogo_finalizado = true

	processando = true

	# PARAR CRONÔMETRO
	_parar_cronometro()

	var estrelas_finais: int = _calcular_estrelas()

	_atualizar_pontuacao()

	_fala_pip(
		"Parabéns! Você concluiu todos os desafios e conquistou "
		+ str(estrelas_finais)
		+ " estrelas!"
	)

	# SALVAR AS ESTRELAS NO GERENCIADOR.

	var gerenciador = get_node_or_null("/root/Gerenciador")

	if gerenciador == null:
		push_error("Gerenciador não encontrado em /root/Gerenciador!")
	else:
		gerenciador.salvar_estrelas_fase_4(estrelas_finais)

		print("==============================")
		print("VERIFICAÇÃO DO SALVAMENTO")
		print("Fase 4 concluída: ", gerenciador.verificar_fase_4_concluida())
		print("Estrelas salvas: ", gerenciador.obter_estrelas_fase_4())
		print("Tentativas: ", total_tentativas)
		print("Tempo: ", segundos_decorridos, " segundos")
		print("==============================")

	# VOLTAR AUTOMATICAMENTE PARA O MODO AVENTURA.
	await get_tree().create_timer(3.0).timeout

	get_tree().change_scene_to_file(CENA_AVENTURA)


# ==================================================
# BOTÃO VOLTAR AO MODO AVENTURA
# ==================================================

func _voltar_aventura() -> void:

	# PARAR CRONÔMETRO
	_parar_cronometro()

	Audio.tocar_click()

	var erro := get_tree().change_scene_to_file(CENA_AVENTURA)

	if erro != OK:
		push_error("Não foi possível voltar ao Modo Aventura!")
