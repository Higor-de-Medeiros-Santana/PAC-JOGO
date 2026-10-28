extends Node2D

enum TipoAposta { EXATO, PAR_IMPAR, SOMA, INTERVALO }
enum EstadoJogo { APOSTANDO, ROLANDO, RESULTADO, FASE_COMPLETA }

const CENA_DADO = preload("res://scenes/Dado.tscn")

var _estado: EstadoJogo = EstadoJogo.APOSTANDO
var _aposta_atual = null
var _dados: Array = []
var _rodadas_na_fase: int = 0
var _cfg_fase: Dictionary = {}
var _resultados_pendentes: int = 0
var _soma_rodada: int = 0

@onready var _container_dados: HBoxContainer = $UI/DiceArea/DiceContainer
@onready var _painel_aposta: PanelContainer    = $UI/BetPanel
@onready var _btn_rolar: Button             = $UI/BottomBar/RollButton
@onready var _label_fase: Label           = $UI/TopBar/PhaseLabel
@onready var _label_pontos: Label           = $UI/TopBar/ScoreLabel
@onready var _label_desc: Label            = $UI/BetPanel/VBox/DescLabel
@onready var _opcoes_aposta: HBoxContainer   = $UI/BetPanel/VBox/BetOptions
@onready var _label_feedback: Label        = $UI/FeedbackLabel
@onready var _barra_progresso: ProgressBar    = $UI/TopBar/PhaseProgress
@onready var _no_grafico: Node2D           = $UI/ChartArea/Chart
@onready var _label_precisao: Label        = $UI/TopBar/AccuracyLabel
@onready var _btn_proxima_fase: Button       = $UI/NextPhaseButton
@onready var _som_click: AudioStreamPlayer = $Click


func _ready() -> void:
	Gerenciador.score_changed.connect(_on_pontos_alterados)
	_btn_proxima_fase.hide()
	_setup_fase()


func _tocar_click() -> void:
	if _som_click and _som_click.stream:
		_som_click.pitch_scale = randf_range(0.95, 1.05)
		_som_click.play()


func _setup_fase() -> void:
	_painel_aposta.show()
	_btn_rolar.show()
	_cfg_fase = Gerenciador.get_phase_config()
	_rodadas_na_fase = 0
	_estado = EstadoJogo.APOSTANDO

	_label_fase.text = "Fase %d / %d" % [Gerenciador.current_phase, Gerenciador.MAX_PHASE]
	_label_pontos.text = "Pontos: %d" % Gerenciador.score
	_label_desc.text = _cfg_fase.get("description", "")
	_label_desc.add_theme_color_override("font_color", Color(0.0, 0.0, 0.0, 1.0))
	_barra_progresso.max_value = _cfg_fase.get("rolls_needed", 5)
	_barra_progresso.value = 0
	_label_feedback.text = ""

	for d in _dados:
		d.queue_free()
	_dados.clear()

	var quantidade = _cfg_fase.get("dice_count", 1)
	var lados = _cfg_fase.get("sides", 6)
	for i in range(quantidade):
		var d = CENA_DADO.instantiate()
		_container_dados.add_child(d)
		d.set_sides(lados)
		d.rolado.connect(_on_dado_rolado)
		_dados.append(d)

	_construir_opcoes_aposta()
	_btn_rolar.disabled = true


func _construir_opcoes_aposta() -> void:
	for filho in _opcoes_aposta.get_children():
		filho.queue_free()
	_aposta_atual = null

	var tipo_aposta = _cfg_fase.get("bet_type", "exact")
	var lados = _cfg_fase.get("sides", 6)
	var quantidade = _cfg_fase.get("dice_count", 1)

	match tipo_aposta:
		"exact":
			for v in range(1, lados + 1):
				_adicionar_botao_aposta(str(v), v)
		"odd_even":
			_adicionar_botao_aposta("Par", "even")
			_adicionar_botao_aposta("Ímpar", "odd")
		"sum":
			var soma_min = quantidade
			var soma_max = quantidade * lados
			for v in range(soma_min, soma_max + 1):
				_adicionar_botao_aposta(str(v), v)
		"range":
			var soma_max = quantidade * lados
			var terco = soma_max / 3
			_adicionar_botao_aposta("Baixo (≤%d)" % terco, "low")
			_adicionar_botao_aposta("Médio (%d-%d)" % [terco + 1, terco * 2], "mid")
			_adicionar_botao_aposta("Alto (>%d)" % (terco * 2), "high")


