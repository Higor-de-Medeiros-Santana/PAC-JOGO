extends Node2D

var perguntas: Array[Dictionary] = [
	{
		"enunciado": "Ao lançar um dado comum de 6 faces, qual é a probabilidade de sair o número 6?",
		"opcoes": ["A) 1/6", "B) 1/3", "C) 1/2", "D) 5/6"],
		"correta": 0,
		"dica": "Observe: existe apenas uma face com o número 6 entre as seis faces possíveis.",
		"acerto": "Muito bem! Uma possibilidade favorável entre seis resultados possíveis!"
	},
	{
		"enunciado": "Quantas faces possui um dado comum?",
		"opcoes": ["A) 4 faces", "B) 6 faces", "C) 8 faces", "D) 10 faces"],
		"correta": 1,
		"dica": "Pense em um dado tradicional e conte as faces numeradas de 1 a 6.",
		"acerto": "Isso mesmo! Um dado comum possui seis faces."
	},
	{
		"enunciado": "Qual é a probabilidade de sair um número par em um dado comum?",
		"opcoes": ["A) 1/6", "B) 1/3", "C) 1/2", "D) 5/6"],
		"correta": 2,
		"dica": "Os números pares são 2, 4 e 6. Quantas faces favoráveis existem entre as seis?",
		"acerto": "Excelente! Três das seis faces são pares: isso representa metade das possibilidades."
	},
	{
		"enunciado": "Qual é a probabilidade de sair um número maior que 4?",
		"opcoes": ["A) 1/6", "B) 1/3", "C) 1/2", "D) 2/3"],
		"correta": 1,
		"dica": "Quais números do dado são maiores que 4? Conte os resultados favoráveis entre as seis faces.",
		"acerto": "Perfeito! Os resultados favoráveis são 5 e 6."
	}
]

var pergunta_atual: int = 0
var resposta_selecionada: int = -1
var aguardando_proxima: bool = false
var acertos: int = 0

# Controla a pontuação da primeira tentativa.
var pergunta_ja_pontuada: bool = false

# Controla o avanço visual das quatro questões.
var questoes_concluidas: int = 0
var animacao_barra: Tween

var escalas_originais: Array[Vector2] = []
var cores_originais: Array[Color] = []

# Uma animação independente para cada alternativa.
var animacoes_botoes: Array = []

var escala_confirmar: Vector2 = Vector2.ONE
var cor_confirmar: Color
var animacao_confirmar: Tween
var confirmacao_em_andamento: bool = false

# Bloqueia cliques enquanto a nova pergunta está entrando na tela.
var animando_entrada: bool = false

# Fala do Pip (efeito máquina de escrever).
var tween_fala: Tween
var painel_pip: Control

# Animações de "pulinho" nos textos e painéis.
var tweens_pop: Dictionary = {}
var escalas_pop: Dictionary = {}
var cores_pop: Dictionary = {}


# ==================================================
# ELEMENTOS DA CENA
# ==================================================

@onready var titulo_desafio: Label = $"Background/Opcoes/t-Desafio"
@onready var texto_pergunta: Label = $"Background/Opcoes/Perguntas"

@onready var botao_voltar: TextureButton = find_child(
	"Voltar",
	true,
	false
) as TextureButton

@onready var botoes: Array[TextureButton] = [
	$"Background/Opcoes/A-1",
	$"Background/Opcoes/A-2",
	$"Background/Opcoes/A-3",
	$"Background/Opcoes/A-4"
]

@onready var botao_confirmar: TextureButton = $"Background/confirmar"
@onready var fala_pip: Label = $"Background/TextureRect5/Label"
@onready var texto_pontos: Label = $"Background/barra-estrelas/pontos"
@onready var texto_estrelas: Label = $"Background/Recompensas/estrela"
@onready var texto_diamantes: Label = $"Background/Recompensas/diamante"
@onready var texto_contagem: Label = $"Background/TextureRect7/Label"


