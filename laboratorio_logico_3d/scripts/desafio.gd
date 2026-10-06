# desafio.gd
# MODO DESAFIO (jogo): o CI mostra "?" e esconde uma porta lógica sorteada.
# O jogador testa as chaves, observa o LED e tenta descobrir qual é a porta.
# São várias rodadas; no final o jogo vai para a tela de resultado.
extends Node

# Portas que podem ser sorteadas (a NOT fica de fora porque tem só uma entrada).
const PORTAS_DESAFIO: Array[String] = ["AND", "OR", "NAND", "NOR", "XOR", "XNOR"]
const PONTOS_ACERTO: int = 100
const PONTOS_BONUS: int = 50 # bônus para quem acerta rápido
const TEMPO_BONUS: float = 20.0 # segundos

var rodada: int = 1
var porta_secreta: String = ""
var tempo_rodada: float = 0.0
var rodada_ativa: bool = false
# Dicionário com os testes feitos. Chave = "AB" (ex.: "01"), valor = saída S.
var testes: Dictionary = {}
var botoes_resposta: Array[Button] = []

@onready var bancada = $Bancada
@onready var label_rodada: Label = $Interface/Tela/PainelPlacar/Coluna/LabelRodada
@onready var label_pontos: Label = $Interface/Tela/PainelPlacar/Coluna/LabelPontos
@onready var label_tempo: Label = $Interface/Tela/PainelPlacar/Coluna/LabelTempo
@onready var tabela_testes: GridContainer = $Interface/Tela/PainelTestes/Coluna/TabelaTestes
@onready var label_testes: Label = $Interface/Tela/PainelTestes/Coluna/LabelTestes
@onready var caixa_botoes: HBoxContainer = $Interface/Tela/PainelResposta/Coluna/BotoesResposta
@onready var painel_feedback: PanelContainer = $Interface/Tela/PainelFeedback
@onready var label_feedback: Label = $Interface/Tela/PainelFeedback/Coluna/LabelFeedback
@onready var botao_proxima: Button = $Interface/Tela/PainelFeedback/Coluna/BotaoProxima
@onready var botao_voltar: Button = $Interface/Tela/BotaoVoltar


func _ready() -> void:
	Global.reiniciar_desafio()
	criar_botoes_resposta()
	bancada.entradas_mudaram.connect(_on_entradas_mudaram)
	botao_proxima.pressed.connect(_on_botao_proxima_pressed)
	botao_voltar.pressed.connect(voltar_ao_menu)
	iniciar_rodada()


# _process roda a cada quadro (frame). delta = tempo desde o último quadro.
func _process(delta: float) -> void:
	if rodada_ativa:
		tempo_rodada += delta
		Global.tempo_total += delta
		label_tempo.text = "Tempo: %.1f s" % Global.tempo_total


func criar_botoes_resposta() -> void:
	for porta in PORTAS_DESAFIO:
		var botao := Button.new()
		botao.text = porta
		botao.custom_minimum_size = Vector2(96, 44)
		botao.pressed.connect(_on_resposta.bind(porta))
		caixa_botoes.add_child(botao)
		botoes_resposta.append(botao)


func iniciar_rodada() -> void:
	# pick_random() sorteia um elemento da lista.
	porta_secreta = PORTAS_DESAFIO.pick_random()
	tempo_rodada = 0.0
	testes.clear()
	rodada_ativa = true
	painel_feedback.visible = false
	habilitar_respostas(true)

	bancada.mostrar_porta("?", "74??")
	bancada.reiniciar_chaves()
	label_rodada.text = "Rodada %d de %d" % [rodada, Global.total_rodadas]
	label_pontos.text = "Pontos: %d" % Global.pontos
	registrar_teste() # registra a combinação inicial A=0, B=0


func _on_entradas_mudaram(_a: bool, _b: bool) -> void:
	registrar_teste()


# Calcula a saída da porta secreta, acende o LED e anota o teste.
func registrar_teste() -> void:
	var a: bool = bancada.a
	var b: bool = bancada.b
	var s: bool = Global.calcular_porta(porta_secreta, a, b)
	bancada.mostrar_saida(s)
	testes[Global.bit(a) + Global.bit(b)] = s
	atualizar_tabela_testes()


# Mostra na tela as combinações já testadas (na ordem 00, 01, 10, 11).
func atualizar_tabela_testes() -> void:
	for celula in tabela_testes.get_children():
		celula.queue_free()
	for titulo in ["A", "B", "S"]:
		adicionar_celula(titulo, Color(0.2, 0.3, 0.45))

	for combinacao in ["00", "01", "10", "11"]:
		if testes.has(combinacao):
			adicionar_celula(combinacao[0], Color(0.15, 0.17, 0.22))
			adicionar_celula(combinacao[1], Color(0.15, 0.17, 0.22))
			adicionar_celula(Global.bit(testes[combinacao]), Color(0.15, 0.17, 0.22))
		else:
			# Combinação ainda não testada: mostra "?".
			adicionar_celula(combinacao[0], Color(0.1, 0.1, 0.12))
			adicionar_celula(combinacao[1], Color(0.1, 0.1, 0.12))
			adicionar_celula("?", Color(0.1, 0.1, 0.12))

	label_testes.text = "Combinações testadas: %d de 4" % testes.size()


func adicionar_celula(texto: String, cor: Color) -> void:
	var celula := Label.new()
	celula.text = texto
	celula.custom_minimum_size = Vector2(76, 32)
	celula.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	celula.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var fundo := StyleBoxFlat.new()
	fundo.bg_color = cor
	celula.add_theme_stylebox_override("normal", fundo)
	tabela_testes.add_child(celula)


# Chamada quando o jogador clica em um dos botões de resposta.
func _on_resposta(porta_escolhida: String) -> void:
	if not rodada_ativa:
		return
	rodada_ativa = false
	habilitar_respostas(false)

	# Revela a porta que estava escondida no CI.
	bancada.mostrar_porta(porta_secreta, Global.CIS[porta_secreta])

	if porta_escolhida == porta_secreta:
		var ganhos: int = PONTOS_ACERTO
		var texto: String = "Correto! Era a porta %s.\n+%d pontos" % [porta_secreta, PONTOS_ACERTO]
		if tempo_rodada <= TEMPO_BONUS:
			ganhos += PONTOS_BONUS
			texto += " (+%d bônus de rapidez!)" % PONTOS_BONUS
		Global.pontos += ganhos
		Global.acertos += 1
		label_feedback.text = texto
		label_feedback.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
	else:
		label_feedback.text = "Errado! Você marcou %s, mas era %s.\n%s" % [
			porta_escolhida, porta_secreta, Global.EXPRESSOES[porta_secreta]]
		label_feedback.add_theme_color_override("font_color", Color(1.0, 0.45, 0.4))

	label_pontos.text = "Pontos: %d" % Global.pontos
	if rodada >= Global.total_rodadas:
		botao_proxima.text = "Ver resultado"
	else:
		botao_proxima.text = "Próxima rodada"
	painel_feedback.visible = true


func _on_botao_proxima_pressed() -> void:
	if rodada >= Global.total_rodadas:
		get_tree().change_scene_to_file("res://cenas/resultado.tscn")
	else:
		rodada += 1
		iniciar_rodada()


func habilitar_respostas(habilitar: bool) -> void:
	for botao in botoes_resposta:
		botao.disabled = not habilitar


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		voltar_ao_menu()


func voltar_ao_menu() -> void:
	get_tree().change_scene_to_file("res://cenas/menu.tscn")
