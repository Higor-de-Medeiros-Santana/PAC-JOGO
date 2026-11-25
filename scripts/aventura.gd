extends Node2D

# ==================================================
# CENAS
# ==================================================

const CENA_FASE_1 := "res://scenes/Fase-1.tscn"
const CENA_FASE_2 := "res://scenes/Fase-2.tscn"
const CENA_FASE_3 := "res://scenes/Fase-3.tscn"
const CENA_FASE_4 := "res://scenes/Fase-4.tscn"
const CENA_MENU := "res://scenes/Menu.tscn"

# Nomes dos nós das linhas (sinapses) na cena.
# Se ficar vazio, o script procura sozinho qualquer nó cujo nome
# comece com "Linha", "Line" ou "Sinapse".
# Se os seus nós tiverem outros nomes, escreva aqui, por exemplo:
# const NOMES_LINHAS: Array[String] = ["Linha-1", "Linha-2", "Linha-3"]
const NOMES_LINHAS: Array[String] = []


# ==================================================
# BOTÕES
# ==================================================

@onready var fase_1: TextureButton = $"Background/Fase-1"
@onready var fase_2: TextureButton = $"Background/Fase-2"
@onready var fase_3: TextureButton = $"Background/Fase-3"
@onready var fase_4: TextureButton = $"Background/Fase-4"

# Botão voltar
@onready var botao_voltar: TextureButton = find_child(
	"Voltar",
	true,
	false
) as TextureButton

# Cadeados
@onready var fase_3_2: TextureButton = $"Background/Fase-3/Fase-3-2"
@onready var fase_4_2: TextureButton = $"Background/Fase-4/Fase-4-2"


# ==================================================
# ESTRELAS DA FASE 1
# ==================================================

@onready var estrelas_vazias_1: TextureRect = $"Background/Fase-1/Estrelas"
@onready var estrelas_1_1: TextureRect = $"Background/Fase-1/Estrelas1"
@onready var estrelas_2_1: TextureRect = $"Background/Fase-1/Estrelas2"
@onready var estrelas_3_1: TextureRect = $"Background/Fase-1/Estrelas3"


# ==================================================
# ESTRELAS DA FASE 2
# ==================================================

@onready var estrelas_vazias_2: TextureRect = $"Background/Fase-2/Estrelas"
@onready var estrelas_1_2: TextureRect = $"Background/Fase-2/Estrelas1"
@onready var estrelas_2_2: TextureRect = $"Background/Fase-2/Estrelas2"
@onready var estrelas_3_2: TextureRect = $"Background/Fase-2/Estrelas3"


# ==================================================
# ESTRELAS DA FASE 3
# ==================================================

@onready var estrelas_vazias_3: TextureRect = $"Background/Fase-3/Estrelas"
@onready var estrelas_1_3: TextureRect = $"Background/Fase-3/Estrelas1"
@onready var estrelas_2_3: TextureRect = $"Background/Fase-3/Estrelas2"
@onready var estrelas_3_3: TextureRect = $"Background/Fase-3/Estrelas3"


# ==================================================
# ESTRELAS DA FASE 4
# ==================================================

@onready var estrelas_vazias_4: TextureRect = $"Background/Fase-4/Estrelas"
@onready var estrelas_1_4: TextureRect = $"Background/Fase-4/Estrelas1"
@onready var estrelas_2_4: TextureRect = $"Background/Fase-4/Estrelas2"
@onready var estrelas_3_4: TextureRect = $"Background/Fase-4/Estrelas3"


# ==================================================
# ANIMAÇÕES
# ==================================================

var dados_botoes: Dictionary = {}
var animando_botoes: Dictionary = {}

# SINAPSES
var linhas_sinapse: Array[CanvasItem] = []
var camada_sinapses: Node2D

# CELEBRAÇÃO FINAL
var fase_recem_concluida: bool = false
var celebrando: bool = false


# ==================================================
# INICIALIZAÇÃO
# ==================================================