func _estilo_normal() -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.6, 0.0, 0.0, 1.0)
	s.corner_radius_top_left = 6
	s.corner_radius_top_right = 6
	s.corner_radius_bottom_left = 6
	s.corner_radius_bottom_right = 6
	return s


func _estilo_selecionado() -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = Color(1.0, 0.2, 0.2, 1.0)
	s.border_width_left = 2
	s.border_width_right = 2
	s.border_width_top = 2
	s.border_width_bottom = 2
	s.border_color = Color.WHITE
	s.corner_radius_top_left = 6
	s.corner_radius_top_right = 6
	s.corner_radius_bottom_left = 6
	s.corner_radius_bottom_right = 6
	return s


func _adicionar_botao_aposta(rotulo: String, valor) -> void:
	var btn = Button.new()
	btn.text = rotulo
	btn.custom_minimum_size = Vector2(80, 50)
	btn.toggle_mode = true
	btn.focus_mode = Control.FOCUS_NONE  # evita foco visual indesejado

	btn.add_theme_stylebox_override("normal", _estilo_normal())
	btn.add_theme_stylebox_override("hover", _estilo_normal())
	btn.add_theme_stylebox_override("pressed", _estilo_selecionado())
	btn.add_theme_stylebox_override("hover_pressed", _estilo_selecionado())
	btn.add_theme_stylebox_override("focus", _estilo_normal())

	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color.WHITE)
	btn.add_theme_color_override("font_focus_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_pressed_color", Color.WHITE)

	btn.toggled.connect(func(ativo: bool): 
		if ativo:
			_tocar_click()
			_selecionar_aposta(valor, btn)
	)
	_opcoes_aposta.add_child(btn)


func _selecionar_aposta(valor, btn_pressionado: Button) -> void:
	for filho in _opcoes_aposta.get_children():
		if filho is Button and filho != btn_pressionado:
			filho.set_pressed_no_signal(false)

	_aposta_atual = valor
	_btn_rolar.disabled = false


func _on_roll_button_pressed() -> void:
	if _estado != EstadoJogo.APOSTANDO or _aposta_atual == null:
		return
	_estado = EstadoJogo.ROLANDO
	_btn_rolar.disabled = true
	_resultados_pendentes = _dados.size()
	_soma_rodada = 0
	_label_feedback.text = "Rolando..."
	for d in _dados:
		d.roll()


func _on_dado_rolado(valor: int) -> void:
	_soma_rodada += valor
	_resultados_pendentes -= 1
	if _resultados_pendentes == 0:
		_avaliar_resultado()


func _avaliar_resultado() -> void:
	_estado = EstadoJogo.RESULTADO
	var acertou = _verificar_aposta(_soma_rodada)

	Gerenciador.register_roll(_soma_rodada, _aposta_atual if _aposta_atual is int else 0, acertou)

	if acertou:
		_label_feedback.text = "✅ Correto! +" + str(_calcular_pontos())
		_label_feedback.modulate = Color(0.2, 1, 0.4)
	else:
		var tipo_aposta = _cfg_fase.get("bet_type", "exact")
		if tipo_aposta == "odd_even":
			var paridade = "Par" if _soma_rodada % 2 == 0 else "Ímpar"
			_label_feedback.text = "❌ Errou! Era %s (%d)" % [paridade, _soma_rodada]
		else:
			_label_feedback.text = "❌ Errou! Era %d" % _soma_rodada
		_label_feedback.modulate = Color(1, 0.3, 0.3)

	_rodadas_na_fase += 1
	_barra_progresso.value = _rodadas_na_fase
	_label_precisao.text = "Precisão: %.1f%%" % Gerenciador.get_accuracy()

	if _no_grafico and _no_grafico.has_method("update_chart"):
		_no_grafico.update_chart(Gerenciador.get_frequency_map(),
			_cfg_fase.get("dice_count", 1) * _cfg_fase.get("sides", 6))

	var necessarias = _cfg_fase.get("rolls_needed", 5)
	if _rodadas_na_fase >= necessarias:
		_estado = EstadoJogo.FASE_COMPLETA
		_mostrar_fase_completa()
	else:
		await get_tree().create_timer(0.8).timeout
		_resetar_para_proxima_rodada()


