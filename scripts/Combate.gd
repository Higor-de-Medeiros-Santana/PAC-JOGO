extends Control
# Combate.gd
# Duelo de dados do Modo Aventura: o jogador aposta em cada rolagem para
# causar dano ao inimigo; errar a aposta causa dano ao jogador.

const CENA_DADO = preload("res://scenes/Dado.tscn")
const BET_TYPES_BOSS := ["odd_even", "sum", "range"]
const TAMANHO_CELULA_DADO := 120.0

var _config: Dictionary = {}
var _dados: Array = []
var _aposta_atual = null
var _resultados_pendentes: int = 0
var _soma_rodada: int = 0
var _vida_inimiga_max: int = 100
var _vida_inimiga: int = 100
var _fase_boss_atual: int = 0
var _pode_jogar: bool = true
var _perdoou_primeiro_erro: bool = false

@onready var _dice_container: HBoxContainer = $Margem/VBox/DiceArea
@onready var _bet_options: HBoxContainer = $Margem/VBox/BetOptions
@onready var _roll_button: Button = $Margem/VBox/RollButton
@onready var _feedback_label: Label = $Margem/VBox/FeedbackLabel
@onready var _enemy_name_label: Label = $Margem/VBox/TopBar/EnemyName
@onready var _enemy_hp_bar: ProgressBar = $Margem/VBox/TopBar/EnemyHpBar
@onready var _player_hp_bar: ProgressBar = $Margem/VBox/TopBar/PlayerHpBar
@onready var _player_hp_label: Label = $Margem/VBox/TopBar/PlayerHpLabel
@onready var _coins_label: Label = $Margem/VBox/TopBar/CoinsLabel


func _ready() -> void:
	RunManager.hp_changed.connect(_on_hp_changed)
	var no: Dictionary = RunManager.get_no_atual()
	_config = RunManager.get_config_combate(no)

	_enemy_name_label.text = String(_config["nome_inimigo"])
	_vida_inimiga_max = _config["vida_inimiga"]
	_vida_inimiga = _vida_inimiga_max
	_enemy_hp_bar.max_value = _vida_inimiga_max
	_enemy_hp_bar.value = _vida_inimiga

	_atualizar_hp_jogador(RunManager.hp, RunManager.max_hp)
	_coins_label.text = "Moedas: %d" % RunManager.coins

	_montar_dados()
	_iniciar_fase_atual()


func _montar_dados() -> void:
	for filho in _dice_container.get_children():
		filho.queue_free()
	_dados.clear()
	for i in range(int(_config["dados"])):
		# O Dado é um Node2D e é desenhado centralizado na sua própria
		# origem (0,0). Um HBoxContainer só sabe posicionar nós Control,
		# então cada dado vai dentro de uma "célula" Control invisível
		# que o container consegue organizar de verdade; o dado então
		# é centralizado dentro dessa célula.
		var celula := Control.new()
		celula.custom_minimum_size = Vector2(TAMANHO_CELULA_DADO, TAMANHO_CELULA_DADO)
		celula.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_dice_container.add_child(celula)

		var d = CENA_DADO.instantiate()
		celula.add_child(d)
		d.position = Vector2(TAMANHO_CELULA_DADO / 2.0, TAMANHO_CELULA_DADO / 2.0)
		d.set_sides(int(_config["lados"]))
		d.rolado.connect(_on_dado_rolado)
		_dados.append(d)


func _bet_type_atual() -> String:
	if int(_config["fases_boss"]) > 1:
		var idx: int = clampi(_fase_boss_atual, 0, BET_TYPES_BOSS.size() - 1)
		return BET_TYPES_BOSS[idx]
	return String(_config["tipo_aposta"])


func _iniciar_fase_atual() -> void:
	_aposta_atual = null
	_roll_button.disabled = true
	_feedback_label.text = "Faça sua aposta!"
	_feedback_label.modulate = Color.WHITE
	_construir_opcoes_aposta()


func _construir_opcoes_aposta() -> void:
	for f in _bet_options.get_children():
		f.queue_free()

	var tipo: String = _bet_type_atual()
	var lados: int = int(_config["lados"])
	var qtd: int = int(_config["dados"])

	match tipo:
		"exact", "sum":
			for v in range(qtd, qtd * lados + 1):
				_add_bet_button(str(v), v)
		"odd_even":
			_add_bet_button("Par", "even")
			_add_bet_button("Ímpar", "odd")
		"range":
			var soma_max: int = qtd * lados
			var terco: int = soma_max / 3
			_add_bet_button("Baixo (≤%d)" % terco, "low")
			_add_bet_button("Médio (%d-%d)" % [terco + 1, terco * 2], "mid")
			_add_bet_button("Alto (>%d)" % (terco * 2), "high")


func _estilo_normal() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.6, 0.0, 0.0, 1.0)
	s.corner_radius_top_left = 6
	s.corner_radius_top_right = 6
	s.corner_radius_bottom_left = 6
	s.corner_radius_bottom_right = 6
	return s


func _estilo_selecionado() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
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