# ==================================================
# BARRA DE PROGRESSÃO
# ==================================================

@onready var barra_fases: TextureRect = $"Background/fases-1_4"
@onready var barra_estado_1: TextureRect = $"Background/fases-1_4/1"
@onready var barra_estado_2: TextureRect = $"Background/fases-1_4/2"
@onready var barra_estado_3: TextureRect = $"Background/fases-1_4/3"


# ==================================================
# INICIALIZAÇÃO
# ==================================================

func _ready() -> void:

	texto_pergunta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fala_pip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	painel_pip = fala_pip.get_parent() as Control

	texto_pontos.text = "           0/12"
	texto_estrelas.text = "0/3 ⭐"
	texto_diamantes.text = "+50 💎"

	for i in range(botoes.size()):
		escalas_originais.append(botoes[i].scale)
		cores_originais.append(botoes[i].modulate)

		animacoes_botoes.append(null)

		# As alternativas crescem a partir do centro.
		botoes[i].pivot_offset = botoes[i].size / 2.0

		botoes[i].pressed.connect(_selecionar_resposta.bind(i))
		botoes[i].mouse_entered.connect(_ao_passar_mouse.bind(i))
		botoes[i].mouse_exited.connect(_ao_sair_mouse.bind(i))

	escala_confirmar = botao_confirmar.scale
	cor_confirmar = botao_confirmar.modulate

	botao_confirmar.pivot_offset = botao_confirmar.size / 2.0

	botao_confirmar.pressed.connect(_confirmar_resposta)
	botao_confirmar.mouse_entered.connect(_mouse_entrou_confirmar)
	botao_confirmar.mouse_exited.connect(_mouse_saiu_confirmar)

	# Conectar botão Voltar ao Modo Aventura.
	if botao_voltar != null:
		if not botao_voltar.pressed.is_connected(_voltar_aventura):
			botao_voltar.pressed.connect(_voltar_aventura)
	else:
		push_error("Botão Voltar não encontrado!")

	_atualizar_barra_progresso()
	_mostrar_pergunta()


# ==================================================
# ENCONTRAR LABEL DAS ALTERNATIVAS
# ==================================================

func _buscar_label(no: Node) -> Label:
	if no is Label:
		return no

	for filho in no.get_children():
		var resultado := _buscar_label(filho)

		if resultado != null:
			return resultado

	return null


# ==================================================
# FALA DO PIP (MÁQUINA DE ESCREVER)
# ==================================================

func _falar(texto: String) -> void:

	if tween_fala != null and tween_fala.is_running():
		tween_fala.kill()

	fala_pip.text = texto
	fala_pip.visible_ratio = 0.0

	var duracao: float = clampf(texto.length() * 0.015, 0.4, 1.4)

	tween_fala = create_tween()

	tween_fala.tween_property(
		fala_pip,
		"visible_ratio",
		1.0,
		duracao
	)

	# O painel do Pip dá um pulinho sempre que ele fala.
	if painel_pip != null:
		_pop(painel_pip, 1.03, false)


# ==================================================
# PULINHO EM TEXTOS E PAINÉIS
# ==================================================

