extends Node2D
class_name FaceDado
const TAMANHO: float = 90.0
const METADE: float = TAMANHO / 2.0
const RAIO_CANTO: float = 20.0       # cantos bem arredondados, estilo cassino
const RAIO_PONTO: float = 7.5
const MARGEM: float = 15.0
const PASSOS_CANTO: int = 12         # mais passos = curva mais suave

const POSICOES_PONTOS = {
	1: [Vector2(0.5,  0.5)],
	2: [Vector2(0.25, 0.25), Vector2(0.75, 0.75)],
	3: [Vector2(0.25, 0.25), Vector2(0.5,  0.5),  Vector2(0.75, 0.75)],
	4: [Vector2(0.25, 0.25), Vector2(0.75, 0.25), Vector2(0.25, 0.75), Vector2(0.75, 0.75)],
	5: [Vector2(0.25, 0.25), Vector2(0.75, 0.25), Vector2(0.5,  0.5),  Vector2(0.25, 0.75), Vector2(0.75, 0.75)],
	6: [Vector2(0.25, 0.25), Vector2(0.75, 0.25), Vector2(0.25, 0.5),  Vector2(0.75, 0.5),  Vector2(0.25, 0.75), Vector2(0.75, 0.75)],
}

const COR_DADO_BASE    := Color(0.82, 0.10, 0.10)     
const COR_DADO_CLARO   := Color(0.95, 0.28, 0.22)     
const COR_DADO_ESCURO  := Color(0.55, 0.05, 0.05)     
const COR_BORDA        := Color(0.35, 0.02, 0.02, 0.90) 
const COR_BRILHO_TOPO  := Color(1.00, 0.85, 0.80, 0.55)  
const COR_SOMBRA_DADO  := Color(0.00, 0.00, 0.00, 0.28)  
const COR_PONTO        := Color(1.00, 1.00, 1.00, 0.96) 
const COR_PONTO_SOMBRA := Color(0.60, 0.05, 0.05, 0.55) 
const COR_PONTO_BRILHO := Color(1.00, 1.00, 1.00, 0.80) 
const COR_ROLANDO      := Color(0.38, 0.40, 0.45)

func _draw() -> void:
	var no_dado := get_parent() as Dado
	if not no_dado:
		return

	var valor: int = clamp(no_dado._valor_atual, 1, 6)
	_desenhar_rect_arredondado(COR_SOMBRA_DADO, Vector2(4.0, 5.0))

	_desenhar_rect_arredondado(COR_DADO_BASE)

	var v: PackedVector2Array = _vertices_rect_arredondado(
		RAIO_CANTO * 0.6, Vector2(-METADE * 0.6, -METADE * 0.7),
		Vector2(METADE * 0.55, METADE * 0.45)
	)
	if v.size() > 2:
		draw_colored_polygon(v, Color(0.95, 0.22, 0.18, 0.30))

	var brilho: PackedVector2Array = PackedVector2Array([
		Vector2(-METADE + 4,              -METADE + 4),
		Vector2(-METADE + TAMANHO * 0.55, -METADE + 4),
		Vector2(-METADE + 4,              -METADE + TAMANHO * 0.55),
	])
	draw_colored_polygon(brilho, COR_BRILHO_TOPO)

	_desenhar_contorno(COR_BORDA, 2.5)

	var area: float   = TAMANHO - MARGEM * 2.0
	var pontos: Array = POSICOES_PONTOS.get(valor, [Vector2(0.5, 0.5)])
	for pp in pontos:
		var px: float = -METADE + MARGEM + pp.x * area
		var py: float = -METADE + MARGEM + pp.y * area
		var centro   := Vector2(px, py)

		draw_circle(centro + Vector2(1.2, 1.5), RAIO_PONTO, COR_PONTO_SOMBRA)
		draw_circle(centro, RAIO_PONTO, COR_PONTO)
		draw_arc(centro, RAIO_PONTO - 1.0, 0.0, TAU, 16, COR_BORDA * Color(1,1,1,0.5), 1.0)
		draw_circle(centro + Vector2(-RAIO_PONTO * 0.32, -RAIO_PONTO * 0.32),
					RAIO_PONTO * 0.28, COR_PONTO_BRILHO)

## Retorna os vértices de um retângulo arredondado genérico (offset opcional).
func _vertices_rect_arredondado(
		raio: float,
		p_min: Vector2 = Vector2(-METADE, -METADE),
		p_max: Vector2 = Vector2( METADE,  METADE),
		offset: Vector2 = Vector2.ZERO
) -> PackedVector2Array:
	var tl := p_min + Vector2( raio,  raio) + offset
	var tr := Vector2(p_max.x - raio, p_min.y + raio) + offset
	var br := p_max - Vector2( raio,  raio) + offset
	var bl := Vector2(p_min.x + raio, p_max.y - raio) + offset
	var centros  := [tl, tr, br, bl]
	var ang_ini  := [PI, PI * 1.5, 0.0,      PI * 0.5]
	var ang_fim  := [PI * 1.5, TAU, PI * 0.5, PI]
	var verts: PackedVector2Array = []
	for i in range(4):
		for s in range(PASSOS_CANTO + 1):
			var a: float = ang_ini[i] + (ang_fim[i] - ang_ini[i]) * float(s) / float(PASSOS_CANTO)
			verts.append(centros[i] + Vector2(cos(a), sin(a)) * raio)
	return verts

func _desenhar_rect_arredondado(cor: Color, offset: Vector2 = Vector2.ZERO) -> void:
	var v := _vertices_rect_arredondado(RAIO_CANTO, Vector2(-METADE, -METADE), Vector2(METADE, METADE), offset)
	if v.size() > 2:
		draw_colored_polygon(v, cor)

func _desenhar_contorno(cor: Color, largura: float) -> void:
	var v := _vertices_rect_arredondado(RAIO_CANTO)
	v.append(v[0])
	draw_polyline(v, cor, largura, true)
