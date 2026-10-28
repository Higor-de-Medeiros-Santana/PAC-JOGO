extends Node
# RunManager.gd - Autoload (Singleton)
# Gerencia o estado do "Modo Aventura" (roguelike): mapa de nós gerado
# proceduralmente, vida, moedas e relíquias do jogador ao longo da run.

signal hp_changed(hp: int, max_hp: int)
signal coins_changed(coins: int)
signal relic_added(relic_id: String)
signal run_ended(vitoria: bool)

enum NodeType { INICIO, COMBATE, ELITE, EVENTO, LOJA, DESCANSO, BOSS }

# Quantidade de nós por andar. O primeiro e o último andar têm sempre 1 nó
# (início e chefe final).
const FLOOR_NODE_COUNTS := [1, 3, 4, 4, 4, 3, 1]

const RELIQUIAS := {
	"dado_sorte":   {"nome": "Dado da Sorte", "desc": "10% de chance de não sofrer dano ao errar uma aposta."},
	"dado_duplo":   {"nome": "Dado Duplo", "desc": "Aumenta um pouco o dano causado ao acertar apostas."},
	"escudo_prob":  {"nome": "Escudo de Probabilidade", "desc": "Ignora completamente o 1º erro de cada combate."},
	"visao_futuro": {"nome": "Visão de Futuro", "desc": "Reduz o dano recebido ao errar apostas."},
}

var max_hp: int = 100
var hp: int = 100
var coins: int = 0
var relics: Array = []
var floor_index: int = 0
var current_node_id: String = ""
var completed_nodes: Array = []
var map: Array = []
var run_ativa: bool = false


func start_new_run() -> void:
	max_hp = 100
	hp = 100
	coins = 0
	relics.clear()
	completed_nodes.clear()
	floor_index = 0
	run_ativa = true
	_gerar_mapa()
	var no_inicial: Dictionary = map[0][0]
	current_node_id = no_inicial["id"]
	completed_nodes.append(current_node_id)


func _gerar_mapa() -> void:
	map.clear()
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var num_andares: int = FLOOR_NODE_COUNTS.size()

	# 1) Cria os nós "vazios" de cada andar (tipo definido depois).
	for f in range(num_andares):
		var quantidade: int = FLOOR_NODE_COUNTS[f]
		var andar: Array = []
		for i in range(quantidade):
			var tipo: int = NodeType.COMBATE
			if f == 0:
				tipo = NodeType.INICIO
			elif f == num_andares - 1:
				tipo = NodeType.BOSS
			andar.append({
				"id": "f%d_n%d" % [f, i],
				"floor": f,
				"idx": i,
				"type": tipo,
				"connects_to": [],
				"x_ratio": (i + 1.0) / (quantidade + 1.0),
			})
		map.append(andar)

	# 2) Conecta cada andar ao próximo com base na proximidade horizontal
	#    dos nós (evita que várias origens caiam sempre no mesmo destino).
	for f in range(num_andares - 1):
		var andar_atual: Array = map[f]
		var proximo: Array = map[f + 1]
		var tam_atual: int = andar_atual.size()
		var tam_proximo: int = proximo.size()

		for i in range(tam_atual):
			var origem: Dictionary = andar_atual[i]
			var alvo_ideal: float = origem["x_ratio"] * tam_proximo - 0.5
			var alvo_base: int = clampi(int(round(alvo_ideal)), 0, tam_proximo - 1)

			origem["connects_to"].append(alvo_base)

			# Chance de ramificar também para um nó vizinho (esquerda/direita),
			# criando bifurcações reais no mapa.
			if tam_proximo > 1 and rng.randf() < 0.45:
				var direcao: int = 1 if rng.randf() < 0.5 else -1
				var vizinho: int = clampi(alvo_base + direcao, 0, tam_proximo - 1)
				if vizinho != alvo_base and not origem["connects_to"].has(vizinho):
					origem["connects_to"].append(vizinho)

		# Garante que todo nó do próximo andar tenha ao menos uma entrada,
		# ligando-o à origem mais próxima horizontalmente (nunca aleatória).
		for j in range(tam_proximo):
			var tem_entrada: bool = false
			for origem2 in andar_atual:
				if origem2["connects_to"].has(j):
					tem_entrada = true
					break
			if not tem_entrada:
				var melhor_i: int = 0
				var melhor_dist: float = INF
				for i in range(tam_atual):
					var dist: float = absf(andar_atual[i]["x_ratio"] - proximo[j]["x_ratio"])
					if dist < melhor_dist:
						melhor_dist = dist
						melhor_i = i
				andar_atual[melhor_i]["connects_to"].append(j)

	# 3) Sorteia os tipos dos nós intermediários (não início, não chefe).
	for f in range(1, num_andares - 1):
		for no in map[f]:
			no["type"] = _sortear_tipo(f, rng)


