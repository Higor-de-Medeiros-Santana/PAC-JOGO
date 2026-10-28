extends Control
# FimRun.gd
# Tela de fim de run do Modo Aventura: mostra se o jogador venceu o
# chefe final ou foi derrotado, e um resumo da run.

@onready var _titulo_label: Label = $VBox/TituloLabel
@onready var _stats_label: Label = $VBox/StatsLabel


func _ready() -> void:
	var venceu: bool = RunManager.hp > 0

	if venceu:
		_titulo_label.text = "🏆 Você derrotou o Croupier Final!"
		_titulo_label.modulate = Color(1, 0.9, 0.3)
	else:
		_titulo_label.text = "💀 Sua run terminou no Andar %d" % RunManager.floor_index
		_titulo_label.modulate = Color(1, 0.4, 0.4)

	_stats_label.text = "Moedas coletadas: %d\nRelíquias obtidas: %d\nAndar alcançado: %d / %d" % [
		RunManager.coins,
		RunManager.relics.size(),
		RunManager.floor_index,
		RunManager.map.size() - 1,
	]


func _on_restart_button_pressed() -> void:
	RunManager.start_new_run()
	get_tree().change_scene_to_file("res://scenes/Mapa.tscn")


func _on_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Menu.tscn")
