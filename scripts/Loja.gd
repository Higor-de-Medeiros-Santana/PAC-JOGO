extends Control
# Loja.gd
# Nó de loja: compra de relíquias e cura usando as moedas da run.

const ITENS_A_VENDA := [
	{"id": "dado_sorte", "preco": 40},
	{"id": "dado_duplo", "preco": 55},
	{"id": "escudo_prob", "preco": 60},
	{"id": "visao_futuro", "preco": 35},
]

@onready var _coins_label: Label = $Margem/VBox/CoinsLabel
@onready var _itens_box: VBoxContainer = $Margem/VBox/Itens
@onready var _cura_btn: Button = $Margem/VBox/CuraButton
@onready var _sair_btn: Button = $Margem/VBox/SairButton


func _ready() -> void:
	_cura_btn.text = "Curar 25 HP por 20 moedas"
	_atualizar_hud()
	_montar_itens()


func _atualizar_hud() -> void:
	_coins_label.text = "Suas moedas: %d" % RunManager.coins


func _montar_itens() -> void:
	for f in _itens_box.get_children():
		f.queue_free()

	for item in ITENS_A_VENDA:
		var item_id: String = String(item["id"])
		if RunManager.has_relic(item_id):
			continue
		var preco: int = int(item["preco"])
		var info: Dictionary = RunManager.RELIQUIAS.get(item_id, {})
		var btn := Button.new()
		btn.text = "%s — %d moedas\n%s" % [info.get("nome", item_id), preco, info.get("desc", "")]
		btn.custom_minimum_size = Vector2(0, 58)
		btn.pressed.connect(func(): _comprar(item_id, preco))
		_itens_box.add_child(btn)


func _comprar(item_id: String, preco: int) -> void:
	if RunManager.gastar_moedas(preco):
		RunManager.add_relic(item_id)
		_atualizar_hud()
		_montar_itens()


func _on_cura_button_pressed() -> void:
	if RunManager.hp >= RunManager.max_hp:
		return
	if RunManager.gastar_moedas(20):
		RunManager.curar(25)
		_atualizar_hud()


func _on_sair_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Mapa.tscn")
