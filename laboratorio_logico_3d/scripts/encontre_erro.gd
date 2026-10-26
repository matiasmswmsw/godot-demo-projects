# encontre_erro.gd
# DESAFIO "ENCONTRE O ERRO": a protoboard aparece montada, às vezes com UM erro
# de ligação e às vezes certa. O jogador testa as chaves, olha os fios e escolhe
# na lista o que está errado (ou "Não há erro").
extends Node

const TOTAL_RODADAS: int = 6
const PONTOS_ACERTO: int = 100
const CHANCE_SEM_ERRO: float = 0.25 # 25% das montagens estão certas
const SEM_FURO := Vector2i(-1, -1)

# Botões de resposta, na ordem em que aparecem.
const BOTOES: Array[String] = [
	"Falta VCC ou GND", "VCC e GND invertidos", "CI virado", "Entrada solta",
	"Fio no pino errado", "LED invertido", "LED sem resistor", "CI fora do canal", "Não há erro",
]

# Para cada defeito: a resposta certa (texto do botão).
const RESPOSTAS: Dictionary = {
	"falta_vcc": "Falta VCC ou GND",
	"falta_gnd": "Falta VCC ou GND",
	"invertido": "VCC e GND invertidos",
	"girado": "CI virado",
	"entrada_solta": "Entrada solta",
	"pino_errado": "Fio no pino errado",
	"led_invertido": "LED invertido",
	"sem_resistor": "LED sem resistor",
	"fora_canal": "CI fora do canal",
	"nenhum": "Não há erro",
}

# Explicação mostrada depois da resposta.
const EXPLICACOES: Dictionary = {
	"falta_vcc": "Faltava o fio vermelho do pino 14 (VCC) até a trilha +. Sem alimentação o CI não funciona e o LED fica sempre apagado.",
	"falta_gnd": "Faltava o fio preto do pino 7 (GND) até a trilha −. Sem o GND o CI não tem alimentação.",
	"invertido": "O fio do pino 14 foi para o − e o do pino 7 para o +. Com a alimentação invertida o CI esquenta e queima.",
	"girado": "O CI estava virado: a marca do pino 1 ficou do lado errado. Assim o + chega no pino 7 e o − no pino 14, e o CI queima.",
	"entrada_solta": "A chave A não estava ligada ao CI. No 74HC uma entrada solta fica indefinida: o LED pisca ou não obedece à chave.",
	"pino_errado": "A saída estava ligada no pino errado. Confira a pinagem: cada porta tem pinos certos de entrada e de saída.",
	"led_invertido": "O LED estava invertido. A perna + (anodo, a mais comprida) vai do lado do resistor e a − vai no GND.",
	"sem_resistor": "Não havia resistor. Sem os 330 Ω a corrente fica alta demais e o LED queima.",
	"fora_canal": "O CI não atravessava o canal central. Os pinos dos dois lados ficaram na mesma coluna, em curto.",
	"nenhum": "A montagem estava certa! Prestar atenção também é saber quando não há erro.",
}

var rodada: int = 1
var defeito: String = ""
var defeito_anterior: String = ""
var furo_do_erro: Vector2i = SEM_FURO
var rodada_ativa: bool = false
var botoes: Array[Button] = []

@onready var protoboard = $Protoboard
@onready var label_rodada: Label = $Interface/Tela/PainelPlacar/Coluna/LabelRodada
@onready var label_pontos: Label = $Interface/Tela/PainelPlacar/Coluna/LabelPontos
@onready var label_porta: Label = $Interface/Tela/PainelPlacar/Coluna/LabelPorta
@onready var caixa_botoes: VBoxContainer = $Interface/Tela/PainelRespostas/Coluna/Botoes
@onready var painel_feedback: PanelContainer = $Interface/Tela/PainelFeedback
@onready var label_feedback: Label = $Interface/Tela/PainelFeedback/Coluna/LabelFeedback
@onready var botao_proxima: Button = $Interface/Tela/PainelFeedback/Coluna/BotaoProxima
@onready var botao_voltar: Button = $Interface/Tela/BotaoVoltar


func _ready() -> void:
	Global.reiniciar_partida("erro", TOTAL_RODADAS)
	criar_botoes()
	botao_proxima.pressed.connect(_on_botao_proxima_pressed)
	botao_voltar.pressed.connect(voltar_ao_menu)
	iniciar_rodada()


func _process(delta: float) -> void:
	if rodada_ativa:
		Global.tempo_total += delta


func criar_botoes() -> void:
	for texto in BOTOES:
		var botao := Button.new()
		botao.text = texto
		botao.custom_minimum_size = Vector2(280, 40)
		botao.pressed.connect(_on_resposta.bind(texto))
		caixa_botoes.add_child(botao)
		botoes.append(botao)