func _add_bet_button(rotulo: String, valor) -> void:
	var btn := Button.new()
	btn.text = rotulo
	btn.custom_minimum_size = Vector2(76, 48)
	btn.toggle_mode = true
	btn.focus_mode = Control.FOCUS_NONE

	btn.add_theme_stylebox_override("normal", _estilo_normal())
	btn.add_theme_stylebox_override("hover", _estilo_normal())
	btn.add_theme_stylebox_override("pressed", _estilo_selecionado())
	btn.add_theme_stylebox_override("hover_pressed", _estilo_selecionado())
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color.WHITE)

	btn.toggled.connect(func(ativo: bool):
		if ativo:
			for f in _bet_options.get_children():
				if f is Button and f != btn:
					f.set_pressed_no_signal(false)
			_aposta_atual = valor
			_roll_button.disabled = false
	)
	_bet_options.add_child(btn)


func _on_roll_button_pressed() -> void:
	if not _pode_jogar or _aposta_atual == null:
		return
	_pode_jogar = false
	_roll_button.disabled = true
	_resultados_pendentes = _dados.size()
	_soma_rodada = 0
	_feedback_label.text = "Rolando..."
	for d in _dados:
		d.roll()


func _on_dado_rolado(valor: int) -> void:
	_soma_rodada += valor
	_resultados_pendentes -= 1
	if _resultados_pendentes == 0:
		_resolver_rodada()


func _resolver_rodada() -> void:
	var acertou: bool = _verificar_aposta(_soma_rodada)
	if acertou:
		_causar_dano_inimigo()
	else:
		_causar_dano_jogador()

	await get_tree().create_timer(0.9).timeout

	if _vida_inimiga <= 0:
		_vencer_combate()
	elif RunManager.hp <= 0:
		pass  # RunManager já disparou o fim de run; a troca de cena ocorre em _causar_dano_jogador
	else:
		_pode_jogar = true
		_iniciar_fase_atual()


func _verificar_aposta(soma: int) -> bool:
	var tipo: String = _bet_type_atual()
	var lados: int = int(_config["lados"])
	var qtd: int = int(_config["dados"])
	var soma_max: int = qtd * lados
	var terco: int = soma_max / 3

	match tipo:
		"exact", "sum":
			return soma == _aposta_atual
		"odd_even":
			return (soma % 2 == 0) == (_aposta_atual == "even")
		"range":
			match _aposta_atual:
				"low":
					return soma <= terco
				"mid":
					return soma > terco and soma <= terco * 2
				"high":
					return soma > terco * 2
	return false


func _causar_dano_inimigo() -> void:
	var dano: int = int(_config["dano_ao_inimigo"])
	_vida_inimiga = maxi(0, _vida_inimiga - dano)
	_enemy_hp_bar.value = _vida_inimiga
	_feedback_label.text = "✅ Acertou! -%d na vida do inimigo" % dano
	_feedback_label.modulate = Color(0.2, 1, 0.4)

	if int(_config["fases_boss"]) > 1 and _vida_inimiga > 0:
		var vida_por_fase: float = _vida_inimiga_max / float(_config["fases_boss"])
		var fase_esperada: int = int((_vida_inimiga_max - _vida_inimiga) / vida_por_fase)
		if fase_esperada > _fase_boss_atual:
			_fase_boss_atual = fase_esperada
			_feedback_label.text += "\n⚠ O chefe muda de estratégia!"


func _causar_dano_jogador() -> void:
	if RunManager.has_relic("escudo_prob") and not _perdoou_primeiro_erro:
		_perdoou_primeiro_erro = true
		_feedback_label.text = "🛡 Escudo de Probabilidade absorveu o erro!"
		_feedback_label.modulate = Color(0.6, 0.8, 1)
		return

	var dano: int = int(_config["dano_ao_jogador"])
	var morreu: bool = RunManager.sofrer_dano(dano)
	_feedback_label.text = "❌ Errou! -%d HP" % dano
	_feedback_label.modulate = Color(1, 0.3, 0.3)

	if morreu:
		await get_tree().create_timer(1.0).timeout
		get_tree().change_scene_to_file("res://scenes/FimRun.tscn")


func _vencer_combate() -> void:
	var recompensa: int = int(_config["recompensa_moedas"])
	RunManager.adicionar_moedas(recompensa)
	var eh_boss: bool = RunManager.get_no_atual()["type"] == RunManager.NodeType.BOSS

	_feedback_label.text = "🏆 Vitória! +%d moedas" % recompensa
	_feedback_label.modulate = Color(1, 0.9, 0.3)

	await get_tree().create_timer(1.2).timeout

	if eh_boss:
		RunManager.vencer_run()
		get_tree().change_scene_to_file("res://scenes/FimRun.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/Mapa.tscn")


func _atualizar_hp_jogador(hp: int, max_hp: int) -> void:
	_player_hp_bar.max_value = max_hp
	_player_hp_bar.value = hp
	_player_hp_label.text = "❤ %d/%d" % [hp, max_hp]


func _on_hp_changed(hp: int, max_hp: int) -> void:
	_atualizar_hp_jogador(hp, max_hp)
	_coins_label.text = "Moedas: %d" % RunManager.coins
