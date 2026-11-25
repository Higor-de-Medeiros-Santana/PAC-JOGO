
class_name CuboFace
extends Control

signal rotacao_alterada(indice: int, rotacao: int)
signal clicado(indice: int, botao_mouse: int)

const VERMELHO: Color = Color("#EF4444")
const BRANCO: Color = Color("#FFFFFF")
const BORDA: Color = Color("#5C1423")
const VERDE: Color = Color("#75FF85")

var indice: int = 0
var face_atual: String = "B"
var rotacao: int = 0
var interativo: bool = true


# ==================================
# CONFIGURAR PEÇA
# ==================================

func configurar(p_indice: int, p_face: String, p_interativo: bool) -> void:
	indice = p_indice
	face_atual = p_face
	interativo = p_interativo
	queue_redraw()


func _ready() -> void:
	custom_minimum_size = Vector2(60, 60)
	mouse_filter = Control.MOUSE_FILTER_STOP if interativo else Control.MOUSE_FILTER_IGNORE


# ==================================
# ALTERAR FACE
# ==================================

func definir_face(nova_face: String) -> void:
	face_atual = nova_face
	queue_redraw()


# ==================================
# ALTERAR ROTAÇÃO
# ==================================

func definir_rotacao(nova_rotacao: int) -> void:
	rotacao = posmod(nova_rotacao, 360)
	queue_redraw()


func rotacionar(graus: int) -> void:
	rotacao = posmod(rotacao + graus, 360)
	queue_redraw()
	rotacao_alterada.emit(indice, rotacao)


# ==================================
# DETECTAR CLIQUES
# ==================================

func _gui_input(event: InputEvent) -> void:
	if not interativo:
		return

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
			clicado.emit(indice, event.button_index)
			accept_event()


# ==================================
# DESENHAR PEÇA
# ==================================

func _draw() -> void:
	var centro: Vector2 = size / 2.0

	draw_set_transform(
		centro,
		deg_to_rad(float(rotacao)),
		Vector2.ONE
	)

	var tamanho: float = minf(size.x, size.y) * 0.46

	var esquerda: float = -tamanho
	var direita: float = tamanho
	var topo: float = -tamanho
	var baixo: float = tamanho

	var quadrado: Rect2 = Rect2(
		Vector2(esquerda, topo),
		Vector2(tamanho * 2.0, tamanho * 2.0)
	)

	match face_atual:
		"B":
			draw_rect(quadrado, BRANCO)

		"V":
			draw_rect(quadrado, VERMELHO)

		"BV":
			draw_rect(quadrado, BRANCO)

			draw_colored_polygon(
				PackedVector2Array([
					Vector2(esquerda, topo),
					Vector2(direita, topo),
					Vector2(esquerda, baixo)
				]),
				VERMELHO
			)

	draw_rect(quadrado, BORDA, false, 1.5)

	draw_set_transform(
		Vector2.ZERO,
		0.0,
		Vector2.ONE
	)


# ==================================
# EFEITO DE FRAGMENTAÇÃO
# ==================================

func explodir() -> void:

	var pai: Node = get_parent()

	if pai == null:
		return

	# Centro da peça
	var centro: Vector2 = size / 2.0

	# Criar os quatro fragmentos triangulares
	var triangulos: Array[PackedVector2Array] = [

		PackedVector2Array([
			Vector2.ZERO,
			Vector2(size.x, 0.0),
			centro
		]),

		PackedVector2Array([
			Vector2(size.x, 0.0),
			Vector2(size.x, size.y),
			centro
		]),

		PackedVector2Array([
			Vector2(size.x, size.y),
			Vector2(0.0, size.y),
			centro
		]),

		PackedVector2Array([
			Vector2(0.0, size.y),
			Vector2.ZERO,
			centro
		])
	]

	# Direção de movimento de cada fragmento
	var direcoes: Array[Vector2] = [
		Vector2(1.0, -1.0),
		Vector2(1.0, 1.0),
		Vector2(-1.0, 1.0),
		Vector2(-1.0, -1.0)
	]

	# Posição original da peça
	var posicao_original: Vector2 = position

	# Criar e animar os fragmentos
	for i in range(4):

		var fragmento: Polygon2D = Polygon2D.new()

		fragmento.polygon = triangulos[i]
		fragmento.color = VERDE
		fragmento.position = posicao_original
		fragmento.z_index = 10

		pai.add_child(fragmento)

		# Calcular destino do fragmento
		var deslocamento: Vector2 = direcoes[i] * centro
		var destino: Vector2 = posicao_original + centro + deslocamento

		# Criar animação
		var tween: Tween = fragmento.create_tween()

		tween.set_parallel(true)
		tween.set_trans(Tween.TRANS_BACK)
		tween.set_ease(Tween.EASE_OUT)

		# Espalhar fragmento
		tween.tween_property(
			fragmento,
			"position",
			destino,
			0.65
		)

		# Girar fragmento
		var angulo: float = 45.0 if i % 2 == 0 else -45.0

		tween.tween_property(
			fragmento,
			"rotation",
			deg_to_rad(angulo),
			0.65
		)

		# Fazer desaparecer
		tween.tween_property(
			fragmento,
			"modulate:a",
			0.0,
			0.65
		)

		# Remover fragmento ao terminar
		tween.chain().tween_callback(
			Callable(fragmento, "queue_free")
		)

	# Esconder a peça original
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
