extends CanvasLayer

# ==================================================
# TRANSIÇÃO COM EXPLOSÃO DE FUMAÇA
#
# Este script deve ser cadastrado como AUTOLOAD com o
# nome "Transicao". Assim ele continua existindo
# durante a troca de cena e consegue revelar a nova
# tela quando a fumaça se dissipa.
#
# Uso:  Transicao.ir_para_cena("res://scenes/Aventura.tscn")
# ==================================================

const COLUNAS := 8
const LINHAS := 6
const TAMANHO_NUVEM := Vector2(256, 256)

# Tempo para a fumaça cobrir a tela inteira.
const DURACAO_EXPLOSAO := 0.9

# Tempo para a fumaça sumir revelando a nova cena.
const DURACAO_DISSIPAR := 0.9

const COR_FUNDO := Color(0.78, 0.78, 0.82)

var ocupado: bool = false
var textura_fumaca: GradientTexture2D
var cobertura: ColorRect
var nuvens: Array[TextureRect] = []


func _ready() -> void:

	# Fica acima de qualquer outra camada do jogo.
	layer = 100

	textura_fumaca = _criar_textura_fumaca()

	# Fundo que garante que nenhum espaço fique sem cobertura.
	cobertura = ColorRect.new()
	cobertura.color = COR_FUNDO
	cobertura.set_anchors_preset(Control.PRESET_FULL_RECT)
	cobertura.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cobertura.modulate.a = 0.0

	add_child(cobertura)


# ==================================================
# FUNÇÃO PRINCIPAL
# ==================================================

# "origem" é o ponto de onde a fumaça explode.
# Se não for informado, explode do centro da tela.
func ir_para_cena(
	caminho: String,
	origem: Vector2 = Vector2(-1, -1)
) -> void:

	if ocupado:
		return

	ocupado = true

	# Bloqueia cliques enquanto a transição acontece.
	cobertura.mouse_filter = Control.MOUSE_FILTER_STOP

	var tela: Vector2 = get_viewport().get_visible_rect().size
	var centro: Vector2 = tela / 2.0

	if origem.x >= 0.0:
		centro = origem

	_explodir(tela, centro)

	await get_tree().create_timer(DURACAO_EXPLOSAO).timeout

	var erro := get_tree().change_scene_to_file(caminho)

	if erro != OK:
		push_error("Não foi possível trocar de cena: " + caminho)

	# Espera a nova cena carregar antes de revelar.
	await get_tree().process_frame
	await get_tree().process_frame

	_dissipar()


# ==================================================
# TEXTURA DA NUVEM (círculo macio gerado por código)
# ==================================================

func _criar_textura_fumaca() -> GradientTexture2D:

	var gradiente := Gradient.new()

	gradiente.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	gradiente.colors = PackedColorArray([
		Color(1, 1, 1, 1.0),
		Color(1, 1, 1, 0.6),
		Color(1, 1, 1, 0.0)
	])

	var textura := GradientTexture2D.new()

	textura.gradient = gradiente
	textura.fill = GradientTexture2D.FILL_RADIAL
	textura.fill_from = Vector2(0.5, 0.5)
	textura.fill_to = Vector2(1.0, 0.5)
	textura.width = 256
	textura.height = 256

	return textura


func _nova_nuvem() -> TextureRect:

	var nuvem := TextureRect.new()

	nuvem.texture = textura_fumaca
	nuvem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	nuvem.stretch_mode = TextureRect.STRETCH_SCALE
	nuvem.size = TAMANHO_NUVEM
	nuvem.pivot_offset = TAMANHO_NUVEM / 2.0
	nuvem.mouse_filter = Control.MOUSE_FILTER_IGNORE

	add_child(nuvem)
	nuvens.append(nuvem)

	return nuvem


# ==================================================
# EXPLOSÃO: a fumaça sai do centro e cobre a tela
# ==================================================

func _explodir(tela: Vector2, centro: Vector2) -> void:

	_limpar_nuvens()

	var proporcao: float = tela.x / 1920.0
	var distancia_maxima: float = tela.length()

	for linha in range(LINHAS):
		for coluna in range(COLUNAS):

			# Grade com variação aleatória para cobrir tudo.
			var alvo := Vector2(
				(coluna + 0.5) / float(COLUNAS) * tela.x
				+ randf_range(-0.5, 0.5) * tela.x / COLUNAS,
				(linha + 0.5) / float(LINHAS) * tela.y
				+ randf_range(-0.5, 0.5) * tela.y / LINHAS
			)

			var nuvem := _nova_nuvem()

			var tom: float = randf_range(0.55, 0.90)
			var escala_final: float = randf_range(2.2, 3.6) * proporcao

			nuvem.position = centro - TAMANHO_NUVEM / 2.0
			nuvem.scale = Vector2.ONE * 0.1
			nuvem.modulate = Color(tom, tom, tom, 0.0)

			# Quem está mais longe do centro sai um pouco depois.
			var atraso: float = centro.distance_to(alvo) / distancia_maxima * 0.3

			var tween := create_tween()
			tween.set_parallel(true)

			tween.tween_property(
				nuvem,
				"position",
				alvo - TAMANHO_NUVEM / 2.0,
				0.5
			).set_delay(atraso).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

			tween.tween_property(
				nuvem,
				"scale",
				Vector2.ONE * escala_final,
				0.5
			).set_delay(atraso).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

			tween.tween_property(
				nuvem,
				"modulate:a",
				0.95,
				0.25
			).set_delay(atraso)

			tween.tween_property(
				nuvem,
				"rotation",
				randf_range(-1.0, 1.0),
				0.8
			)

	# O fundo aparece no final para fechar qualquer brecha.
	var tween_fundo := create_tween()

	tween_fundo.tween_property(
		cobertura,
		"modulate:a",
		1.0,
		0.3
	).set_delay(0.5)


# ==================================================
# DISSIPAR: a fumaça sobe e revela a nova cena
# ==================================================

func _dissipar() -> void:

	var tween_fundo := create_tween()

	tween_fundo.tween_property(
		cobertura,
		"modulate:a",
		0.0,
		0.5
	)

	for nuvem in nuvens:

		if not is_instance_valid(nuvem):
			continue

		var atraso: float = randf_range(0.0, 0.25)

		var tween := create_tween()
		tween.set_parallel(true)

		tween.tween_property(
			nuvem,
			"scale",
			nuvem.scale * 1.5,
			DURACAO_DISSIPAR
		).set_delay(atraso).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

		tween.tween_property(
			nuvem,
			"position:y",
			nuvem.position.y - randf_range(60.0, 140.0),
			DURACAO_DISSIPAR
		).set_delay(atraso).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

		tween.tween_property(
			nuvem,
			"modulate:a",
			0.0,
			DURACAO_DISSIPAR
		).set_delay(atraso)

	await get_tree().create_timer(DURACAO_DISSIPAR + 0.4).timeout

	_limpar_nuvens()

	cobertura.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ocupado = false


func _limpar_nuvens() -> void:

	for nuvem in nuvens:

		if is_instance_valid(nuvem):
			nuvem.queue_free()

	nuvens.clear()
	# Atalho usado pelas fases para voltar ao mapa da aventura.
func voltar_aventura() -> void:
	ir_para_cena("res://scenes/Aventura.tscn")
