# modo_livre.gd
# MODO LIVRE (simulador): o usuário escolhe uma porta lógica e testa
# todas as combinações das chaves A e B, vendo o LED e a tabela-verdade.
# A protoboard já vem montada do jeito certo para a porta escolhida.
extends Node

# Porta lógica selecionada no momento.
var porta_atual: String = "AND"

@onready var protoboard = $Protoboard
@onready var botoes_portas: GridContainer = $Interface/Tela/PainelPortas/Coluna/BotoesPortas
@onready var label_porta: Label = $Interface/Tela/PainelInfo/Coluna/LabelPorta
@onready var label_ci: Label = $Interface/Tela/PainelInfo/Coluna/LabelCI
@onready var label_expressao: Label = $Interface/Tela/PainelInfo/Coluna/LabelExpressao
@onready var label_estado: Label = $Interface/Tela/PainelInfo/Coluna/LabelEstado
@onready var tabela: GridContainer = $Interface/Tela/PainelInfo/Coluna/Tabela
@onready var label_ligacoes: Label = $Interface/Tela/PainelInfo/Coluna/LabelLigacoes
@onready var botao_voltar: Button = $Interface/Tela/Rodape/BotaoVoltar


func _ready() -> void:
	porta_atual = Global.porta_inicial # a tela Aprender pode escolher a porta
	criar_botoes_portas()
	protoboard.chave_alternada.connect(_on_chave_alternada)
	botao_voltar.pressed.connect(voltar_ao_menu)
	selecionar_porta(porta_atual)


# Cria um botão para cada porta da lista Global.PORTAS.
func criar_botoes_portas() -> void:
	# ButtonGroup: só um botão do grupo pode ficar "pressionado" por vez.
	var grupo := ButtonGroup.new()
	for porta in Global.PORTAS:
		var botao := Button.new()
		botao.text = porta
		botao.toggle_mode = true
		botao.button_group = grupo
		botao.custom_minimum_size = Vector2(90, 44)
		botao.button_pressed = (porta == porta_atual)
		# bind(porta) faz o botão enviar o nome da porta para a função.
		botao.pressed.connect(selecionar_porta.bind(porta))
		botoes_portas.add_child(botao)


func selecionar_porta(porta: String) -> void:
	porta_atual = porta
	label_porta.text = "Porta " + porta
	label_ci.text = "CI " + Global.CIS[porta] + " (linha 74HC)"
	label_expressao.text = Global.EXPRESSOES[porta]
	# Monta a protoboard certa para esta porta (a NOT usa só a chave A).
	protoboard.carregar(Circuito.montagem_correta(porta))
	label_ligacoes.text = texto_ligacoes(Global.CIS[porta])
	atualizar_saida()


# Chamada pelo sinal da protoboard sempre que uma chave muda.
func _on_chave_alternada(_nome: String, _ligada: bool) -> void:
	atualizar_saida()


# Lê o LED da protoboard e atualiza o texto e a tabela.
func atualizar_saida() -> void:
	var a: bool = protoboard.valor_chave("A")
	var b: bool = protoboard.valor_chave("B")
	# A saída vem da SIMULAÇÃO da protoboard (fios + pinagem do CI).
	var s: bool = protoboard.resultado["leds"][0] == "aceso"

	if porta_atual == "NOT":
		label_estado.text = "A=%s  →  S=%s" % [Global.bit(a), Global.bit(s)]
	else:
		label_estado.text = "A=%s  B=%s  →  S=%s" % [Global.bit(a), Global.bit(b), Global.bit(s)]
	montar_tabela()


# Monta a tabela-verdade da porta atual, destacando a linha das chaves.
func montar_tabela() -> void:
	# Remove as células antigas.
	for celula in tabela.get_children():
		celula.queue_free()

	# Cabeçalho.
	adicionar_celula("A", false, true)
	adicionar_celula("B", false, true)
	adicionar_celula("S", false, true)

	# Percorre todas as combinações de entradas: 00, 01, 10, 11.
	for valor_a in [false, true]:
		for valor_b in [false, true]:
			if porta_atual == "NOT" and valor_b:
				continue # a NOT só precisa de 2 linhas (A = 0 e A = 1)
			var s: bool = Global.calcular_porta(porta_atual, valor_a, valor_b)
			var linha_atual: bool = (valor_a == protoboard.valor_chave("A") and valor_b == protoboard.valor_chave("B"))
			adicionar_celula(Global.bit(valor_a), linha_atual, false)
			if porta_atual == "NOT":
				adicionar_celula("-", linha_atual, false)
			else:
				adicionar_celula(Global.bit(valor_b), linha_atual, false)
			adicionar_celula(Global.bit(s), linha_atual, false)


# Texto com as ligações da porta 1 do CI (pinos tirados da tabela de pinagem).
func texto_ligacoes(modelo: String) -> String:
	var porta1: Array = Global.PORTAS_DO_CI[modelo][0]
	var t: String = "• Pino 14 (VCC) → trilha + (5 V)\n"
	t += "• Pino 7 (GND) → trilha −\n"
	t += "• Chave A → pino %d\n" % porta1[0]
	if porta1.size() == 3:
		t += "• Chave B → pino %d\n" % porta1[1]
	t += "• Pino %d (saída) → resistor 330 Ω → LED → GND" % porta1[porta1.size() - 1]
	return t


# Cria uma "célula" (Label com fundo colorido) dentro da tabela.
func adicionar_celula(texto: String, destacada: bool, cabecalho: bool) -> void:
	var celula := Label.new()
	celula.text = texto
	celula.custom_minimum_size = Vector2(80, 34)
	celula.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	celula.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var fundo := StyleBoxFlat.new()
	if cabecalho:
		fundo.bg_color = Color(0.2, 0.3, 0.45)
	elif destacada:
		fundo.bg_color = Color(0.95, 0.65, 0.1)
		celula.add_theme_color_override("font_color", Color.BLACK)
	else:
		fundo.bg_color = Color(0.15, 0.17, 0.22)
	celula.add_theme_stylebox_override("normal", fundo)
	tabela.add_child(celula)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"): # tecla Esc
		voltar_ao_menu()


func voltar_ao_menu() -> void:
	get_tree().change_scene_to_file("res://cenas/menu.tscn")
