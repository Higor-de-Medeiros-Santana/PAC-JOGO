extends Control
# Mapa.gd
# Tela do mapa de nós do Modo Aventura (roguelike), inspirada em
# jogos como Pokelike/Slay the Spire: o jogador escolhe o caminho
# entre combates, eventos, lojas e descansos até enfrentar o chefe.

const LARGURA_MAPA := 480.0
const ESPACO_ANDAR := 150.0
const RAIO_NO := 28.0

@onready var _map_area: Control = $ScrollContainer/MapArea
@onready var _scroll: ScrollContainer = $ScrollContainer
@onready var _hp_label: Label = $HUD/HpLabel
@onready var _coins_label: Label = $HUD/CoinsLabel
@onready var _floor_label: Label = $HUD/FloorLabel
@onready var _relics_label: Label = $HUD/RelicsLabel

var _posicoes: Dictionary = {}


func _ready() -> void:
	if not RunManager.run_ativa:
		RunManager.start_new_run()
	RunManager.hp_changed.connect(func(_h, _m): _atualizar_hud())
	RunManager.coins_changed.connect(func(_c): _atualizar_hud())
	_atualizar_hud()
	_montar_mapa()


func _atualizar_hud() -> void:
	_hp_label.text = "❤ %d/%d" % [RunManager.hp, RunManager.max_hp]
	_coins_label.text = "Moedas: %d" % RunManager.coins
	_floor_label.text = "Andar %d / %d" % [RunManager.floor_index, RunManager.map.size() - 1]

	if RunManager.relics.is_empty():
		_relics_label.text = "Relíquias: nenhuma"
	else:
		var texto := "Relíquias: "
		for i in range(RunManager.relics.size()):
			var info: Dictionary = RunManager.RELIQUIAS.get(RunManager.relics[i], {})
			texto += String(info.get("nome", RunManager.relics[i]))
			if i < RunManager.relics.size() - 1:
				texto += ", "
		_relics_label.text = texto


func _montar_mapa() -> void:
	for filho in _map_area.get_children():
		filho.queue_free()
	_posicoes.clear()

	var num_andares: int = RunManager.map.size()
	_map_area.custom_minimum_size = Vector2(LARGURA_MAPA, num_andares * ESPACO_ANDAR + 100)

	for f in range(num_andares):
		var andar: Array = RunManager.map[f]
		var y: float = 60 + f * ESPACO_ANDAR
		for no in andar:
			var x: float = no["x_ratio"] * (LARGURA_MAPA - 80) + 40
			_posicoes[no["id"]] = Vector2(x, y)

	for f in range(num_andares - 1):
		for no in RunManager.map[f]:
			for idx_destino in no["connects_to"]:
				var destino: Dictionary = RunManager.map[f + 1][idx_destino]
				_desenhar_conexao(_posicoes[no["id"]], _posicoes[destino["id"]], no["id"])

	for f in range(num_andares):
		for no in RunManager.map[f]:
			_criar_botao_no(no)

	await get_tree().process_frame
	var pos_atual: Vector2 = _posicoes.get(RunManager.current_node_id, Vector2.ZERO)
	_scroll.scroll_vertical = int(maxi(0, pos_atual.y - 200))


func _desenhar_conexao(origem: Vector2, destino: Vector2, id_origem: String) -> void:
	var linha := Line2D.new()
	linha.width = 3.0
	if id_origem == RunManager.current_node_id:
		linha.default_color = Color(1, 1, 1, 0.9)
	else:
		linha.default_color = Color(1, 1, 1, 0.3)
	linha.add_point(origem)
	linha.add_point(destino)
	_map_area.add_child(linha)
	_map_area.move_child(linha, 0)


