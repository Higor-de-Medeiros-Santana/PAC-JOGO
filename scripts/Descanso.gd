extends Control
# Descanso.gd
# Nó de descanso: o jogador escolhe entre curar HP agora ou treinar
# para aumentar o HP máximo permanentemente nesta run.

@onready var _hp_label: Label = $Margem/VBox/HpLabel
@onready var _curar_btn: Button = $Margem/VBox/CurarButton
@onready var _upgrade_btn: Button = $Margem/VBox/UpgradeButton
@onready var _resultado_label: Label = $Margem/VBox/ResultadoLabel
@onready var _continuar_btn: Button = $Margem/VBox/ContinuarButton


func _ready() -> void:
	_continuar_btn.hide()
	_atualizar_hp()
	_curar_btn.text = "🏕 Descansar (cura 35% do HP máximo)"
	_upgrade_btn.text = "💪 Treinar (HP máximo +10, cura 5)"


func _atualizar_hp() -> void:
	_hp_label.text = "❤ HP atual: %d / %d" % [RunManager.hp, RunManager.max_hp]


func _on_curar_button_pressed() -> void:
	var quantidade: int = int(RunManager.max_hp * 0.35)
	RunManager.curar(quantidade)
	_resultado_label.text = "Você descansou e recuperou %d HP." % quantidade
	_finalizar_escolha()


func _on_upgrade_button_pressed() -> void:
	RunManager.aumentar_hp_maximo(10)
	RunManager.curar(5)
	_resultado_label.text = "Seu HP máximo aumentou em 10!"
	_finalizar_escolha()


func _finalizar_escolha() -> void:
	_atualizar_hp()
	_curar_btn.disabled = true
	_upgrade_btn.disabled = true
	_continuar_btn.show()


func _on_continuar_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Mapa.tscn")
