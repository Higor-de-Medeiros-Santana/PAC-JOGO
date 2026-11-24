
extends Node

# FASE 1
var estrelas_fase_1: int = 0
var fase_1_concluida: bool = false
var animar_estrelas_fase_1: bool = false

# FASE 2
var estrelas_fase_2: int = 0
var fase_2_concluida: bool = false
var animar_estrelas_fase_2: bool = false

# FASE 3
var estrelas_fase_3: int = 0
var fase_3_concluida: bool = false
var animar_estrelas_fase_3: bool = false


# =========================
# FASE 1
# =========================

func salvar_estrelas_fase_1(quantidade: int) -> void:
	estrelas_fase_1 = maxi(
		estrelas_fase_1,
		clampi(quantidade, 0, 3)
	)

	fase_1_concluida = true
	animar_estrelas_fase_1 = true


func obter_estrelas_fase_1() -> int:
	return estrelas_fase_1


func verificar_fase_1_concluida() -> bool:
	return fase_1_concluida


func consumir_animacao_fase_1() -> bool:
	var resultado: bool = animar_estrelas_fase_1
	animar_estrelas_fase_1 = false
	return resultado


# =========================
# FASE 2
# =========================

func salvar_estrelas_fase_2(quantidade: int) -> void:
	estrelas_fase_2 = maxi(
		estrelas_fase_2,
		clampi(quantidade, 0, 3)
	)

	fase_2_concluida = true
	animar_estrelas_fase_2 = true


func obter_estrelas_fase_2() -> int:
	return estrelas_fase_2


func verificar_fase_2_concluida() -> bool:
	return fase_2_concluida


func consumir_animacao_fase_2() -> bool:
	var resultado: bool = animar_estrelas_fase_2
	animar_estrelas_fase_2 = false
	return resultado


# =========================
# FASE 3
# =========================

func salvar_estrelas_fase_3(quantidade: int) -> void:
	estrelas_fase_3 = maxi(
		estrelas_fase_3,
		clampi(quantidade, 0, 3)
	)

	fase_3_concluida = true
	animar_estrelas_fase_3 = true


func obter_estrelas_fase_3() -> int:
	return estrelas_fase_3


func verificar_fase_3_concluida() -> bool:
	return fase_3_concluida


func consumir_animacao_fase_3() -> bool:
	var resultado: bool = animar_estrelas_fase_3
	animar_estrelas_fase_3 = false
	return resultado
# =========================
# FASE 4
# =========================

# FASE 4
var estrelas_fase_4: int = 0
var fase_4_concluida: bool = false
var animar_estrelas_fase_4: bool = false


func salvar_estrelas_fase_4(quantidade: int) -> void:

	estrelas_fase_4 = maxi(
		estrelas_fase_4,
		clampi(quantidade, 0, 3)
	)

	fase_4_concluida = true
	animar_estrelas_fase_4 = true


func obter_estrelas_fase_4() -> int:
	return estrelas_fase_4


func verificar_fase_4_concluida() -> bool:
	return fase_4_concluida


func consumir_animacao_fase_4() -> bool:

	var resultado := animar_estrelas_fase_4

	animar_estrelas_fase_4 = false

	return resultado
