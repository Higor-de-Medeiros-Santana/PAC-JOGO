extends Control
# Evento.gd
# Nó de evento: escolhas com resultado probabilístico. Reforça, na prática,
# a ideia de valor esperado (chance x recompensa/risco).

var _eventos := [
	{
		"titulo": "Baú Suspeito",
		"texto": "Você encontra um baú trancado no meio do salão. Parece arriscado abri-lo.",
		"opcoes": [
			{"rotulo": "Abrir o baú (70% moedas, 30% dano)", "acao": "bau"},
			{"rotulo": "Ignorar e seguir em frente", "acao": "ignorar"},
		],
	},
	{
		"titulo": "Vidente do Cassino",
		"texto": "Uma vidente oferece uma relíquia de probabilidade em troca de moedas.",
		"opcoes": [
			{"rotulo": "Pagar 15 moedas por uma relíquia", "acao": "vidente"},
			{"rotulo": "Recusar educadamente", "acao": "ignorar"},
		],
	},
	{
		"titulo": "Fonte da Sorte",
		"texto": "Uma fonte brilhante promete cura... ou pode ser uma armadilha.",
		"opcoes": [
			{"rotulo": "Beber da fonte (50% cura 20 HP, 50% perde 15 HP)", "acao": "fonte"},
			{"rotulo": "Não arriscar", "acao": "ignorar"},
		],
	},
]

@onready var _titulo_label: Label = $Margem/VBox/TituloLabel
@onready var _texto_label: Label = $Margem/VBox/TextoLabel
@onready var _opcoes_box: VBoxContainer = $Margem/VBox/Opcoes
@onready var _resultado_label: Label = $Margem/VBox/ResultadoLabel
@onready var _continuar_btn: Button = $Margem/VBox/ContinuarButton

var _evento_atual: Dictionary = {}


func _ready() -> void:
	_continuar_btn.hide()
	_resultado_label.text = ""
	_evento_atual = _eventos[randi() % _eventos.size()]
	_titulo_label.text = String(_evento_atual["titulo"])
	_texto_label.text = String(_evento_atual["texto"])

	for opcao in _evento_atual["opcoes"]:
		var btn := Button.new()
		btn.text = String(opcao["rotulo"])
		btn.custom_minimum_size = Vector2(0, 46)
		var acao: String = String(opcao["acao"])
		btn.pressed.connect(func(): _executar_acao(acao))
		_opcoes_box.add_child(btn)


func _executar_acao(acao: String) -> void:
	for f in _opcoes_box.get_children():
		f.queue_free()

	match acao:
		"bau":
			if randf() < 0.7:
				var moedas: int = randi_range(15, 30)
				RunManager.adicionar_moedas(moedas)
				_resultado_label.text = "✅ O baú tinha %d moedas!" % moedas
				_resultado_label.modulate = Color(1, 0.9, 0.3)
			else:
				var dano: int = randi_range(8, 15)
				RunManager.sofrer_dano(dano)
				_resultado_label.text = "💥 Era uma armadilha! -%d HP" % dano
				_resultado_label.modulate = Color(1, 0.3, 0.3)
		"vidente":
			if RunManager.gastar_moedas(15):
				var relics_disponiveis: Array = RunManager.RELIQUIAS.keys()
				var sorteada: String = String(relics_disponiveis[randi() % relics_disponiveis.size()])
				RunManager.add_relic(sorteada)
				var nome: String = String(RunManager.RELIQUIAS[sorteada].get("nome", sorteada))
				_resultado_label.text = "🔮 Você recebeu: %s!" % nome
				_resultado_label.modulate = Color(0.6, 0.8, 1)
			else:
				_resultado_label.text = "Você não tem moedas suficientes."
				_resultado_label.modulate = Color.WHITE
		"fonte":
			if randf() < 0.5:
				RunManager.curar(20)
				_resultado_label.text = "💧 A fonte curou 20 HP!"
				_resultado_label.modulate = Color(0.4, 1, 0.5)
			else:
				RunManager.sofrer_dano(15)
				_resultado_label.text = "☠ A água estava envenenada! -15 HP"
				_resultado_label.modulate = Color(1, 0.3, 0.3)
		"ignorar":
			_resultado_label.text = "Você segue seu caminho."
			_resultado_label.modulate = Color.WHITE

	_continuar_btn.show()


func _on_continuar_button_pressed() -> void:
	if RunManager.hp <= 0:
		get_tree().change_scene_to_file("res://scenes/FimRun.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/Mapa.tscn")