func _sortear_tipo(floor_i: int, rng: RandomNumberGenerator) -> int:
	var pesos: Array
	if floor_i == 1:
		pesos = [
			[NodeType.COMBATE, 70],
			[NodeType.EVENTO, 20],
			[NodeType.LOJA, 10],
		]
	else:
		pesos = [
			[NodeType.COMBATE, 45],
			[NodeType.EVENTO, 20],
			[NodeType.ELITE, 10],
			[NodeType.LOJA, 10],
			[NodeType.DESCANSO, 15],
		]
	return _sortear_por_peso(pesos, rng)


func _sortear_por_peso(pesos: Array, rng: RandomNumberGenerator) -> int:
	var total: int = 0
	for p in pesos:
		total += p[1]
	var sorteio: int = rng.randi_range(1, total)
	var acumulado: int = 0
	for p in pesos:
		acumulado += p[1]
		if sorteio <= acumulado:
			return p[0]
	return pesos[0][0]


func get_no_atual() -> Dictionary:
	return _buscar_no(current_node_id)


func _buscar_no(id: String) -> Dictionary:
	for andar in map:
		for no in andar:
			if no["id"] == id:
				return no
	return {}


func get_nos_disponiveis() -> Array:
	var no_atual: Dictionary = get_no_atual()
	if no_atual.is_empty():
		return []
	var proximo_floor: int = no_atual["floor"] + 1
	if proximo_floor >= map.size():
		return []
	var disponiveis: Array = []
	for idx in no_atual["connects_to"]:
		disponiveis.append(map[proximo_floor][idx])
	return disponiveis


func esta_disponivel(node_id: String) -> bool:
	for no in get_nos_disponiveis():
		if no["id"] == node_id:
			return true
	return false


func ir_para_no(node_id: String) -> void:
	current_node_id = node_id
	floor_index = get_no_atual()["floor"]
	if not completed_nodes.has(node_id):
		completed_nodes.append(node_id)


func adicionar_moedas(quantidade: int) -> void:
	coins += quantidade
	coins_changed.emit(coins)


func gastar_moedas(quantidade: int) -> bool:
	if coins < quantidade:
		return false
	coins -= quantidade
	coins_changed.emit(coins)
	return true


func sofrer_dano(quantidade: int) -> bool:
	var dano: int = quantidade
	if has_relic("dado_sorte") and randf() < 0.10:
		dano = 0
	if has_relic("visao_futuro"):
		dano = int(dano * 0.8)
	hp = maxi(0, hp - dano)
	hp_changed.emit(hp, max_hp)
	if hp <= 0:
		run_ativa = false
		run_ended.emit(false)
		return true
	return false


func curar(quantidade: int) -> void:
	hp = mini(max_hp, hp + quantidade)
	hp_changed.emit(hp, max_hp)


func aumentar_hp_maximo(quantidade: int) -> void:
	max_hp += quantidade
	hp += quantidade
	hp_changed.emit(hp, max_hp)


func add_relic(relic_id: String) -> void:
	if not relics.has(relic_id):
		relics.append(relic_id)
		relic_added.emit(relic_id)


func has_relic(relic_id: String) -> bool:
	return relics.has(relic_id)


func vencer_run() -> void:
	run_ativa = false
	run_ended.emit(true)


func get_config_combate(no: Dictionary) -> Dictionary:
	var f: int = no["floor"]
	var eh_boss: bool = no["type"] == NodeType.BOSS
	var eh_elite: bool = no["type"] == NodeType.ELITE

	var tipos_aposta := ["exact", "odd_even", "sum", "range"]
	var indice_tipo: int = clampi(f - 1, 0, tipos_aposta.size() - 1)
	var tipo_aposta: String = tipos_aposta[indice_tipo]

	var dados: int = 1 if f <= 2 else 2
	var lados: int = 6

	var vida_inimiga: int = 60 + f * 15
	if eh_elite:
		vida_inimiga = int(vida_inimiga * 1.6)
	if eh_boss:
		vida_inimiga = 260
		dados = 2
		lados = 6

	var dano_ao_inimigo: int = 20
	if has_relic("dado_duplo"):
		dano_ao_inimigo += 6

	var dano_ao_jogador: int = 8 + f * 2
	if eh_elite:
		dano_ao_jogador = int(dano_ao_jogador * 1.4)
	if eh_boss:
		dano_ao_jogador = 16

	var nome_inimigo: String = "Apostador Sombrio"
	if eh_elite:
		nome_inimigo = "Cassino Elite"
	if eh_boss:
		nome_inimigo = "O Croupier Final"

	var recompensa: int = 15 + f * 5
	if eh_elite:
		recompensa += 25
	if eh_boss:
		recompensa += 100

	return {
		"tipo_aposta": tipo_aposta,
		"dados": dados,
		"lados": lados,
		"vida_inimiga": vida_inimiga,
		"dano_ao_inimigo": dano_ao_inimigo,
		"dano_ao_jogador": dano_ao_jogador,
		"nome_inimigo": nome_inimigo,
		"recompensa_moedas": recompensa,
		"fases_boss": 3 if eh_boss else 1,
	}