func _pop(no: Control, fator: float = 1.2, brilho: bool = true) -> void:

	if not escalas_pop.has(no):
		escalas_pop[no] = no.scale
		cores_pop[no] = no.modulate

	var escala_base: Vector2 = escalas_pop[no]
	var cor_base: Color = cores_pop[no]

	var anterior = tweens_pop.get(no)

	if anterior != null and anterior.is_running():
		anterior.kill()

	no.pivot_offset = no.size / 2.0
	no.scale = escala_base
	no.modulate = cor_base

	var tween := create_tween()
	tweens_pop[no] = tween

	tween.tween_property(
		no,
		"scale",
		escala_base * fator,
		0.12
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	if brilho:
		tween.parallel().tween_property(
			no,
			"modulate",
			Color(1.0, 0.92, 0.45),
			0.12
		)

	tween.tween_property(
		no,
		"scale",
		escala_base,
		0.25
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	if brilho:
		tween.parallel().tween_property(
			no,
			"modulate",
			cor_base,
			0.25
		)


# ==================================================
# CONTROLAR ANIMAÇÕES INDIVIDUAIS DOS BOTÕES
# ==================================================

func _animar_botao(
	indice: int,
	nova_escala: Vector2,
	nova_cor: Color,
	duracao: float
) -> void:

	var tween_anterior = animacoes_botoes[indice]

	if tween_anterior != null and tween_anterior.is_running():
		tween_anterior.kill()

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


# ==================================================
# MOSTRAR PERGUNTA
# ==================================================

func _mostrar_pergunta() -> void:
	resposta_selecionada = -1
	aguardando_proxima = false
	confirmacao_em_andamento = false

	pergunta_ja_pontuada = false

	var dados: Dictionary = perguntas[pergunta_atual]

	titulo_desafio.text = "Desafio " + str(pergunta_atual + 1)
	texto_pergunta.text = dados["enunciado"]
	texto_contagem.text = "Pergunta " + str(pergunta_atual + 1) + " de 4"

	_falar("Vamos lá! Leia o desafio com atenção e escolha sua resposta.")

	for i in range(botoes.size()):
		var label := _buscar_label(botoes[i])

		if label == null:
			push_error("Não encontrei o Label da alternativa " + str(i + 1))
			return

		label.text = dados["opcoes"][i]

		botoes[i].disabled = false
		botoes[i].show()

	botao_confirmar.disabled = true
	botao_confirmar.show()

	# ANIMAÇÃO DE ENTRADA DA NOVA PERGUNTA.
	_animar_entrada()


# ==================================================
# ANIMAÇÃO DE ENTRADA DA PERGUNTA
# ==================================================

func _animar_entrada() -> void:

	animando_entrada = true

	# TÍTULO "DESAFIO N": cai crescendo.
	titulo_desafio.pivot_offset = titulo_desafio.size / 2.0
	titulo_desafio.scale = Vector2(1.5, 1.5)
	titulo_desafio.modulate.a = 0.0

	var tween_titulo := create_tween()
	tween_titulo.set_parallel(true)

	tween_titulo.tween_property(
		titulo_desafio,
		"scale",
		Vector2.ONE,
		0.45
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	tween_titulo.tween_property(
		titulo_desafio,
		"modulate:a",
		1.0,
		0.30
	)

	# ENUNCIADO: surge suavemente.
	texto_pergunta.pivot_offset = texto_pergunta.size / 2.0
	texto_pergunta.scale = Vector2(0.94, 0.94)
	texto_pergunta.modulate.a = 0.0

	var tween_pergunta := create_tween()
	tween_pergunta.set_parallel(true)

	tween_pergunta.tween_property(
		texto_pergunta,
		"scale",
		Vector2.ONE,
		0.45
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(0.15)

	tween_pergunta.tween_property(
		texto_pergunta,
		"modulate:a",
		1.0,
		0.40
	).set_delay(0.15)

	# ALTERNATIVAS: pulam uma de cada vez.
	for i in range(botoes.size()):

		var anterior = animacoes_botoes[i]

		if anterior != null and anterior.is_running():
			anterior.kill()

		var cor: Color = cores_originais[i]

		botoes[i].scale = Vector2.ZERO
		botoes[i].modulate = Color(cor.r, cor.g, cor.b, 0.0)

		var atraso: float = 0.30 + i * 0.10

		var tween := create_tween()
		animacoes_botoes[i] = tween

		tween.set_parallel(true)

		tween.tween_property(
			botoes[i],
			"scale",
			escalas_originais[i],
			0.35
		).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(atraso)

		tween.tween_property(
			botoes[i],
			"modulate",
			cor,
			0.25
		).set_delay(atraso)

	# BOTÃO CONFIRMAR: aparece por último.
	_parar_animacao_confirmar()

	botao_confirmar.scale = Vector2.ZERO
	botao_confirmar.modulate = Color(
		cor_confirmar.r,
		cor_confirmar.g,
		cor_confirmar.b,
		0.0
	)

	animacao_confirmar = create_tween()
	animacao_confirmar.set_parallel(true)

	animacao_confirmar.tween_property(
		botao_confirmar,
		"scale",
		escala_confirmar,
		0.35
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(0.75)

	animacao_confirmar.tween_property(
		botao_confirmar,
		"modulate",
		cor_confirmar,
		0.25
	).set_delay(0.75)

	await get_tree().create_timer(1.15).timeout

	animando_entrada = false


# ==================================================
# RESTAURAR BOTÃO
# ==================================================

func _restaurar_botao(indice: int) -> void:
	_animar_botao(
		indice,
		escalas_originais[indice],
		cores_originais[indice],
		0.12
	)


# ==================================================
# SELECIONAR RESPOSTA
# ==================================================

func _selecionar_resposta(indice: int) -> void:
	if aguardando_proxima or confirmacao_em_andamento or animando_entrada:
		return

	if resposta_selecionada == indice:
		return

	if resposta_selecionada != -1:
		_restaurar_botao(resposta_selecionada)

	resposta_selecionada = indice

	_animar_botao(
		indice,
		escalas_originais[indice] * 1.035,
		Color(1.0, 0.90, 0.76),
		0.12
	)

	botao_confirmar.disabled = false


# ==================================================
# PASSAR O MOUSE
# ==================================================

func _ao_passar_mouse(indice: int) -> void:
	if aguardando_proxima or confirmacao_em_andamento or animando_entrada:
		return

	if resposta_selecionada == indice:
		return

	_animar_botao(
		indice,
		escalas_originais[indice] * 1.02,
		cores_originais[indice],
		0.12
	)


# ==================================================
# RETIRAR O MOUSE
# ==================================================

func _ao_sair_mouse(indice: int) -> void:
	if resposta_selecionada == indice:
		return

	if aguardando_proxima or confirmacao_em_andamento or animando_entrada:
		return

	_restaurar_botao(indice)


# ==================================================
# INTERROMPER ANIMAÇÃO DO CONFIRMAR
# ==================================================

func _parar_animacao_confirmar() -> void:
	if animacao_confirmar != null and animacao_confirmar.is_running():
		animacao_confirmar.kill()


# ==================================================
# EFEITO AO PASSAR O MOUSE NO CONFIRMAR
# ==================================================

func _mouse_entrou_confirmar() -> void:
	if botao_confirmar.disabled or confirmacao_em_andamento or animando_entrada:
		return

	_parar_animacao_confirmar()

	animacao_confirmar = create_tween()
	animacao_confirmar.set_parallel(true)
	animacao_confirmar.set_trans(Tween.TRANS_SINE)
	animacao_confirmar.set_ease(Tween.EASE_OUT)

	animacao_confirmar.tween_property(
		botao_confirmar,
		"scale",
		escala_confirmar * 1.04,
		0.20
	)

	animacao_confirmar.tween_property(
		botao_confirmar,
		"modulate",
		Color(1.0, 0.92, 0.76),
		0.20
	)


# ==================================================
# EFEITO AO RETIRAR O MOUSE DO CONFIRMAR
# ==================================================

func _mouse_saiu_confirmar() -> void:
	if confirmacao_em_andamento or animando_entrada:
		return

	_parar_animacao_confirmar()

	animacao_confirmar = create_tween()
	animacao_confirmar.set_parallel(true)
	animacao_confirmar.set_trans(Tween.TRANS_SINE)
	animacao_confirmar.set_ease(Tween.EASE_OUT)

	animacao_confirmar.tween_property(
		botao_confirmar,
		"scale",
		escala_confirmar,
		0.20
	)

	animacao_confirmar.tween_property(
		botao_confirmar,
		"modulate",
		cor_confirmar,
		0.20
	)


# ==================================================
# ANIMAÇÃO AO CLICAR NO CONFIRMAR
# ==================================================

func _animar_confirmar() -> void:
	_parar_animacao_confirmar()

	animacao_confirmar = create_tween()

	animacao_confirmar.tween_property(
		botao_confirmar,
		"scale",
		escala_confirmar * 0.90,
		0.10
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	animacao_confirmar.tween_property(
		botao_confirmar,
		"scale",
		escala_confirmar * 1.08,
		0.20
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	animacao_confirmar.parallel().tween_property(
		botao_confirmar,
		"modulate",
		Color(1.0, 0.88, 0.60),
		0.20
	)

	animacao_confirmar.tween_property(
		botao_confirmar,
		"scale",
		escala_confirmar,
		0.18
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	animacao_confirmar.parallel().tween_property(
		botao_confirmar,
		"modulate",
		cor_confirmar,
		0.18
	)

	await animacao_confirmar.finished


# ==================================================
# ANIMAÇÃO DA BARRA DE QUESTÕES
# ==================================================

func _atualizar_barra_progresso() -> void:
	barra_fases.visible = true

	var estados: Array[TextureRect] = [
		barra_estado_1,
		barra_estado_2,
		barra_estado_3
	]

	# Interrompe a animação anterior.
	if animacao_barra != null and animacao_barra.is_running():
		animacao_barra.kill()

	# Esconde os três estados antes de mostrar o atual.
	for estado in estados:
		estado.visible = false
		estado.scale = Vector2.ONE
		estado.modulate = Color.WHITE

	# Nenhuma questão concluída.
	if questoes_concluidas == 0:
		return

	# A barra possui três estados visuais.
	# A quarta questão mantém o terceiro estado ativo.
	var indice: int = mini(questoes_concluidas, 3) - 1

	var estado_atual: TextureRect = estados[indice]

	estado_atual.visible = true
	estado_atual.pivot_offset = estado_atual.size / 2.0

	# Na última questão, mantém o estado final sem repetir a entrada.
	if questoes_concluidas == 4:
		return

	# Começa pequeno e transparente.
	estado_atual.scale = Vector2(0.65, 0.65)
	estado_atual.modulate.a = 0.0

	# Entrada suave com efeito de crescimento.
	animacao_barra = create_tween()
	animacao_barra.set_parallel(true)
	animacao_barra.set_trans(Tween.TRANS_BACK)
	animacao_barra.set_ease(Tween.EASE_OUT)

	animacao_barra.tween_property(
		estado_atual,
		"scale",
		Vector2.ONE,
		0.45
	)

	animacao_barra.tween_property(
		estado_atual,
		"modulate:a",
		1.0,
		0.35
	)


# ==================================================
# CONFIRMAR RESPOSTA
# ==================================================

func _confirmar_resposta() -> void:
	if resposta_selecionada == -1 or aguardando_proxima:
		return

	aguardando_proxima = true
	confirmacao_em_andamento = true
	botao_confirmar.disabled = true

	await _animar_confirmar()

	var dados: Dictionary = perguntas[pergunta_atual]
	var indice_resposta: int = resposta_selecionada
	var botao: TextureButton = botoes[indice_resposta]

	if indice_resposta == int(dados["correta"]):

		# SOM DE ACERTO
		Audio.tocar_acerto()

		# Pontuação somente na primeira tentativa.
		var ganhou_ponto: bool = not pergunta_ja_pontuada

		if ganhou_ponto:
			acertos += 1
			pergunta_ja_pontuada = true

		_falar(dados["acerto"])

		# A questão concluída avança a barra,
		# mesmo que o jogador tenha errado antes.
		questoes_concluidas += 1
		_atualizar_pontuacao()
		_atualizar_barra_progresso()

		_animar_botao(
			indice_resposta,
			escalas_originais[indice_resposta] * 1.10,
			Color(0.65, 1.0, 0.65),
			0.25
		)

		# EFEITO VISUAL DE ACERTO.
		_efeito_acerto_visual(botao, ganhou_ponto)

		for b in botoes:
			b.disabled = true

		await get_tree().create_timer(1.5).timeout

		pergunta_atual += 1

		if pergunta_atual < perguntas.size():
			_mostrar_pergunta()
		else:
			_finalizar_fase()

	else:
		# SOM DE ERRO
		Audio.tocar_erro()

		# Errou: a pergunta não poderá mais gerar pontos.
		pergunta_ja_pontuada = true

		_falar("Vamos pensar juntos! " + str(dados["dica"]))

		_animar_botao(
			indice_resposta,
			escalas_originais[indice_resposta],
			Color(1.0, 0.35, 0.30),
			0.20
		)

		# TREMOR NA ALTERNATIVA ERRADA.
		_tremer_botao(indice_resposta)

		await get_tree().create_timer(0.65).timeout

		_restaurar_botao(indice_resposta)

		resposta_selecionada = -1
		aguardando_proxima = false
		confirmacao_em_andamento = false
		botao_confirmar.disabled = true


# ==================================================
# TREMOR NA RESPOSTA ERRADA
# ==================================================

func _tremer_botao(indice: int) -> void:

	var botao := botoes[indice]
	var posicao_original: Vector2 = botao.position

	var tween := create_tween()

	for deslocamento in [-9.0, 9.0, -6.0, 6.0, -3.0, 0.0]:

		tween.tween_property(
			botao,
			"position",
			posicao_original + Vector2(deslocamento, 0.0),
			0.045
		)

	await tween.finished

	botao.position = posicao_original


# ==================================================
# EFEITO VISUAL DE ACERTO
# ==================================================

func _efeito_acerto_visual(botao: Control, ganhou_ponto: bool) -> void:

	var camada := CanvasLayer.new()
	camada.layer = 60
	add_child(camada)

	var centro: Vector2 = botao.get_global_rect().get_center()

	_criar_brilhos(camada, centro, 12)
	_criar_confetes(camada, 40)

	if ganhou_ponto:
		_texto_flutuante(camada, "+3 pontos!", centro)

	_pop(texto_pontos, 1.25)
	_pop(texto_estrelas, 1.25)

	_limpar_camada(camada, 2.2)


# ==================================================
# BRILHOS EM EXPLOSÃO
# ==================================================

func _criar_brilhos(camada: Node, centro: Vector2, quantidade: int) -> void:

	for i in range(quantidade):

		var brilho := Label.new()

		brilho.text = "✦"
		brilho.modulate = Color("#FFD45A")
		brilho.add_theme_font_size_override("font_size", 26)
		brilho.size = Vector2(40, 40)
		brilho.pivot_offset = Vector2(20, 20)
		brilho.mouse_filter = Control.MOUSE_FILTER_IGNORE
		brilho.position = centro - Vector2(20, 20)

		camada.add_child(brilho)

		var angulo: float = TAU * float(i) / float(quantidade)
		var distancia: float = randf_range(70.0, 150.0)

		var destino: Vector2 = centro - Vector2(20, 20) + Vector2(
			cos(angulo),
			sin(angulo)
		) * distancia

		var tween := create_tween()
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
		).set_delay(0.2)

		tween.tween_property(
			brilho,
			"rotation",
			randf_range(-3.0, 3.0),
			0.7
		)

		tween.chain().tween_callback(brilho.queue_free)


# ==================================================
# CONFETES CAINDO
# ==================================================

func _criar_confetes(camada: Node, quantidade: int) -> void:

	var tamanho_tela: Vector2 = get_viewport_rect().size

	var cores: Array[Color] = [
		Color("#FFD45A"),
		Color("#FF5C8A"),
		Color("#65E6A5"),
		Color("#55C7FF"),
		Color("#B58AFF"),
		Color("#FFFFFF")
	]

	for i in range(quantidade):

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

		var duracao: float = randf_range(0.9, 1.5)

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
		).set_delay(duracao * 0.5)

		tween.chain().tween_callback(confete.queue_free)


# ==================================================
# TEXTO "+3 PONTOS!" SUBINDO
# ==================================================

func _texto_flutuante(camada: Node, texto: String, centro: Vector2) -> void:

	var rotulo := Label.new()

	rotulo.text = texto
	rotulo.add_theme_font_size_override("font_size", 48)
	rotulo.add_theme_color_override("font_color", Color("#FFD45A"))
	rotulo.add_theme_color_override("font_outline_color", Color("#7A3E00"))
	rotulo.add_theme_constant_override("outline_size", 10)
	rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE

	camada.add_child(rotulo)

	rotulo.size = rotulo.get_minimum_size()
	rotulo.pivot_offset = rotulo.size / 2.0
	rotulo.position = centro - rotulo.size / 2.0
	rotulo.scale = Vector2.ZERO

	var tween := create_tween()

	tween.tween_property(
		rotulo,
		"scale",
		Vector2.ONE,
		0.30
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	tween.set_parallel(true)

	tween.tween_property(
		rotulo,
		"position:y",
		rotulo.position.y - 110.0,
		1.0
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	tween.tween_property(
		rotulo,
		"modulate:a",
		0.0,
		0.5
	).set_delay(0.7)

	tween.chain().tween_callback(rotulo.queue_free)


# ==================================================
# REMOVER CAMADA DE EFEITOS
# ==================================================

func _limpar_camada(camada: Node, atraso: float) -> void:

	await get_tree().create_timer(atraso).timeout

	if is_instance_valid(camada):
		camada.queue_free()


# ==================================================
# CALCULAR ESTRELAS
# ==================================================

func _calcular_estrelas() -> int:
	if acertos == 4:
		return 3

	if acertos >= 2:
		return 2

	if acertos == 1:
		return 1

	return 0


# ==================================================
# ATUALIZAR PONTUAÇÃO
# ==================================================

func _atualizar_pontuacao() -> void:
	texto_pontos.text = "           " + str(acertos * 3) + "/12"
	texto_estrelas.text = str(_calcular_estrelas()) + "/3 ⭐"


# ==================================================
# FINALIZAR FASE
# ==================================================

func _finalizar_fase() -> void:
	var estrelas: int = _calcular_estrelas()

	var gerenciador = get_node_or_null("/root/Gerenciador")

	if gerenciador == null:
		push_error("Gerenciador não encontrado!")
		return

	gerenciador.salvar_estrelas_fase_1(estrelas)

	titulo_desafio.text = "Fase concluída!"
	texto_pergunta.text = "Parabéns! Você restaurou ás sinapses!"

	_falar(
		"A aventura foi concluída! Você conquistou "
		+ str(estrelas)
		+ " de 3 estrelas. Vamos voltar ao mapa!"
	)

	texto_estrelas.text = str(estrelas) + "/3 ⭐"

	for botao in botoes:
		botao.hide()

	botao_confirmar.hide()

	# COMEMORAÇÃO FINAL DA FASE.
	_pop(titulo_desafio, 1.35)
	_pop(texto_pergunta, 1.10, false)
	_pop(texto_estrelas, 1.40)

	var camada := CanvasLayer.new()
	camada.layer = 60
	add_child(camada)

	var tamanho_tela: Vector2 = get_viewport_rect().size

	_criar_confetes(camada, 90)
	_criar_brilhos(camada, tamanho_tela / 2.0, 16)

	await get_tree().create_timer(2.5).timeout

	# Explosão de fumaça e volta para o mapa da aventura.
	Transicao.voltar_aventura()


# ==================================================
# BOTÃO VOLTAR AO MODO AVENTURA
# ==================================================

func _voltar_aventura() -> void:

	# Som de clique.
	Audio.tocar_click()

	# Retornar ao mapa da aventura.
	Transicao.voltar_aventura()