func _ready() -> void:

	_configurar_botao(fase_1, CENA_FASE_1, 1)
	_configurar_botao(fase_2, CENA_FASE_2, 2)
	_configurar_botao(fase_3, CENA_FASE_3, 3)
	_configurar_botao(fase_4, CENA_FASE_4, 4)

	_atualizar_estrelas_fase_1()
	_atualizar_estrelas_fase_2()
	_atualizar_estrelas_fase_3()
	_atualizar_estrelas_fase_4()

	_atualizar_bloqueio_fase_3()
	_atualizar_bloqueio_fase_4()

	# CONECTAR BOTÃO VOLTAR
	if botao_voltar != null:

		if not botao_voltar.pressed.is_connected(_voltar_menu):
			botao_voltar.pressed.connect(_voltar_menu)

	else:
		push_error("Botão Voltar não encontrado!")

	# SINAPSES ANIMADAS O TEMPO TODO
	_localizar_linhas()
	_iniciar_sinapses()

	print("MODO AVENTURA INICIALIZADO!")

	# CELEBRAÇÃO SE O JOGADOR TERMINOU TODO O PERCURSO
	await _verificar_celebracao_final()


# ==================================================
# CONFIGURAR BOTÕES
# ==================================================

func _configurar_botao(
	botao: TextureButton,
	cena: String,
	numero_fase: int
) -> void:

	if botao == null:
		push_error("Botão da Fase " + str(numero_fase) + " não encontrado!")
		return

	botao.pivot_offset = botao.size / 2.0

	dados_botoes[botao] = {
		"escala": botao.scale,
		"cor": botao.modulate
	}

	animando_botoes[botao] = false

	botao.pressed.connect(
		_abrir_fase.bind(botao, cena)
	)

	botao.mouse_entered.connect(
		_mouse_entrou.bind(botao)
	)

	botao.mouse_exited.connect(
		_mouse_saiu.bind(botao)
	)


# ==================================================
# BLOQUEIO DA FASE 3
# ==================================================

func _atualizar_bloqueio_fase_3() -> void:

	var gerenciador = get_node_or_null("/root/Gerenciador")

	if gerenciador == null:
		push_error("Gerenciador não foi carregado!")
		return

	var concluida: bool = (
		gerenciador.verificar_fase_2_concluida()
	)

	fase_3.visible = true
	fase_3.disabled = not concluida

	fase_3_2.visible = not concluida
	fase_3_2.disabled = true

	if concluida:
		print("FASE 3 DESBLOQUEADA!")
	else:
		print("FASE 3 BLOQUEADA!")


# ==================================================
# BLOQUEIO DA FASE 4
# ==================================================

func _atualizar_bloqueio_fase_4() -> void:

	var gerenciador = get_node_or_null("/root/Gerenciador")

	if gerenciador == null:
		push_error("Gerenciador não foi carregado!")
		return

	# A Fase 4 depende da conclusão da Fase 3.
	var concluida: bool = (
		gerenciador.verificar_fase_3_concluida()
	)

	fase_4.visible = true
	fase_4.disabled = not concluida

	# Exibir ou esconder o cadeado.
	fase_4_2.visible = not concluida
	fase_4_2.disabled = true

	if concluida:
		print("FASE 4 DESBLOQUEADA!")
	else:
		print("FASE 4 BLOQUEADA!")


# ==================================================
# MOUSE ENTROU
# ==================================================

func _mouse_entrou(botao: TextureButton) -> void:

	if botao.disabled or animando_botoes[botao]:
		return

	var escala_original: Vector2 = dados_botoes[botao]["escala"]

	var tween := create_tween()

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
		Color(1.0, 0.94, 0.78),
		0.22
	)


# ==================================================
# MOUSE SAIU
# ==================================================