func _verificar_aposta(soma: int) -> bool:
	var tipo_aposta = _cfg_fase.get("bet_type", "exact")
	var lados = _cfg_fase.get("sides", 6)
	var quantidade = _cfg_fase.get("dice_count", 1)
	var soma_max = quantidade * lados
	var terco = soma_max / 3

	match tipo_aposta:
		"exact":
			return soma == _aposta_atual
		"odd_even":
			if _aposta_atual == "even":
				return soma % 2 == 0
			else:
				return soma % 2 != 0
		"sum":
			return soma == _aposta_atual
		"range":
			match _aposta_atual:
				"low":  return soma <= terco
				"mid":  return soma > terco and soma <= terco * 2
				"high": return soma > terco * 2
	return false


func _calcular_pontos() -> int:
	return 100 + (Gerenciador.current_phase - 1) * 50


func _resetar_para_proxima_rodada() -> void:
	_estado = EstadoJogo.APOSTANDO
	_aposta_atual = null
	for filho in _opcoes_aposta.get_children():
		if filho is Button:
			filho.set_pressed_no_signal(false)
	_btn_rolar.disabled = true
	_label_feedback.text = "Faça sua aposta!"
	_label_feedback.modulate = Color.WHITE


func _mostrar_fase_completa() -> void:
	_painel_aposta.hide()
	_btn_rolar.hide()
	var precisao = Gerenciador.get_accuracy()
	_label_feedback.text = "🎉 Fase %d concluída! Precisão: %.1f%%" % \
		[Gerenciador.current_phase, precisao]
	_label_feedback.modulate = Color(0.874, 0.881, 1.0, 1.0)

	if Gerenciador.current_phase < Gerenciador.MAX_PHASE:
		_btn_proxima_fase.text = "Próxima Fase →"
		_btn_proxima_fase.show()
	else:
		_btn_proxima_fase.text = "🏆 Ver Resultado Final"
		_btn_proxima_fase.show()


func _on_next_phase_button_pressed() -> void:
	_tocar_click()
	_btn_proxima_fase.hide()
	if Gerenciador.current_phase < Gerenciador.MAX_PHASE:
		Gerenciador.advance_phase()
		_setup_fase()
	else:
		get_tree().change_scene_to_file("res://scenes/FimJogo.tscn")


func _on_pontos_alterados(novos_pontos: int) -> void:
	_label_pontos.text = "Pontos: %d" % novos_pontos


var _pause_menu: CanvasLayer = null

func _input(evento: InputEvent) -> void:
	if evento.is_action_pressed("roll"):
		_on_roll_button_pressed()
	elif evento.is_action_pressed("ui_cancel"):
		_toggle_pause()

func _toggle_pause() -> void:
	if _pause_menu == null:
		_pause_menu = CanvasLayer.new()
		_pause_menu.layer = 10
		add_child(_pause_menu)

		var panel = ColorRect.new()
		panel.color = Color(0, 0, 0, 0.6)
		panel.set_anchors_preset(Control.PRESET_FULL_RECT)
		_pause_menu.add_child(panel)

		var vbox = VBoxContainer.new()
		vbox.set_anchors_preset(Control.PRESET_CENTER)
		vbox.custom_minimum_size = Vector2(200, 120)
		vbox.position = Vector2(-100, -60)
		_pause_menu.add_child(vbox)

		var btn_continuar = Button.new()
		btn_continuar.text = "▶ Continuar"
		btn_continuar.pressed.connect(func():
			_tocar_click()
			_toggle_pause()
		)
		vbox.add_child(btn_continuar)

		var btn_menu = Button.new()
		btn_menu.text = "🏠 Voltar ao Menu"
		btn_menu.pressed.connect(func():
			_tocar_click()
			get_tree().paused = false
			get_tree().change_scene_to_file("res://scenes/Menu.tscn")
		)
		vbox.add_child(btn_menu)

		get_tree().paused = true
		_pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	else:
		get_tree().paused = false
		_pause_menu.queue_free()
		_pause_menu = null
