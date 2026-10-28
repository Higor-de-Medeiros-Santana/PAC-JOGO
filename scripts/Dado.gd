extends Node2D
class_name Dado
signal rolado(valor: int)

@export var lados: int = 6
@export var duracao_rolagem: float = 0.8

var _valor_atual: int = 1
var _esta_rolando: bool = false
var _timer_rolagem: float = 0.0
var _intervalo_flash: float = 0.07

@onready var _face: Node2D = $DiceFace
@onready var _anim: AnimationPlayer = $AnimationPlayer
@onready var _som_rolagem: AudioStreamPlayer2D = $SomRolagem
@onready var _som_parada: AudioStreamPlayer2D = $SomParada

# Posições dos pontos para cada face (coordenadas em grade 3x3, 0..1)
const POSICOES_PONTOS = {
	1: [[0.5, 0.5]],
	2: [[0.25, 0.25], [0.75, 0.75]],
	3: [[0.25, 0.25], [0.5, 0.5], [0.75, 0.75]],
	4: [[0.25, 0.25], [0.75, 0.25], [0.25, 0.75], [0.75, 0.75]],
	5: [[0.25, 0.25], [0.75, 0.25], [0.5, 0.5], [0.25, 0.75], [0.75, 0.75]],
	6: [[0.25, 0.25], [0.75, 0.25], [0.25, 0.5], [0.75, 0.5], [0.25, 0.75], [0.75, 0.75]],
}

func _ready() -> void:
	_setup_animacao()
	_atualizar_display()

func _setup_animacao() -> void:
	if not _anim:
		return
	var biblioteca = AnimationLibrary.new()

	# =========================================================
	# 1) AÇÃO PRINCIPAL: shake (sacudir/sortear valores ao rolar)
	# =========================================================
	var anim_shake = Animation.new()
	anim_shake.length = 0.8
	anim_shake.loop_mode = Animation.LOOP_LINEAR
	var faixa_shake = anim_shake.add_track(Animation.TYPE_VALUE)
	anim_shake.track_set_path(faixa_shake, ".:position")
	anim_shake.track_insert_key(faixa_shake, 0.0, Vector2(0, 0))
	anim_shake.track_insert_key(faixa_shake, 0.1, Vector2(5, -5))
	anim_shake.track_insert_key(faixa_shake, 0.2, Vector2(-5, 5))
	anim_shake.track_insert_key(faixa_shake, 0.3, Vector2(5, 5))
	anim_shake.track_insert_key(faixa_shake, 0.4, Vector2(-5, -5))
	anim_shake.track_insert_key(faixa_shake, 0.5, Vector2(5, -5))
	anim_shake.track_insert_key(faixa_shake, 0.6, Vector2(-5, 5))
	anim_shake.track_insert_key(faixa_shake, 0.7, Vector2(5, -5))
	anim_shake.track_insert_key(faixa_shake, 0.8, Vector2(0, 0))
	biblioteca.add_animation("shake", anim_shake)

	# =========================================================
	# 2) IDLE: repouso suave (flutuação + leve balanço)
	# =========================================================
	var anim_idle = Animation.new()
	anim_idle.length = 2.0
	anim_idle.loop_mode = Animation.LOOP_LINEAR

	var faixa_pos = anim_idle.add_track(Animation.TYPE_VALUE)
	anim_idle.track_set_path(faixa_pos, ".:position")
	anim_idle.track_set_interpolation_type(faixa_pos, Animation.INTERPOLATION_CUBIC)
	anim_idle.track_insert_key(faixa_pos, 0.0, Vector2(0, 0))
	anim_idle.track_insert_key(faixa_pos, 1.0, Vector2(0, -3))
	anim_idle.track_insert_key(faixa_pos, 2.0, Vector2(0, 0))

	var faixa_rot = anim_idle.add_track(Animation.TYPE_VALUE)
	anim_idle.track_set_path(faixa_rot, ".:rotation")
	anim_idle.track_set_interpolation_type(faixa_rot, Animation.INTERPOLATION_CUBIC)
	anim_idle.track_insert_key(faixa_rot, 0.0, 0.0)
	anim_idle.track_insert_key(faixa_rot, 0.5, deg_to_rad(1.5))
	anim_idle.track_insert_key(faixa_rot, 1.5, deg_to_rad(-1.5))
	anim_idle.track_insert_key(faixa_rot, 2.0, 0.0)

	biblioteca.add_animation("idle", anim_idle)

	# =========================================================
	# 3) WALK -> "deslizar": deslocamento do dado pelo tabuleiro
	# =========================================================
	var anim_deslizar = Animation.new()
	anim_deslizar.length = 0.5
	anim_deslizar.loop_mode = Animation.LOOP_LINEAR

	var faixa_desl_pos = anim_deslizar.add_track(Animation.TYPE_VALUE)
	anim_deslizar.track_set_path(faixa_desl_pos, ".:position")
	anim_deslizar.track_set_interpolation_type(faixa_desl_pos, Animation.INTERPOLATION_CUBIC)
	anim_deslizar.track_insert_key(faixa_desl_pos, 0.0, Vector2(0, 0))
	anim_deslizar.track_insert_key(faixa_desl_pos, 0.15, Vector2(0, -6))
	anim_deslizar.track_insert_key(faixa_desl_pos, 0.3, Vector2(0, 0))
	anim_deslizar.track_insert_key(faixa_desl_pos, 0.45, Vector2(0, -6))
	anim_deslizar.track_insert_key(faixa_desl_pos, 0.5, Vector2(0, 0))

	var faixa_desl_rot = anim_deslizar.add_track(Animation.TYPE_VALUE)
	anim_deslizar.track_set_path(faixa_desl_rot, ".:rotation")
	anim_deslizar.track_set_interpolation_type(faixa_desl_rot, Animation.INTERPOLATION_CUBIC)
	anim_deslizar.track_insert_key(faixa_desl_rot, 0.0, deg_to_rad(-3.0))
	anim_deslizar.track_insert_key(faixa_desl_rot, 0.25, deg_to_rad(3.0))
	anim_deslizar.track_insert_key(faixa_desl_rot, 0.5, deg_to_rad(-3.0))

	biblioteca.add_animation("deslizar", anim_deslizar)

	# =========================================================
	# 4) INTERAÇÃO: destaque ao selecionar/passar o mouse
	# =========================================================
	var anim_interacao = Animation.new()
	anim_interacao.length = 0.6
	anim_interacao.loop_mode = Animation.LOOP_LINEAR

	var faixa_int_escala = anim_interacao.add_track(Animation.TYPE_VALUE)
	anim_interacao.track_set_path(faixa_int_escala, ".:scale")
	anim_interacao.track_set_interpolation_type(faixa_int_escala, Animation.INTERPOLATION_CUBIC)
	anim_interacao.track_insert_key(faixa_int_escala, 0.0, Vector2(1.0, 1.0))
	anim_interacao.track_insert_key(faixa_int_escala, 0.3, Vector2(1.12, 1.12))
	anim_interacao.track_insert_key(faixa_int_escala, 0.6, Vector2(1.0, 1.0))

	var faixa_int_mod = anim_interacao.add_track(Animation.TYPE_VALUE)
	anim_interacao.track_set_path(faixa_int_mod, ":modulate")
	anim_interacao.track_set_interpolation_type(faixa_int_mod, Animation.INTERPOLATION_CUBIC)
	anim_interacao.track_insert_key(faixa_int_mod, 0.0, Color(1, 1, 1, 1))
	anim_interacao.track_insert_key(faixa_int_mod, 0.3, Color(1.3, 1.3, 1.0, 1))
	anim_interacao.track_insert_key(faixa_int_mod, 0.6, Color(1, 1, 1, 1))

	biblioteca.add_animation("interacao", anim_interacao)

	# =========================================================
	_anim.add_animation_library("", biblioteca)
	_anim.play("idle")  # já começa em repouso