func _cor_do_tipo(tipo: int) -> Color:
	match tipo:
		RunManager.NodeType.INICIO:
			return Color(0.55, 0.55, 0.55)
		RunManager.NodeType.COMBATE:
			return Color(0.75, 0.15, 0.15)
		RunManager.NodeType.ELITE:
			return Color(0.45, 0.1, 0.5)
		RunManager.NodeType.EVENTO:
			return Color(0.85, 0.75, 0.15)
		RunManager.NodeType.LOJA:
			return Color(0.15, 0.45, 0.8)
		RunManager.NodeType.DESCANSO:
			return Color(0.2, 0.65, 0.3)
		RunManager.NodeType.BOSS:
			return Color(0.8, 0.65, 0.1)
	return Color.WHITE


func _icone_do_tipo(tipo: int) -> String:
	match tipo:
		RunManager.NodeType.INICIO:
			return ">"
		RunManager.NodeType.COMBATE:
			return "C"
		RunManager.NodeType.ELITE:
			return "E!"
		RunManager.NodeType.EVENTO:
			return "?"
		RunManager.NodeType.LOJA:
			return "$"
		RunManager.NodeType.DESCANSO:
			return "+"
		RunManager.NodeType.BOSS:
			return "B"
	return "?"


func _criar_botao_no(no: Dictionary) -> void:
	var pos: Vector2 = _posicoes[no["id"]]
	var btn := Button.new()
	btn.text = _icone_do_tipo(no["type"])
	btn.custom_minimum_size = Vector2(RAIO_NO * 2, RAIO_NO * 2)
	btn.position = pos - Vector2(RAIO_NO, RAIO_NO)
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 18)

	var cor: Color = _cor_do_tipo(no["type"])
	var disponivel: bool = RunManager.esta_disponivel(no["id"])
	var eh_atual: bool = no["id"] == RunManager.current_node_id
	var ja_completo: bool = RunManager.completed_nodes.has(no["id"]) and not eh_atual

	var estilo := StyleBoxFlat.new()
	estilo.corner_radius_top_left = 28
	estilo.corner_radius_top_right = 28
	estilo.corner_radius_bottom_left = 28
	estilo.corner_radius_bottom_right = 28

	if eh_atual:
		estilo.bg_color = cor
		estilo.border_width_left = 3
		estilo.border_width_right = 3
		estilo.border_width_top = 3
		estilo.border_width_bottom = 3
		estilo.border_color = Color.WHITE
	elif ja_completo:
		estilo.bg_color = cor.darkened(0.5)
	elif disponivel:
		estilo.bg_color = cor
	else:
		estilo.bg_color = cor.darkened(0.7)

	btn.add_theme_stylebox_override("normal", estilo)
	btn.add_theme_stylebox_override("hover", estilo)
	btn.add_theme_stylebox_override("disabled", estilo)
	btn.add_theme_color_override("font_color", Color.WHITE if (disponivel or eh_atual) else Color(1, 1, 1, 0.4))
	btn.add_theme_color_override("font_disabled_color", Color.WHITE if (disponivel or eh_atual) else Color(1, 1, 1, 0.4))

	btn.disabled = not disponivel
	btn.mouse_filter = Control.MOUSE_FILTER_STOP if disponivel else Control.MOUSE_FILTER_IGNORE

	if disponivel:
		btn.pressed.connect(func(): _selecionar_no(no))

	_map_area.add_child(btn)


func _selecionar_no(no: Dictionary) -> void:
	RunManager.ir_para_no(no["id"])
	match no["type"]:
		RunManager.NodeType.COMBATE, RunManager.NodeType.ELITE, RunManager.NodeType.BOSS:
			get_tree().change_scene_to_file("res://scenes/Combate.tscn")
		RunManager.NodeType.EVENTO:
			get_tree().change_scene_to_file("res://scenes/Evento.tscn")
		RunManager.NodeType.LOJA:
			get_tree().change_scene_to_file("res://scenes/Loja.tscn")
		RunManager.NodeType.DESCANSO:
			get_tree().change_scene_to_file("res://scenes/Descanso.tscn")


func _on_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Menu.tscn")
