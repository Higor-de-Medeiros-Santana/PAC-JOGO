extends Node

# Gerenciador.gd - Autoload (Singleton)
# Gerencia estado global: fase, pontuação, histórico


signal fase_alterada(fase: int)
signal score_changed(score: int)

var current_phase: int = 1
var score: int = 0
var total_rolls: int = 0
var acertos: int = 0

const MAX_PHASE = 2

const PHASE_CONFIG = [
	{},  # índice 0 não usado
	# Fase 1 - Número exato
	{"dice_count": 1, "sides": 6, "bet_type": "exact",
	 "rolls_needed": 5, "description": "Adivinhe o número exato!"},
	# Fase 2 - Par ou ímpar
	{"dice_count": 1, "sides": 6, "bet_type": "odd_even",
	 "rolls_needed": 8, "description": "Par ou ímpar?"},
]

var historico_rolagens: Array = []
var historico_previsoes: Array = []


func _ready() -> void:
	reset_game()


func reset_game() -> void:
	current_phase = 1
	score = 0
	total_rolls = 0
	acertos = 0
	historico_rolagens.clear()
	historico_previsoes.clear()


func get_phase_config() -> Dictionary:
	if current_phase <= MAX_PHASE:
		return PHASE_CONFIG[current_phase]
	return PHASE_CONFIG[MAX_PHASE]


func register_roll(resultado: int, previsto: int, acertou: bool) -> void:
	total_rolls += 1
	historico_rolagens.append(resultado)
	historico_previsoes.append(acertou)
	if acertou:
		acertos += 1
		var cfg_fase = get_phase_config()
		score += _calcular_pontos(cfg_fase)
		score_changed.emit(score)


func _calcular_pontos(cfg: Dictionary) -> int:
	if cfg.get("bet_type", "exact") == "exact":
		return 100
	return 150


func advance_phase() -> void:
	if current_phase < MAX_PHASE:
		current_phase += 1
		fase_alterada.emit(current_phase)


func get_accuracy() -> float:
	if total_rolls == 0:
		return 0.0
	return float(acertos) / float(total_rolls) * 100.0


func get_frequency_map() -> Dictionary:
	var frequencia: Dictionary = {}
	for r in historico_rolagens:
		frequencia[r] = frequencia.get(r, 0) + 1
	return frequencia