func _process(delta: float) -> void:
	if _esta_rolando:
		_timer_rolagem -= delta
		_intervalo_flash -= delta
		if _intervalo_flash <= 0:
			_intervalo_flash = 0.07
			_valor_atual = randi_range(1, lados)
			_atualizar_display()
		if _timer_rolagem <= 0:
			_finalizar_rolagem()

func roll() -> void:
	if _esta_rolando:
		return
	_esta_rolando = true
	_timer_rolagem = duracao_rolagem
	_intervalo_flash = 0.07
	if _anim:
		_anim.play("shake")
	if _som_rolagem:
		_som_rolagem.play()

func _finalizar_rolagem() -> void:
	_esta_rolando = false
	_valor_atual = randi_range(1, lados)
	_atualizar_display()
	if _anim:
		_anim.play("idle")  # volta ao repouso suave em vez de só parar
	if _som_rolagem and _som_rolagem.playing:
		_som_rolagem.stop()
	if _som_parada:
		_som_parada.play()
	rolado.emit(_valor_atual)

func get_value() -> int:
	return _valor_atual

func set_sides(s: int) -> void:
	lados = s
	_valor_atual = 1
	_atualizar_display()

func _atualizar_display() -> void:
	if _face:
		_face.queue_redraw()

# =========================================================
# Controles públicos para Walk e Interação
# =========================================================
func deslizar() -> void:
	if _anim and not _esta_rolando:
		_anim.play("deslizar")

func parar_deslizar() -> void:
	if _anim and not _esta_rolando:
		_anim.play("idle")

func interagir() -> void:
	if _anim and not _esta_rolando:
		_anim.play("interacao")