func _mouse_saiu(botao: TextureButton) -> void:

	if botao.disabled or animando_botoes[botao]:
		return

	var escala_original: Vector2 = dados_botoes[botao]["escala"]
	var cor_original: Color = dados_botoes[botao]["cor"]

	var tween := create_tween()

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
# ABRIR FASE
# ==================================================

func _abrir_fase(
	botao: TextureButton,
	cena: String
) -> void:

	if botao.disabled or animando_botoes[botao]:
		return

	# Som de clique ao selecionar uma fase.
	Audio.tocar_click()

	animando_botoes[botao] = true
	botao.disabled = true

	var escala_original: Vector2 = dados_botoes[botao]["escala"]
	var cor_original: Color = dados_botoes[botao]["cor"]

	var tween := create_tween()

	# Pressionar
	tween.tween_property(
		botao,
		"scale",
		escala_original * 0.90,
		0.10
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	tween.parallel().tween_property(
		botao,
		"rotation",
		deg_to_rad(-3.0),
		0.10
	)

	# Salto
	tween.tween_property(
		botao,
		"scale",
		escala_original * 1.10,
		0.22
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	tween.parallel().tween_property(
		botao,
		"rotation",
		deg_to_rad(2.0),
		0.22
	)

	tween.parallel().tween_property(
		botao,
		"modulate",
		Color(1.0, 0.88, 0.60),
		0.22
	)

	# Retorno
	tween.tween_property(
		botao,
		"scale",
		escala_original,
		0.18
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	tween.parallel().tween_property(
		botao,
		"rotation",
		0.0,
		0.18
	)

	tween.parallel().tween_property(
		botao,
		"modulate",
		cor_original,
		0.18
	)

	await tween.finished

	await get_tree().create_timer(0.12).timeout

	get_tree().change_scene_to_file(cena)


# ==================================================
# MOSTRAR ESTRELAS
# ==================================================

func _mostrar_estrelas(
	vazias: TextureRect,
	uma: TextureRect,
	duas: TextureRect,
	tres: TextureRect,
	quantidade: int,
	concluida: bool
) -> void:

	vazias.visible = not concluida

	uma.visible = concluida and quantidade == 1
	duas.visible = concluida and quantidade == 2
	tres.visible = concluida and quantidade == 3


# ==================================================
# ANIMAR ESTRELA DA FASE
# ==================================================

func _animar_estrela_da_fase(
	uma: TextureRect,
	duas: TextureRect,
	tres: TextureRect,
	quantidade: int
) -> void:

	var imagem: TextureRect = null

	match quantidade:

		1:
			imagem = uma

		2:
			imagem = duas

		3:
			imagem = tres

	if imagem != null:
		_animar_estrelas(imagem)


# ==================================================
# ANIMAÇÃO DAS ESTRELAS
# ==================================================

func _animar_estrelas(imagem: TextureRect) -> void:

	var escala_original: Vector2 = imagem.scale
	var rotacao_original: float = imagem.rotation
	var cor_original: Color = imagem.modulate

	imagem.pivot_offset = imagem.size / 2.0
	imagem.scale = escala_original * 0.2
	imagem.rotation = deg_to_rad(-12.0)
	imagem.modulate.a = 0.0

	var entrada := create_tween()

	entrada.set_parallel(true)
	entrada.set_trans(Tween.TRANS_BACK)
	entrada.set_ease(Tween.EASE_OUT)

	entrada.tween_property(
		imagem,
		"scale",
		escala_original * 1.15,
		0.55
	)

	entrada.tween_property(
		imagem,
		"rotation",
		deg_to_rad(5.0),
		0.55
	)

	entrada.tween_property(
		imagem,
		"modulate",
		cor_original,
		0.45
	)

	await entrada.finished

	var pulsacao := create_tween()

	pulsacao.tween_property(
		imagem,
		"scale",
		escala_original * 1.08,
		0.18
	)

	pulsacao.tween_property(
		imagem,
		"scale",
		escala_original,
		0.25
	)

	pulsacao.parallel().tween_property(
		imagem,
		"rotation",
		rotacao_original,
		0.35
	)


# ==================================================
# ATUALIZAR ESTRELAS DA FASE 1
# ==================================================

func _atualizar_estrelas_fase_1() -> void:

	var gerenciador = get_node_or_null("/root/Gerenciador")

	if gerenciador == null:
		push_error("Gerenciador não foi carregado!")
		return

	var quantidade: int = gerenciador.obter_estrelas_fase_1()
	var concluida: bool = gerenciador.verificar_fase_1_concluida()

	_mostrar_estrelas(
		estrelas_vazias_1,
		estrelas_1_1,
		estrelas_2_1,
		estrelas_3_1,
		quantidade,
		concluida
	)

	if gerenciador.consumir_animacao_fase_1():

		fase_recem_concluida = true

		_animar_estrela_da_fase(
			estrelas_1_1,
			estrelas_2_1,
			estrelas_3_1,
			quantidade
		)


# ==================================================
# ATUALIZAR ESTRELAS DA FASE 2
# ==================================================

func _atualizar_estrelas_fase_2() -> void:

	var gerenciador = get_node_or_null("/root/Gerenciador")

	if gerenciador == null:
		push_error("Gerenciador não foi carregado!")
		return

	var quantidade: int = gerenciador.obter_estrelas_fase_2()
	var concluida: bool = gerenciador.verificar_fase_2_concluida()

	_mostrar_estrelas(
		estrelas_vazias_2,
		estrelas_1_2,
		estrelas_2_2,
		estrelas_3_2,
		quantidade,
		concluida
	)

	if gerenciador.consumir_animacao_fase_2():

		fase_recem_concluida = true

		_animar_estrela_da_fase(
			estrelas_1_2,
			estrelas_2_2,
			estrelas_3_2,
			quantidade
		)


# ==================================================
# ATUALIZAR ESTRELAS DA FASE 3
# ==================================================

func _atualizar_estrelas_fase_3() -> void:

	var gerenciador = get_node_or_null("/root/Gerenciador")

	if gerenciador == null:
		push_error("Gerenciador não foi carregado!")
		return

	var quantidade: int = gerenciador.obter_estrelas_fase_3()
	var concluida: bool = gerenciador.verificar_fase_3_concluida()

	_mostrar_estrelas(
		estrelas_vazias_3,
		estrelas_1_3,
		estrelas_2_3,
		estrelas_3_3,
		quantidade,
		concluida
	)

	if gerenciador.consumir_animacao_fase_3():

		fase_recem_concluida = true

		_animar_estrela_da_fase(
			estrelas_1_3,
			estrelas_2_3,
			estrelas_3_3,
			quantidade
		)


# ==================================================
# ATUALIZAR ESTRELAS DA FASE 4
# ==================================================

func _atualizar_estrelas_fase_4() -> void:

	var gerenciador = get_node_or_null("/root/Gerenciador")

	if gerenciador == null:
		push_error("Gerenciador não foi carregado!")
		return

	var quantidade: int = gerenciador.obter_estrelas_fase_4()
	var concluida: bool = gerenciador.verificar_fase_4_concluida()

	_mostrar_estrelas(
		estrelas_vazias_4,
		estrelas_1_4,
		estrelas_2_4,
		estrelas_3_4,
		quantidade,
		concluida
	)

	if gerenciador.consumir_animacao_fase_4():

		fase_recem_concluida = true

		_animar_estrela_da_fase(
			estrelas_1_4,
			estrelas_2_4,
			estrelas_3_4,
			quantidade
		)


# ==================================================
# SINAPSES - LOCALIZAR LINHAS
# ==================================================

func _localizar_linhas() -> void:

	linhas_sinapse.clear()

	if NOMES_LINHAS.size() > 0:

		for nome in NOMES_LINHAS:

			var no := find_child(nome, true, false) as CanvasItem

			if no != null:
				linhas_sinapse.append(no)
			else:
				push_warning("Linha '" + nome + "' não encontrada!")

	else:

		for no in find_children("*", "CanvasItem", true, false):

			var nome_minusculo: String = String(no.name).to_lower()

			if (
				nome_minusculo.begins_with("linha")
				or nome_minusculo.begins_with("line")
				or nome_minusculo.begins_with("sinapse")
			):
				linhas_sinapse.append(no as CanvasItem)

	linhas_sinapse.sort_custom(
		func(a: CanvasItem, b: CanvasItem) -> bool:
			return String(a.name) < String(b.name)
	)

	if linhas_sinapse.is_empty():
		push_warning(
			"Nenhuma linha encontrada! Preencha NOMES_LINHAS no topo do script."
		)
	else:
		print("SINAPSES: ", linhas_sinapse.size(), " linhas encontradas.")


# ==================================================
# SINAPSES - INICIAR
# ==================================================

func _iniciar_sinapses() -> void:

	if linhas_sinapse.is_empty():
		return

	camada_sinapses = Node2D.new()
	camada_sinapses.z_index = 2
	add_child(camada_sinapses)

	# Cada linha pisca e solta faíscas de forma independente.
	for i in range(linhas_sinapse.size()):
		_tremer_linha(linhas_sinapse[i], i * 0.35)

	# Um pulso de energia viaja de uma linha para a outra, em sequência.
	_ciclo_sinapses()


# ==================================================
# SINAPSES - LINHA PISCANDO COMO CHOQUE
# ==================================================

func _tremer_linha(linha: CanvasItem, atraso: float) -> void:

	await get_tree().create_timer(atraso).timeout

	var base: Color = linha.modulate

	while is_inside_tree() and is_instance_valid(linha):

		var brilho := Color(
			base.r * randf_range(1.5, 2.0),
			base.g * randf_range(1.6, 2.1),
			base.b * 2.3,
			base.a
		)

		var apagado := Color(
			base.r * 0.7,
			base.g * 0.7,
			base.b * 0.75,
			base.a
		)

		# Pisca uma ou duas vezes, rápido, como um choquinho.
		var repeticoes: int = 2 if randf() < 0.5 else 1

		var tween := create_tween()

		for i in range(repeticoes):
			tween.tween_property(linha, "modulate", brilho, 0.05)
			tween.tween_property(linha, "modulate", apagado, 0.06)

		tween.tween_property(linha, "modulate", base, 0.12)

		_faiscas_na_linha(linha)

		await tween.finished

		if not is_inside_tree() or not is_instance_valid(linha):
			return

		await get_tree().create_timer(
			randf_range(0.25, 0.95)
		).timeout


# ==================================================
# SINAPSES - PULSO VIAJANDO PELAS LINHAS
# ==================================================

func _ciclo_sinapses() -> void:

	await get_tree().create_timer(0.5).timeout

	while is_inside_tree():

		for linha in linhas_sinapse:

			if not is_instance_valid(linha):
				return

			await _pulso_na_linha(linha)

		await get_tree().create_timer(0.8).timeout


func _pulso_na_linha(linha: CanvasItem) -> void:

	var pontos: Array = _extremidades_da_linha(linha)

	if pontos.size() < 2:
		return

	var inicio: Vector2 = pontos[0]
	var fim: Vector2 = pontos[1]

	var centro := Vector2(18, 18)

	var brilho := Label.new()

	brilho.text = "✦"
	brilho.modulate = Color("#BFF6FF")
	brilho.add_theme_font_size_override("font_size", 30)
	brilho.size = Vector2(36, 36)
	brilho.pivot_offset = centro
	brilho.mouse_filter = Control.MOUSE_FILTER_IGNORE

	camada_sinapses.add_child(brilho)

	brilho.global_position = inicio - centro

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(
		brilho,
		"global_position",
		fim - centro,
		0.9
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(
		brilho,
		"rotation",
		TAU,
		0.9
	)

	# A própria linha acende quando o pulso passa.
	var base_self: Color = linha.self_modulate

	var tween_linha := create_tween()

	tween_linha.tween_property(
		linha,
		"self_modulate",
		Color(1.8, 2.0, 2.4, base_self.a),
		0.35
	)

	tween_linha.tween_property(
		linha,
		"self_modulate",
		base_self,
		0.55
	)

	# Rastro de faíscas durante o caminho.
	for k in range(4):

		await get_tree().create_timer(0.2).timeout

		if not is_instance_valid(brilho):
			return

		_faiscas_em(brilho.global_position + centro, 4)

	await tween.finished

	if is_instance_valid(brilho):
		brilho.queue_free()


# ==================================================
# SINAPSES - PONTAS DA LINHA
# ==================================================

func _extremidades_da_linha(linha: CanvasItem) -> Array:

	if linha is Line2D:

		var line2d := linha as Line2D

		if line2d.points.size() >= 2:
			return [
				line2d.to_global(line2d.points[0]),
				line2d.to_global(line2d.points[line2d.points.size() - 1])
			]

	elif linha is Control:

		var retangulo: Rect2 = (linha as Control).get_global_rect()

		if retangulo.size.x >= retangulo.size.y:

			var y: float = retangulo.position.y + retangulo.size.y / 2.0

			return [
				Vector2(retangulo.position.x, y),
				Vector2(retangulo.end.x, y)
			]

		else:

			var x: float = retangulo.position.x + retangulo.size.x / 2.0

			return [
				Vector2(x, retangulo.position.y),
				Vector2(x, retangulo.end.y)
			]

	return []


# ==================================================
# SINAPSES - FAÍSCAS
# ==================================================

func _faiscas_na_linha(linha: CanvasItem) -> void:

	var pontos: Array = _extremidades_da_linha(linha)

	if pontos.size() < 2:
		return

	var inicio: Vector2 = pontos[0]
	var fim: Vector2 = pontos[1]

	_faiscas_em(inicio.lerp(fim, randf()), 5)


func _faiscas_em(posicao: Vector2, quantidade: int) -> void:

	if camada_sinapses == null or not is_instance_valid(camada_sinapses):
		return

	for i in range(quantidade):

		var faisca := ColorRect.new()

		faisca.size = Vector2(
			randf_range(2.0, 4.0),
			randf_range(6.0, 12.0)
		)

		faisca.color = (
			Color("#BFF6FF") if randf() < 0.6 else Color("#FFE680")
		)

		faisca.pivot_offset = faisca.size / 2.0
		faisca.mouse_filter = Control.MOUSE_FILTER_IGNORE

		camada_sinapses.add_child(faisca)

		faisca.global_position = posicao

		var angulo: float = randf() * TAU

		faisca.rotation = angulo + PI / 2.0

		var destino: Vector2 = posicao + Vector2(
			cos(angulo),
			sin(angulo)
		) * randf_range(10.0, 28.0)

		var tween := create_tween()
		tween.set_parallel(true)

		tween.tween_property(
			faisca,
			"global_position",
			destino,
			0.25
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

		tween.tween_property(
			faisca,
			"modulate:a",
			0.0,
			0.25
		)

		tween.chain().tween_callback(faisca.queue_free)


# ==================================================
# CELEBRAÇÃO FINAL - VERIFICAR
# ==================================================

func _verificar_celebracao_final() -> void:

	if not fase_recem_concluida:
		return

	var gerenciador = get_node_or_null("/root/Gerenciador")

	if gerenciador == null:
		return

	var tudo_concluido: bool = (
		gerenciador.verificar_fase_1_concluida()
		and gerenciador.verificar_fase_2_concluida()
		and gerenciador.verificar_fase_3_concluida()
		and gerenciador.verificar_fase_4_concluida()
	)

	if not tudo_concluido:
		return

	# Espera a animação das estrelas aparecer primeiro.
	await get_tree().create_timer(1.0).timeout

	await _celebrar_percurso_completo()


# ==================================================
# CELEBRAÇÃO FINAL - FOGOS, CONFETES E MENSAGEM
# ==================================================

func _celebrar_percurso_completo() -> void:

	if celebrando:
		return

	celebrando = true

	var camada := CanvasLayer.new()
	camada.layer = 100
	add_child(camada)

	var tamanho_tela: Vector2 = get_viewport_rect().size

	# ESCURECER O FUNDO SUAVEMENTE.
	var fundo := ColorRect.new()
	fundo.color = Color(0, 0, 0, 0)
	fundo.size = tamanho_tela
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	camada.add_child(fundo)

	create_tween().tween_property(fundo, "color:a", 0.55, 0.5)

	Audio.tocar_acerto()

	# MENSAGEM DE PARABÉNS.
	var titulo := Label.new()

	titulo.text = "⭐ Parabéns! ⭐\nVocê terminou todo o percurso!"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 56)
	titulo.add_theme_color_override("font_color", Color("#FFD45A"))
	titulo.add_theme_color_override("font_outline_color", Color("#7A3E00"))
	titulo.add_theme_constant_override("outline_size", 14)
	titulo.mouse_filter = Control.MOUSE_FILTER_IGNORE

	camada.add_child(titulo)

	await get_tree().process_frame

	titulo.size = titulo.get_minimum_size()
	titulo.pivot_offset = titulo.size / 2.0
	titulo.position = (tamanho_tela - titulo.size) / 2.0
	titulo.scale = Vector2.ZERO

	var entrada := create_tween()

	entrada.tween_property(
		titulo,
		"scale",
		Vector2.ONE,
		0.6
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Depois de aparecer, a mensagem pulsa suavemente.
	var pulsar := create_tween().set_loops()

	pulsar.tween_property(
		titulo,
		"scale",
		Vector2(1.05, 1.05),
		0.6
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	pulsar.tween_property(
		titulo,
		"scale",
		Vector2.ONE,
		0.6
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await entrada.finished

	# CHUVA DE CONFETES + FOGUETES.
	_chuva_de_confetes(camada, 70)

	for i in range(18):

		if not is_instance_valid(camada):
			return

		_lancar_foguete(camada, tamanho_tela)

		if i % 6 == 5:
			_chuva_de_confetes(camada, 50)

		await get_tree().create_timer(
			randf_range(0.25, 0.55)
		).timeout

	await get_tree().create_timer(2.5).timeout

	if not is_instance_valid(camada):
		return

	# DESAPARECER.
	pulsar.kill()

	var saida := create_tween()
	saida.set_parallel(true)

	saida.tween_property(fundo, "color:a", 0.0, 0.7)
	saida.tween_property(titulo, "modulate:a", 0.0, 0.7)

	await saida.finished

	camada.queue_free()

	celebrando = false


# ==================================================
# CELEBRAÇÃO - CONFETES
# ==================================================

func _chuva_de_confetes(camada: Node, quantidade: int) -> void:

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
			randf_range(-200.0, -20.0)
		)

		confete.color = cores[randi() % cores.size()]
		confete.rotation = randf_range(-0.5, 0.5)
		confete.mouse_filter = Control.MOUSE_FILTER_IGNORE

		camada.add_child(confete)

		var destino := Vector2(
			confete.position.x + randf_range(-120.0, 120.0),
			tamanho_tela.y + randf_range(40.0, 180.0)
		)

		var duracao: float = randf_range(1.4, 2.4)

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
			confete.rotation + randf_range(-6.0, 6.0),
			duracao
		)

		tween.tween_property(
			confete,
			"modulate:a",
			0.0,
			duracao
		).set_delay(duracao * 0.6)

		tween.chain().tween_callback(confete.queue_free)


# ==================================================
# CELEBRAÇÃO - FOGUETES
# ==================================================

func _lancar_foguete(camada: Node, tamanho_tela: Vector2) -> void:

	var x: float = randf_range(
		tamanho_tela.x * 0.12,
		tamanho_tela.x * 0.88
	)

	var y_alvo: float = randf_range(
		tamanho_tela.y * 0.12,
		tamanho_tela.y * 0.50
	)

	var foguete := ColorRect.new()

	foguete.size = Vector2(6, 18)
	foguete.color = Color("#FFE9A0")
	foguete.position = Vector2(x, tamanho_tela.y)
	foguete.mouse_filter = Control.MOUSE_FILTER_IGNORE

	camada.add_child(foguete)

	var subida := create_tween()

	subida.tween_property(
		foguete,
		"position",
		Vector2(x, y_alvo),
		randf_range(0.55, 0.8)
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	await subida.finished

	if not is_instance_valid(camada):
		return

	foguete.queue_free()

	_explodir_foguete(camada, Vector2(x, y_alvo))


func _explodir_foguete(camada: Node, centro: Vector2) -> void:

	var cores: Array[Color] = [
		Color("#FFD45A"),
		Color("#FF5C8A"),
		Color("#65E6A5"),
		Color("#55C7FF"),
		Color("#B58AFF"),
		Color("#FF9A3C")
	]

	var cor_a: Color = cores[randi() % cores.size()]
	var cor_b: Color = cores[randi() % cores.size()]

	var quantidade: int = 30

	# CLARÃO NO CENTRO DA EXPLOSÃO.
	var clarao := Label.new()

	clarao.text = "✦"
	clarao.modulate = Color(1, 1, 1, 1)
	clarao.add_theme_font_size_override("font_size", 60)
	clarao.size = Vector2(70, 70)
	clarao.pivot_offset = Vector2(35, 35)
	clarao.position = centro - Vector2(35, 35)
	clarao.mouse_filter = Control.MOUSE_FILTER_IGNORE

	camada.add_child(clarao)

	var tween_clarao := create_tween()
	tween_clarao.set_parallel(true)

	tween_clarao.tween_property(
		clarao,
		"scale",
		Vector2(2.2, 2.2),
		0.3
	)

	tween_clarao.tween_property(
		clarao,
		"modulate:a",
		0.0,
		0.3
	)

	tween_clarao.chain().tween_callback(clarao.queue_free)

	# PARTÍCULAS EM TODAS AS DIREÇÕES.
	for i in range(quantidade):

		var particula := ColorRect.new()

		particula.size = Vector2(6, 6)
		particula.pivot_offset = Vector2(3, 3)
		particula.color = cor_a if i % 2 == 0 else cor_b
		particula.position = centro
		particula.mouse_filter = Control.MOUSE_FILTER_IGNORE

		camada.add_child(particula)

		var angulo: float = (
			TAU * float(i) / float(quantidade)
			+ randf_range(-0.1, 0.1)
		)

		var distancia: float = randf_range(90.0, 210.0)

		var destino: Vector2 = centro + Vector2(
			cos(angulo),
			sin(angulo)
		) * distancia

		# As partículas também "caem" um pouco no final.
		destino.y += randf_range(30.0, 80.0)

		var duracao: float = randf_range(0.9, 1.4)

		var tween := create_tween()
		tween.set_parallel(true)

		tween.tween_property(
			particula,
			"position",
			destino,
			duracao
		).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

		tween.tween_property(
			particula,
			"modulate:a",
			0.0,
			duracao
		).set_delay(duracao * 0.3)

		tween.tween_property(
			particula,
			"scale",
			Vector2(0.2, 0.2),
			duracao
		)

		tween.chain().tween_callback(particula.queue_free)


# ==================================================
# BOTÃO VOLTAR AO MENU
# ==================================================

func _voltar_menu() -> void:

	Audio.tocar_click()

	var erro := get_tree().change_scene_to_file(CENA_MENU)

	if erro != OK:
		push_error("Não foi possível voltar ao menu principal!")
