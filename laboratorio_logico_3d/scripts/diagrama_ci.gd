# diagrama_ci.gd
# Desenha a pinagem de um CI visto de cima, com as funções de desenho 2D do
# Godot (_draw). Tudo vem da tabela de pinagem do Global, então o mesmo código
# desenha os 7 CIs.
extends Control

const ESPACO: float = 52.0 # distância entre dois pinos
const TOPO: float = 70.0 # onde começa o corpo do CI
const ESQ: float = 150.0 # lado esquerdo do corpo
const LARGURA: float = 220.0
const COR_CORPO := Color(0.12, 0.12, 0.14)
const COR_TEXTO := Color(0.9, 0.92, 0.95)
const COR_APAGADA := Color(0.55, 0.58, 0.62)
const COR_VCC := Color(1.0, 0.4, 0.35)
const COR_GND := Color(0.5, 0.7, 1.0)
const COR_DESTAQUE := Color(0.95, 0.65, 0.1)

# Ao mudar o modelo, o "set" pede para desenhar de novo.
var modelo: String = "74HC08":
	set(valor):
		modelo = valor
		queue_redraw()


func _draw() -> void:
	var fonte: Font = get_theme_default_font()
	var portas: Array = Global.PORTAS_DO_CI[modelo]
	var funcao: String = Global.FUNCAO_DO_CI[modelo]
	var direita: float = ESQ + LARGURA
	var altura: float = 7 * ESPACO

	draw_string(fonte, Vector2(0, 32), "%s  –  %d portas %s" % [modelo, portas.size(), funcao],
			HORIZONTAL_ALIGNMENT_CENTER, size.x, 26, COR_DESTAQUE)

	# Corpo do CI e a marca do pino 1 (meio círculo em cima)
	draw_rect(Rect2(ESQ, TOPO, LARGURA, altura), COR_CORPO)
	draw_arc(Vector2(ESQ + LARGURA / 2.0, TOPO), 14.0, 0.0, PI, 16, COR_APAGADA, 3.0)

	# Os 14 pinos: 1 a 7 à esquerda (de cima para baixo), 14 a 8 à direita.
	for pino in range(1, 15):
		var y: float = y_do_pino(pino)
		var cor: Color = cor_do_pino(pino)
		var nome: String = Global.nome_do_pino(modelo, pino)
		if pino <= 7:
			draw_line(Vector2(ESQ - 24, y), Vector2(ESQ, y), cor, 6.0)
			draw_string(fonte, Vector2(ESQ - 64, y + 7), str(pino), HORIZONTAL_ALIGNMENT_RIGHT, 34, 20, cor)
			draw_string(fonte, Vector2(ESQ - 150, y + 7), nome, HORIZONTAL_ALIGNMENT_RIGHT, 80, 20, cor)
		else:
			draw_line(Vector2(direita, y), Vector2(direita + 24, y), cor, 6.0)
			draw_string(fonte, Vector2(direita + 30, y + 7), str(pino), HORIZONTAL_ALIGNMENT_LEFT, 34, 20, cor)
			draw_string(fonte, Vector2(direita + 70, y + 7), nome, HORIZONTAL_ALIGNMENT_LEFT, 80, 20, cor)

	# As portas por dentro: uma caixa por porta, ligada aos seus pinos.
	for i in range(portas.size()):
		desenhar_porta(fonte, portas[i], funcao, i == 0)

	var base: float = TOPO + altura
	draw_string(fonte, Vector2(0, base + 34), "Visto de cima • marca = lado do pino 1 • contagem anti-horária",
			HORIZONTAL_ALIGNMENT_CENTER, size.x, 16, COR_APAGADA)
	draw_string(fonte, Vector2(0, base + 58), "Laranja: porta 1, a que o jogo usa",
			HORIZONTAL_ALIGNMENT_CENTER, size.x, 16, COR_DESTAQUE)


func desenhar_porta(fonte: Font, porta: Array, funcao: String, destacar: bool) -> void:
	var cor: Color = COR_DESTAQUE if destacar else COR_APAGADA
	var na_esquerda: bool = porta[0] <= 7
	# Acha o pino mais alto e o mais baixo desta porta (laço + min/max).
	var y_min: float = INF
	var y_max: float = -INF
	for pino in porta:
		y_min = minf(y_min, y_do_pino(pino))
		y_max = maxf(y_max, y_do_pino(pino))
	var caixa: Rect2
	if na_esquerda:
		caixa = Rect2(ESQ + 36, y_min - 16, 76, y_max - y_min + 32)
	else:
		caixa = Rect2(ESQ + LARGURA - 112, y_min - 16, 76, y_max - y_min + 32)
	draw_rect(caixa, cor, false, 2.0)
	draw_string(fonte, Vector2(caixa.position.x, caixa.get_center().y + 6), funcao,
			HORIZONTAL_ALIGNMENT_CENTER, caixa.size.x, 16, cor)
	for k in range(porta.size()):
		var y: float = y_do_pino(porta[k])
		var eh_saida: bool = k == porta.size() - 1
		var largura_linha: float = 3.0 if eh_saida else 1.5
		if na_esquerda:
			draw_line(Vector2(ESQ, y), Vector2(caixa.position.x, y), cor, largura_linha)
		else:
			draw_line(Vector2(caixa.end.x, y), Vector2(ESQ + LARGURA, y), cor, largura_linha)


# Altura (y) de um pino na tela.
func y_do_pino(pino: int) -> float:
	var linha: int = pino - 1 if pino <= 7 else 14 - pino
	return TOPO + ESPACO * (linha + 0.5)


func cor_do_pino(pino: int) -> Color:
	if pino == Global.PINO_VCC:
		return COR_VCC
	if pino == Global.PINO_GND:
		return COR_GND
	if Global.PORTAS_DO_CI[modelo][0].has(pino):
		return COR_DESTAQUE
	return COR_TEXTO