func iniciar_rodada() -> void:
	var porta: String = Global.PORTAS.pick_random()
	defeito = sortear_defeito()
	defeito_anterior = defeito
	var circuito := Circuito.montagem_correta(porta)
	furo_do_erro = aplicar_defeito(circuito, defeito)
	protoboard.carregar(circuito)

	rodada_ativa = true
	painel_feedback.visible = false
	habilitar_respostas(true)
	label_rodada.text = "Montagem %d de %d" % [rodada, TOTAL_RODADAS]
	label_pontos.text = "Pontos: %d" % Global.pontos
	label_porta.text = "Porta %s (%s)\nO LED deveria seguir: %s" % [porta, Global.CIS[porta], Global.EXPRESSOES[porta]]


# Sorteia o defeito da rodada. Nunca repete o mesmo duas vezes seguidas.
func sortear_defeito() -> String:
	if randf() < CHANCE_SEM_ERRO and defeito_anterior != "nenhum":
		return "nenhum"
	var lista: Array = RESPOSTAS.keys()
	lista.erase("nenhum")
	lista.erase(defeito_anterior)
	return lista.pick_random()


# Estraga a montagem certa de acordo com o defeito sorteado.
# Retorna o furo onde está o erro (para marcar depois da resposta).
func aplicar_defeito(c: Circuito, qual: String) -> Vector2i:
	var ci: Dictionary = c.cis[0]
	var porta1: Array = Global.PORTAS_DO_CI[ci["modelo"]][0]
	match qual:
		"falta_vcc":
			c.remover_fio("vcc_ci")
			return c.furo_do_pino(ci, Global.PINO_VCC)
		"falta_gnd":
			c.remover_fio("gnd_ci")
			return c.furo_do_pino(ci, Global.PINO_GND)
		"invertido":
			var fio_vcc: Dictionary = c.fio_por_id("vcc_ci")
			var fio_gnd: Dictionary = c.fio_por_id("gnd_ci")
			fio_vcc["para"] = Vector2i(10, 1) # fio do pino 14 no −
			fio_gnd["para"] = Vector2i(16, 12) # fio do pino 7 no +
			return c.furo_do_pino(ci, Global.PINO_VCC)
		"girado":
			ci["girado"] = true
			return c.furo_do_pino(ci, 1)
		"entrada_solta":
			c.remover_fio("entrada_a")
			return c.furo_do_pino(ci, porta1[0])
		"pino_errado":
			var pino_errado: int = porta1[porta1.size() - 1] + 1 # o pino ao lado da saída
			var fio_saida: Dictionary = c.fio_por_id("saida")
			fio_saida["de"] = c.furo_do_pino(ci, pino_errado) + Vector2i(0, 4)
			return c.furo_do_pino(ci, pino_errado)
		"led_invertido":
			var led: Dictionary = c.leds[0]
			var anodo: Vector2i = led["anodo"]
			led["anodo"] = led["catodo"]
			led["catodo"] = anodo
			return anodo
		"sem_resistor":
			c.resistores.clear()
			var fio_direto: Dictionary = c.fio_por_id("saida")
			fio_direto["para"] = c.leds[0]["anodo"] + Vector2i(0, 4) # saída direto no LED
			return c.leds[0]["anodo"]
		"fora_canal":
			ci["fora_canal"] = true
			return c.furo_do_pino(ci, 1)
	return SEM_FURO # "nenhum": não estraga nada


func _on_resposta(escolha: String) -> void:
	if not rodada_ativa:
		return
	rodada_ativa = false
	habilitar_respostas(false)
	if furo_do_erro != SEM_FURO:
		protoboard.marcar_furo(furo_do_erro) # mostra onde estava o erro

	var certa: String = RESPOSTAS[defeito]
	var texto: String
	if escolha == certa:
		Global.pontos += PONTOS_ACERTO
		Global.acertos += 1
		texto = "Correto! +%d pontos\n" % PONTOS_ACERTO
		label_feedback.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
	else:
		texto = "Errado! Você marcou \"%s\", mas era \"%s\".\n" % [escolha, certa]
		label_feedback.add_theme_color_override("font_color", Color(1.0, 0.55, 0.45))
	label_feedback.text = texto + EXPLICACOES[defeito]
	label_pontos.text = "Pontos: %d" % Global.pontos
	botao_proxima.text = "Ver resultado" if rodada >= TOTAL_RODADAS else "Próxima montagem"
	painel_feedback.visible = true


func _on_botao_proxima_pressed() -> void:
	if rodada >= TOTAL_RODADAS:
		get_tree().change_scene_to_file("res://cenas/resultado.tscn")
	else:
		rodada += 1
		iniciar_rodada()


func habilitar_respostas(habilitar: bool) -> void:
	for botao in botoes:
		botao.disabled = not habilitar


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		voltar_ao_menu()


func voltar_ao_menu() -> void:
	get_tree().change_scene_to_file("res://cenas/menu.tscn")
