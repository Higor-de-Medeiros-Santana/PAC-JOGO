extends Control
# Intro.gd
# Prólogo do Modo Aventura: apresenta a história em poucas telas, com
# efeito de "máquina de escrever". O jogador pode pular a qualquer momento.

const Historia = preload("res://scripts/Historia.gd")
const CARACTERES_POR_SEGUNDO := 45.0

@onready var _quem_label: Label = $Margem/VBox/QuemLabel
@onready var _texto_label: Label = $Margem/VBox/TextoLabel
@onready var _next_btn: Button = $Margem/VBox/Botoes/NextButton

var _pagina: int = 0
var _tween: Tween = null
var _digitando: bool = false


func _ready() -> void:
	_mostrar_pagina()


func _mostrar_pagina() -> void:
	var pagina: Dictionary = Historia.PROLOGO[_pagina]
	var quem: String = String(pagina["quem"])
	_quem_label.text = quem
	if quem == Historia.PIP:
		_quem_label.modulate = Color(1, 0.45, 0.45)
	else:
		_quem_label.modulate = Color(1, 0.9, 0.4)

	_texto_label.text = String(pagina["texto"])
	_texto_label.visible_ratio = 0.0

	if _tween:
		_tween.kill()
	var duracao: float = float(_texto_label.text.length()) / CARACTERES_POR_SEGUNDO
	_tween = create_tween()
	_tween.tween_property(_texto_label, "visible_ratio", 1.0, duracao)
	_tween.finished.connect(func(): _digitando = false)
	_digitando = true

	if _pagina < Historia.PROLOGO.size() - 1:
		_next_btn.text = "Continuar ▶"
	else:
		_next_btn.text = "Entrar no cassino 🎲"


func _on_next_button_pressed() -> void:
	if _digitando:
		# Primeiro clique: mostra o texto completo da página.
		if _tween:
			_tween.kill()
		_texto_label.visible_ratio = 1.0
		_digitando = false
		return

	_pagina += 1
	if _pagina >= Historia.PROLOGO.size():
		_ir_para_mapa()
	else:
		_mostrar_pagina()


func _on_skip_button_pressed() -> void:
	_ir_para_mapa()


func _ir_para_mapa() -> void:
	get_tree().change_scene_to_file("res://scenes/Mapa.tscn")
